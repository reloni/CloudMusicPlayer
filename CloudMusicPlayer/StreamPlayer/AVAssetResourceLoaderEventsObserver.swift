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
	case shouldWaitForLoading(AVAssetResourceLoadingRequestProtocol)
	case didCancelLoading(AVAssetResourceLoadingRequestProtocol)
	/// this event will send when AVAssetResourceLoaderEventsObserver will deinit
	case observerDeinit
}

public protocol AVAssetResourceLoaderEventsObserverProtocol {
	var loaderEvents: Observable<AssetLoadingEvents> { get }
	var shouldWaitForLoading: Bool { get set }
}

@objc public class AVAssetResourceLoaderEventsObserver : NSObject {
	internal let publishSubject = PublishSubject<AssetLoadingEvents>()
	public var shouldWaitForLoading: Bool
	
	public init(shouldWaitForLoading: Bool = true) {
		self.shouldWaitForLoading = shouldWaitForLoading
	}
	
	deinit {
		print("AVAssetResourceLoaderEventsObserver deinit")
		publishSubject.onNext(.observerDeinit)
	}
}

extension AVAssetResourceLoaderEventsObserver : AVAssetResourceLoaderEventsObserverProtocol {
	public var loaderEvents: Observable<AssetLoadingEvents> {
		return publishSubject
	}
}

extension AVAssetResourceLoaderEventsObserver : AVAssetResourceLoaderDelegate {	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		publishSubject.onNext(.shouldWaitForLoading(loadingRequest))
		return shouldWaitForLoading
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		publishSubject.onNext(.didCancelLoading(loadingRequest))
	}
}