//
//  Lab3_invert_filter_dylib.swift
//  Lab3_invert_filter_dylib
//
//  Created by Alexandr on 26.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Foundation
import Cocoa

@_cdecl("getFilterName")
public func getFilterName() -> String {
    return "ImageInvert"
}

@_cdecl("getFilter")
public func getFilter() -> ((CIImage) -> CIImage) {
    return { (image: CIImage) -> CIImage in
        return image.applyingFilter("CIColorInvert")
    }
}
