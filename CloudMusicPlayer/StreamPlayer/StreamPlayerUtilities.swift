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
	func createavPlayerItem(url: NSURL) -> AVPlayerItemProtocol
	func createInternalPlayer(hostPlayer: RxPlayer) -> InternalPlayerType
}

public class StreamPlayerUtilities { }

extension StreamPlayerUtilities: StreamPlayerUtilitiesProtocol {
	public func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol {
		return AVURLAsset(URL: url)
	}
	
	public func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol {
		return AVPlayerItem(asset: asset as! AVURLAsset)
	}
	
	public func createavPlayerItem(url: NSURL) -> AVPlayerItemProtocol {
		return AVPlayerItem(URL: url)
	}
	
	public func createInternalPlayer(hostPlayer: RxPlayer) -> InternalPlayerType {
		return InternalPlayer(hostPlayer: hostPlayer)
	}
}