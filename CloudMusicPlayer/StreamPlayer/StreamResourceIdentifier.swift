////
////  StreamResourceIdentifier.swift
////  CloudMusicPlayer
////
////  Created by Anton Efimenko on 29.03.16.
////  Copyright © 2016 Anton Efimenko. All rights reserved.
////

import Foundation
import RxSwift

public enum StreamResourceType {
	case LocalResource
	case HttpResource
	case HttpsResource
}

public protocol StreamResourceIdentifier {
	var streamResourceUid: String { get }
	var streamResourceUrl: String? { get }
	var streamResourceContentType: ContentType? { get }
	var streamResourceType: StreamResourceType? { get }
}
extension StreamResourceIdentifier {
	public var streamResourceType: StreamResourceType? {
		guard let url = streamResourceUrl, scheme = NSURLComponents(string: url)?.scheme else { return nil }
		switch scheme {
			case "file": return .LocalResource
			case "http": return .HttpResource
			case "https": return .HttpsResource
			default: return nil
		}
	}
}
extension String : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return self
	}
	public var streamResourceUrl: String? {
		return self
	}
	public var streamResourceContentType: ContentType? {
		return nil
	}
}
extension YandexDiskCloudAudioJsonResource : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return path
	}
	
	public var streamResourceUrl: String? {
		let dispatchGroup = dispatch_group_create()
		var url: String? = nil
		// use dispatch group to perfort sync operation
		dispatch_group_enter(dispatchGroup)
		let disposable = downloadUrl?.bindNext { result in
			url = result
			dispatch_group_leave(dispatchGroup)
		}
		
		// wait until async is completed
		dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)))
		disposable?.dispose()
		return url
	}
	
	public var streamResourceContentType: ContentType? {
		guard let mime = mimeType, type = ContentType(rawValue: mime) else { return nil }
		return type
	}
}