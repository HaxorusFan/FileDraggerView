//
//  FileDraggerView.swift
//  VirtualBot
//  Created by ZXL on 2024/12/11.

import Foundation
import SwiftUI
import Cocoa

class NSFileDraggerView: NSView {
    private var allowedExtensions: [String] = []
    private var goodURLS: [URL] = []
    private var acceptsDirectory: Bool = false
    var onFileDragged: (([URL]) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if isFileTypeAllowed(sender){
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.5).cgColor
            return .copy
        } else {
            return []
        }
    }
    
    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func draggingEnded(_ sender: any NSDraggingInfo) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        if let _ = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL] {
            onFileDragged?(goodURLS)
            return true
        }
        return false
    }
    
    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if isFileTypeAllowed(sender) {
            return .copy
        } else {
            return []
        }
    }
    
    private func isFileTypeAllowed(_ sender: NSDraggingInfo) -> Bool {
        if let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            goodURLS.removeAll()
            for item in items {
                if item.hasDirectoryPath && acceptsDirectory{
                    goodURLS.append(item)
                }else{
                    let fileExtension = item.pathExtension.lowercased()
                    if allowedExtensions.contains(fileExtension) {
                        goodURLS.append(item)
                    }
                }
            }
            if goodURLS.count > 0 {
                return true
            }
        }
        return false
    }
    
    func setAllowedExtensions(extensions: [String]){
        self.allowedExtensions = extensions
    }
    
    func setAcceptsDirectory(flag: Bool){
        self.acceptsDirectory = flag
    }
}

struct FileDraggerView: NSViewRepresentable {
    typealias NSViewType = NSFileDraggerView
    var fileUSage:(([URL]) -> Void)
    let allowedExtensions: [String]
    let acceptsDirectory: Bool
    
    init(fileUSage: @escaping ([URL]) -> Void, allowedExtensions: [String], acceptsDirectory: Bool = false) {
        self.fileUSage = fileUSage
        self.allowedExtensions = allowedExtensions
        self.acceptsDirectory = acceptsDirectory
    }
    
    func makeNSView(context: Context) -> NSFileDraggerView {
        let view = NSFileDraggerView()
        view.onFileDragged = context.coordinator.handleFileDragged
        return view
    }
    
    func updateNSView(_ nsView: NSFileDraggerView, context: Context) {
        nsView.setAllowedExtensions(extensions: self.allowedExtensions)
        nsView.setAcceptsDirectory(flag: self.acceptsDirectory)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFileDragged:self.fileUSage)
    }
    
    class Coordinator {
        var onFileDragged:(([URL]) -> Void)
        
        init(
            onFileDragged: @escaping (([URL]) -> Void)
        ) {
            self.onFileDragged = onFileDragged
        }
        
        func handleFileDragged(URLS: [URL]){
            self.onFileDragged(URLS)
        }
    }
}


struct example: View {
    @State var paths:[String] = []
    @State var extensions:[String] = ["csv", "xlsx"]
    var body: some View{
        VStack{
            List {
                ForEach(Array(paths.enumerated()), id: \.0){ index, path in
                    Text(path)
                }
            }
            Text("Drag \(extensions.joined(separator: "/")) over here")
                .frame(minWidth: 500, minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [10, 2]))
                )
                .background(
                    FileDraggerView(fileUSage: { URLS in
                        paths.removeAll()
                        for url in URLS {
                            paths.append(url.path)
                            print(url.path)
                        }
                    }, allowedExtensions: extensions, acceptsDirectory: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
                .animation(nil)
                .padding()
        }
    }
}

#Preview {
    example()
}
