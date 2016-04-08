//
//  StreamPlayerUtilities.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

public protocol StreamPlayerUtilitiesProtocol {
	func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol
	func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol
}

public class StreamPlayerUtilities {
	private static var _instance: StreamPlayerUtilitiesProtocol?
	private static var token: dispatch_once_t = 0
	
	internal static var instance: StreamPlayerUtilitiesProtocol  {
		initWithInstance()
		return StreamPlayerUtilities._instance!
	}
	
	internal static func initWithInstance(instance: StreamPlayerUtilitiesProtocol? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? StreamPlayerUtilities()
		}
	}
	
	internal init() { }
}

extension StreamPlayerUtilities: StreamPlayerUtilitiesProtocol {
	public func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol {
		return AVURLAsset(URL: url)
	}
	
	public func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol {
		return AVPlayerItem(asset: asset as! AVURLAsset)
	}
}