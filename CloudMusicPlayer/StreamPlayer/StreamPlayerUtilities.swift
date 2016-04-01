//
//  StreamPlayerUtilities.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

internal protocol StreamPlayerUtilitiesProtocol {
	func createAVPlayer(streamItem: StreamAudioItem) -> AVPlayer?
	func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol
	func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol
	func createStreamAudioItem(player: StreamAudioPlayer, cacheItem: CacheItem) -> StreamAudioItem
//	func createStreamResourceIdentifier(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol,
//	                                    saveCachedData: Bool, targetMimeType: String?) -> StreamResourceIdentifier
}

internal class StreamPlayerUtilities {
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
	internal func createAVPlayer(streamItem: StreamAudioItem) -> AVPlayer? {
		guard let item = streamItem.playerItem else { return nil }
		return AVPlayer(playerItem: item as! AVPlayerItem)
	}
	
	internal func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol {
		return AVURLAsset(URL: url)
	}
	
	internal func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol {
		return AVPlayerItem(asset: asset as! AVURLAsset)
	}
	
	internal func createStreamAudioItem(player: StreamAudioPlayer, cacheItem: CacheItem) -> StreamAudioItem {
		return StreamAudioItem(cacheItem: cacheItem, player: player)
	}
	
//	internal func createStreamResourceIdentifier(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol,
//																						saveCachedData: Bool, targetMimeType: String?) -> StreamResourceIdentifier {
//		return StreamUrlResourceIdentifier(urlRequest: urlRequest, httpClient: httpClient,
//		                                   saveCachedData: saveCachedData, targetMimeType: targetMimeType)
//	}
}