//
//  ViewController.swift
//  Lab3_VideoStream
//
//  Created by Alexandr on 26.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Cocoa
import AVFoundation

typealias ImageFilter = ((CIImage) -> CIImage)
typealias ImageFilterFunction = @convention(c) () -> ImageFilter
typealias ImageFilterNameFunction = @convention(c) () -> String


class ViewController: NSViewController {
    
    let appName = "Lab3_VideoStream.app"
    
    func noFilter(image: CIImage) -> CIImage {
        return image
    }
    
    @IBOutlet weak var videoStream1PopUpButton: NSPopUpButton!
    
    @IBOutlet weak var ouputVideoStream1: NSImageView!
    let videoStream1URL = URL(string: "http:commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    let videoStream2URL = URL(string: "http:commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    
    private var playerItemObserver: NSKeyValueObservation?
    
    var provider: VideoStreamProvider!
    var imageFilters: [String: ImageFilter] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider = VideoStreamProvider(outputView: ouputVideoStream1, streamURL: videoStream1URL, imageFilter: noFilter(image:))
        
        //loads libs
        let libs = getDyLibNamesInAppFolder()
        plog(libs)
        
        for liba in libs {
            var filterName = ""
            let getFilterFuncDyLib = getImageFilterFrom(dylib: liba, filterName: &filterName)
            imageFilters[filterName] = getFilterFuncDyLib
        }
        imageFilters["noFilter"] = noFilter(image:)
        
        videoStream1PopUpButton.removeAllItems()
        videoStream1PopUpButton.addItems(withTitles: imageFilters.keys.map({ (key) -> String in
            return String(key)
        }))
        
        videoStream1PopUpButton.addItem(withTitle: "noFilter")
        videoStream1PopUpButton.selectItem(withTitle: "noFilter")
    }
    

    func plog<T : CustomDebugStringConvertible>(_ str: T) {
        print(str.debugDescription)
        print("\n\n")
    }
    
    @IBAction func playVideoStream1ButtonWasTapped(_ sender: NSButton) {
        provider.play()
    }
    
    @IBAction func pauseVideoStream1ButtonWasTapped(_ sender: NSButton) {
        provider.pause()
    }
    
    @IBAction func videoStream1FilterWasChanged(_ sender: NSPopUpButton) {
        if let filterName = sender.titleOfSelectedItem {
            plog(filterName)
            provider.imageFilter = imageFilters[filterName]
        }
    }
}

//MARK: - working with dylibs
extension ViewController {
    
    func getDyLibNamesInAppFolder() -> [String] {
        var dylibs: [String] = []
        let fileManager = FileManager.default
        
        var path = Bundle.main.bundlePath.replacingOccurrences(of: appName, with: "")
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: path)!
        
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(".dylib") {
                dylibs.append(element)
            }
        }
        
        return dylibs
    }
    
    func getImageFilterFrom(dylib path: String, filterName: inout String) -> ImageFilter {
        guard let handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL) else {
            plog("handle is null")
            return noFilter(image:)
        }
        
        if let function = dlsym(handle, "getFilterName") {
            let f = unsafeBitCast(function, to: ImageFilterNameFunction.self)
            filterName = f()
        }
        
        if let function = dlsym(handle, "getFilter") {
            let f = unsafeBitCast(function, to: ImageFilterFunction.self)
            return f()
        }
         
        if let error = dlerror() {
            print(String(cString: error))
            plog(String(cString: error) + "\n")
        }

        dlclose(handle)
        
        return noFilter(image:)
    }
    
}

class VideoStreamProvider {
    
    private var player: AVPlayer!
    private var output: AVPlayerItemVideoOutput!
    private var displayLink: DisplayLink!
    private var context: CIContext = CIContext(options: [CIContextOption.workingColorSpace : NSNull()])
    private var playerItemObserver: NSKeyValueObservation?
    private let outputView: NSView
    private let streamURL: URL
    public var imageFilter: ImageFilter!
    
    init(outputView: NSView, streamURL: URL, imageFilter: @escaping ImageFilter) {
        self.outputView = outputView
        self.streamURL = streamURL
        self.imageFilter = imageFilter
    }
    
    func play() {
        if player != nil {
            continuePlay()
            return
        }
        
        outputView.layer = CALayer()
        outputView.layer?.isOpaque = true

        let item = AVPlayerItem(url: streamURL)
        output = AVPlayerItemVideoOutput(outputSettings: nil)
        item.add(output)

        playerItemObserver = item.observe(\.status) { [weak self] item, _ in
            guard let self = self, item.status == .readyToPlay  else { return }
            self.playerItemObserver = nil
            self.setupDisplayLink()
            self.player.play()
        }

        player = AVPlayer(playerItem: item)
    }
    
    private func setupDisplayLink() {
        displayLink = DisplayLink(onQueue: .global())
        displayLink.callback = {
            self.displayLinkUpdated()
        }
        displayLink.start()
    }
    
    func displayLinkUpdated() {
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard output.hasNewPixelBuffer(forItemTime: time),
              let pixbuf = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
        
        let baseImg = CIImage(cvImageBuffer: pixbuf)
        let performedImg = imageFilter(baseImg)
        
        guard let cgImg = context.createCGImage(performedImg, from: baseImg.extent) else { return }

        DispatchQueue.main.async {
            self.outputView.layer?.contents = cgImg
        }
    }

    func pause() {
        player.pause()
    }
    
    func continuePlay() {
        player.play()
    }
    
}


