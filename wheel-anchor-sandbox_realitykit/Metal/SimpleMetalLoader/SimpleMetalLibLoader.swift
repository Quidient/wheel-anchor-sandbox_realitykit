// CustomModelEntity.swift
// BareBonesARApp
//
//  Created by Julian Dowell  on 4/10/25.
//

import MetalKit

struct MetalLibLoader {

    static var isInitialized = false
    static var textureCache: CVMetalTextureCache!
    static var mtlDevice: MTLDevice!
    static var library: MTLLibrary!

    static func initializeMetal() -> MTLLibrary {
        guard !isInitialized else { fatalError("Metal Not Initialized yet") }

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        mtlDevice = device

        if CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache) != kCVReturnSuccess {
            fatalError()
        }

        guard let library = device.makeDefaultLibrary() else {
            fatalError()
        }
        self.library = library

        isInitialized = true
        return library
    }
}

