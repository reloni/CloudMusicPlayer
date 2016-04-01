////
////  StreamResourceIdentifier.swift
////  CloudMusicPlayer
////
////  Created by Anton Efimenko on 29.03.16.
////  Copyright © 2016 Anton Efimenko. All rights reserved.
////

import Foundation
import RxSwift

public protocol StreamResourceIdentifier {
	var streamResourceUid: String { get }
	var streamResourceUrl: String? { get }
}
extension String : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return self
	}
	public var streamResourceUrl: String? {
		return self
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
}