//
//  AssetResourceLoader.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

public class AssetResourceLoader : NSObject {
	
}

extension AssetResourceLoader : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		return false
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		
	}
}