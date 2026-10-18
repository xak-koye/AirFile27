import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
}

struct FilesView: View {
    @State private var currentPath: String
    @State private var items: [FileItem] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading...")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
            
            if path == "/var/mobile" {
                self.items = [
                    FileItem(name: "Library", isDirectory: true),
                    FileItem(name: "Media", isDirectory: true),
                    FileItem(name: "Documents", isDirectory: true),
                    FileItem(name: "test.txt", isDirectory: false)
                ]
            } else if path.hasSuffix("Library") {
                self.items = [
                    FileItem(name: "Books", isDirectory: true),
                    FileItem(name: "CallServices", isDirectory: true),
                    FileItem(name: "Safari", isDirectory: true),
                    FileItem(name: "Preferences.plist", isDirectory: false)
                ]
            } else {
                self.items = [
                    FileItem(name: "file_inside.txt", isDirectory: false)
                ]
            }
        }
    }
}
