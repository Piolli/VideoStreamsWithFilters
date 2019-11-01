//
//  Lab3_blur_filter_dylib.swift
//  Lab3_blur_filter_dylib
//
//  Created by Alexandr on 26.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Foundation
import Cocoa

@_cdecl("getFilterName")
public func getFilterName() -> String {
    return "ImageBlur"
}

@_cdecl("getFilter")
public func getFilter() -> ((CIImage) -> CIImage) {
    return { (image: CIImage) -> CIImage in
        
        return image.clampedToExtent().applyingGaussianBlur(sigma: 10).cropped(to: image.extent)
    }
}


