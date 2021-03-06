//
//  AudioItemMetadata.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

public class AudioItemMetadata {
	public internal(set) var resourceUid: String
	internal let metadata: [String: AnyObject?]
	public init(resourceUid: String, metadata: [String: AnyObject?]) {
		self.metadata = metadata
		self.resourceUid = resourceUid
	}
	public lazy var title: String? = {
		return self.metadata["title"] as? String
	}()
	
	public lazy var artist: String? = {
		return self.metadata["artist"] as? String
	}()
	
	public lazy var album: String? = {
		return self.metadata["albumName"] as? String
	}()
	
	public lazy var artwork: NSData? = {
		return self.metadata["artwork"] as? NSData
	}()
	
	public lazy var duration: Float? = {
		return self.metadata["duration"] as? Float
	}()
}
extension AudioItemMetadata: MediaItemMetadataType {
}