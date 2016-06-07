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
	var streamResourceUrl: Observable<String> { get }
	var streamResourceContentType: ContentType? { get }
	var streamResourceType: Observable<StreamResourceType> { get }
}

public protocol StreamHttpResourceIdentifier {
	var streamHttpHeaders: [String: String]? { get }
}

extension StreamResourceIdentifier {
	public var streamResourceType: Observable<StreamResourceType> {
		return streamResourceUrl.flatMapLatest { url -> Observable<StreamResourceType> in
			if url.hasPrefix("https") {
				return Observable.just(.HttpsResource)
			} else if url.hasPrefix("http") {
				return Observable.just(.HttpResource)
			} else if NSFileManager.fileExistsAtPath(url) {
				return Observable.just(.LocalResource)
			} else {
				return Observable.empty()
			}
		}
	}
}

extension StreamHttpResourceIdentifier {
	public var streamHttpHeaders: [String: String]? {
		return nil
	}
	
	public var hashValue: Int {
		return 0
	}
}

extension String : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return self
	}
	public var streamResourceUrl: Observable<String> {
		return Observable.just(self)
	}
	public var streamResourceContentType: ContentType? {
		return nil
	}
}


extension _SwiftNativeNSString : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return String(self)
	}
	public var streamResourceUrl: Observable<String> {
		return Observable.just(String(self))
	}
	public var streamResourceContentType: ContentType? {
		return nil
	}
}

extension NSString : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return String(self)
	}
	public var streamResourceUrl: Observable<String> {
		return Observable.just(String(self))
	}
	public var streamResourceContentType: ContentType? {
		return nil
	}
}

extension YandexDiskCloudAudioJsonResource : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return uid
	}
	
	public var streamResourceUrl: Observable<String> {
		return downloadUrl
	}
	
	public var streamResourceContentType: ContentType? {
		guard let mime = mimeType, type = ContentType(rawValue: mime) else { return nil }
		return type
	}
}

//extension YandexDiskCloudJsonResource : StreamHttpResourceIdentifier {
//	public var streamHttpHeaders: [String: String]? {
//		return getRequestHeaders()
//	}
//}

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