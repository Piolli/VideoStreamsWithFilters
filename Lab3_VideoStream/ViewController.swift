//
//  ViewController.swift
//  Lab3_VideoStream
//
//  Created by Alexandr on 26.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    @IBOutlet weak var ouputVideoStream1: NSImageView!
    let videoStream1URL = URL(string: "http:commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    let videoStream2URL = URL(string: "http:commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    
    private var playerItemObserver: NSKeyValueObservation?
    
    var provider: VideoStreamProvider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider = VideoStreamProvider(outputView: ouputVideoStream1, streamURL: videoStream1URL)
        
    }
    
    override func viewDidAppear() {
        
    }
    
    
    @IBAction func playVideoStream1ButtonWasTapped(_ sender: NSButton) {
        provider.play()
    }
    
    @IBAction func pauseVideoStream1ButtonWasTapped(_ sender: NSButton) {
        provider.pause()
    }
    
}

//MARK: - working with streams
extension ViewController {
    
    
    
}

class VideoStreamProvider {
    
    private var player: AVPlayer!
    private var output: AVPlayerItemVideoOutput!
    private var displayLink: DisplayLink!
    private var context: CIContext = CIContext(options: [CIContextOption.workingColorSpace : NSNull()])
    private var playerItemObserver: NSKeyValueObservation?
    private let outputView: NSView
    private let streamURL: URL
    
    init(outputView: NSView, streamURL: URL) {
        self.outputView = outputView
        self.streamURL = streamURL
    }
    
    func play() {
        if player != nil {
            continuePlay()
            return
        }
        
        outputView.layer = CALayer()
        outputView.layer?.isOpaque = true

        // 1
        let item = AVPlayerItem(url: streamURL)
        output = AVPlayerItemVideoOutput(outputSettings: nil)
        item.add(output)

        // 2
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
        // 1
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard output.hasNewPixelBuffer(forItemTime: time),
              let pixbuf = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
        // 2
        let baseImg = CIImage(cvImageBuffer: pixbuf)
//        let blurImg = baseImg.clampedToExtent().applyingGaussianBlur(sigma: blurRadius).cropped(to: baseImg.extent)
        // 3
        guard let cgImg = context.createCGImage(baseImg, from: baseImg.extent) else { return }

        DispatchQueue.main.async {
            self.outputView.layer?.contents = cgImg
        }
    }

    func pause() {
        player.pause()
//        player.rate = 0
//        displayLink.invalidate()
    }
    
    func continuePlay() {
        player.play()
    }
    
}
