import SwiftUI
import AirliftFFI

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
}

struct FilesView: View {
    @State private var currentPath: String
    @State private var items: [FileItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.footnote)
            } else if items.isEmpty {
                Text("Empty folder or no files found.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { item in
                    if item.isDirectory {
                        NavigationLink(destination: FilesView(initialPath: currentPath + "/" + item.name)) {
                            Label(item.name, systemImage: "folder.fill")
                                .foregroundColor(.blue)
                        }
                    } else {
                        HStack {
                            Label(item.name, systemImage: "doc.text.fill")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(currentPath.components(separatedBy: "/").last ?? "Files")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { loadDirectory(currentPath) }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            if items.isEmpty {
                loadDirectory(currentPath)
            }
        }
    }
    
    init(initialPath: String = "/var/mobile") {
        self._currentPath = State(initialValue: initialPath)
    }

    private func loadDirectory(_ path: String) {
        isLoading = true
        errorMessage = nil
        
        let pairingPath = PairingController.pairingFilePath()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var outJson: UnsafeMutablePointer<CChar>?
            var outError: UnsafeMutablePointer<CChar>?
            
            // بانگکردنی فەنکشنی Rust (دڵنیابەرەوە کە لە airlift.h زیادکراوە)
            let rc = pairingPath.withCString { pairC in
                path.withCString { pathC in
                    al_exploit_list_dir(pairC, pathC, nil, nil, &outJson, &outError)
                }
            }
            
            DispatchQueue.main.async {
                isLoading = false
                if rc == 0, let jsonCStr = outJson {
                    let jsonString = String(cString: jsonCStr)
                    al_string_free(jsonCStr)
                    
                    if let data = jsonString.data(using: .utf8),
                       let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        self.items = jsonArray.compactMap { dict in
                            if let name = dict["name"] as? String, let isDir = dict["is_dir"] as? Bool {
                                return FileItem(name: name, isDirectory: isDir)
                            }
                            return nil
                        }.sorted { $0.isDirectory && !$1.isDirectory }
                    }
                } else {
                    if let errCStr = outError {
                        errorMessage = String(cString: errCStr)
                        al_string_free(errCStr)
                    } else {
                        errorMessage = "Failed to list directory (rc=\(rc))"
                    }
                }
            }
        }
    }
}
