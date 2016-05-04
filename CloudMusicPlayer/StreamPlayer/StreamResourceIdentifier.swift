////
////  StreamResourceIdentifier.swift
////  CloudMusicPlayer
////
////  Created by Anton Efimenko on 29.03.16.
////  Copyright © 2016 Anton Efimenko. All rights reserved.
////

import Foundation
import RxSwift
import RxBlocking

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

public protocol StreamHttpResourceIdentifier {
	var streamHttpHeaders: [String: String]? { get }
}

extension StreamResourceIdentifier {
	public var streamResourceType: StreamResourceType? {
		guard let url = streamResourceUrl else { return nil }
		if url.hasPrefix("https") {
			return .HttpsResource
		} else if url.hasPrefix("http") {
			return .HttpResource
		} else if NSFileManager.fileExistsAtPath(url) {
			return .LocalResource
		} else {
			return nil
		}
	}
//		guard let scheme = NSURLComponents(string: url)?.scheme else {
//			if NSFileManager.fileExistsAtPath(url, isDirectory: false) {
//				return .LocalResource
//			} else { return nil }
//		}
//		
//		switch scheme {
//			case "http": return .HttpResource
//			case "https": return .HttpsResource
//			default: return nil
//		}
//	}
}

extension StreamHttpResourceIdentifier {
	public var streamHttpHeaders: [String: String]? {
		return nil
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


extension _SwiftNativeNSString : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return String(self)
	}
	public var streamResourceUrl: String? {
		return String(self)
	}
	public var streamResourceContentType: ContentType? {
		return nil
	}
}


extension YandexDiskCloudAudioJsonResource : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return uid
	}
	
	public var streamResourceUrl: String? {		
		do {
			let array = try downloadUrl.toBlocking().toArray()
			return array.first ?? nil
		} catch { return nil }
	}
	
	public var streamResourceContentType: ContentType? {
		guard let mime = mimeType, type = ContentType(rawValue: mime) else { return nil }
		return type
	}
}

extension YandexDiskCloudJsonResource : StreamHttpResourceIdentifier {
	public var streamHttpHeaders: [String: String]? {
		return getRequestHeaders()
	}
}

//extension GoogleDriveCloudAudioJsonResource : StreamResourceIdentifier {
//	public var streamResourceUid: String {
//		return uid
//	}
//	
//	public var streamResourceUrl: String? {
//		do {
//			let array = try downloadUrl.toBlocking().toArray()
//			return array.first ?? nil
//		} catch { return nil }
//	}
//	
//	public var streamResourceContentType: ContentType? {
//		guard let mime = mimeType, type = ContentType(rawValue: mime) else { return nil }
//		return type
//	}
//}
//
//extension GoogleDriveCloudJsonResource : StreamHttpResourceIdentifier {
//	public var streamHttpHeaders: [String: String]? {
//		return getRequestHeaders()
//	}
//}