import SwiftUI

struct FilesView: View {
    // لیستێکی نموونەیی بۆ فایلەکان
    let fileList = [
        "/var/mobile/Library/Books/Sync/Books.plist",
        "/var/mobile/Library/CallServices/Greetings/default/tone.m4a"
    ]

    var body: some View {
        NavigationView {
            List(fileList, id: \.self) { filePath in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text(filePath)
                        .font(.system(.footnote, design: .monospaced))
                        .lineLimit(2)
                }
            }
            .navigationTitle("Device Files")
        }
    }
}

// ئەم بەشە تەنها بۆ تاقیکردنەوەیە لە Xcode
struct FilesView_Previews: PreviewProvider {
    static var previews: some View {
        FilesView()
    }
}
