import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
}

struct FilesView: View {
    @State private var currentPath: String = "/var/mobile"
    @State private var items: [FileItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading...")
                } else if items.isEmpty {
                    Text("No files found or empty folder.")
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
            .navigationTitle("Files")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { loadDirectory(currentPath) }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // بۆ تاقیکردنەوە، ئێمە لیستێکی دەستکرد بەکاردەهێنین
                // چونکە فەنکشنی ڕاستەقینەی لیستکردن لە Rust هێشتا نییە
                if items.isEmpty {
                    loadMockData()
                }
            }
        }
    }
    
    // سازکردنی Initializer بۆ ئەوەی بتوانین بچینە ناو فۆڵدەرەکان
    init(initialPath: String = "/var/mobile") {
        self._currentPath = State(initialValue: initialPath)
    }

    private func loadMockData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            // لیستی نموونەیی بۆ تاقیکردنەوەی ڕووکارەکە
            self.items = [
                FileItem(name: "Library", isDirectory: true),
                FileItem(name: "Media", isDirectory: true),
                FileItem(name: "Documents", isDirectory: true),
                FileItem(name: "test.txt", isDirectory: false),
                FileItem(name: "config.plist", isDirectory: false)
            ]
        }
    }
    
    // ئەمە دواتر بە فەنکشنی ڕاستەقینەی Rust دەگۆڕدرێت
    private func loadDirectory(_ path: String) {
        loadMockData()
    }
}
