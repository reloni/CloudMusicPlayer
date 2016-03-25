//
//  AVAssetResourceLoaderEventsObserver.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

public enum AssetLoadingEvents {
	case ShouldWaitForLoading(AVAssetResourceLoadingRequestProtocol)
	case DidCancelLoading(AVAssetResourceLoadingRequestProtocol)
}

public protocol AVAssetResourceLoaderEventsObserverProtocol {
	var loaderEvents: Observable<AssetLoadingEvents> { get }
}

@objc public class AVAssetResourceLoaderEventsObserver : NSObject {
	internal let publishSubject = PublishSubject<AssetLoadingEvents>()
	deinit {
		print("AVAssetResourceLoaderEventsObserver deinit")
	}
}

extension AVAssetResourceLoaderEventsObserver : AVAssetResourceLoaderEventsObserverProtocol {
	public var loaderEvents: Observable<AssetLoadingEvents> {
		return publishSubject
	}
}

extension AVAssetResourceLoaderEventsObserver : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		publishSubject.onNext(.ShouldWaitForLoading(loadingRequest))
		return true
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		publishSubject.onNext(.DidCancelLoading(loadingRequest))
	}
}