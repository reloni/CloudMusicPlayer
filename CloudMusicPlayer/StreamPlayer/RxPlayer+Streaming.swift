//
//  RxPlayer+Streaming.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension Observable where Element : StreamTaskEventsProtocol {
	public func stream(contentType: ContentType? = nil, utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) ->
		Observable<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])> {
			
			let asset = utilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
			//self.asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
			asset.getResourceLoader().setDelegate(GlobalPlayerHolder.instance.observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
			let playerItem = utilities.createavPlayerItem(asset)
			
			let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let task = self.observeOn(scheduler).loadWithAsset(
				assetEvents: GlobalPlayerHolder.instance.observer.loaderEvents.observeOn(scheduler),
				targetAudioFormat: contentType)
			
			GlobalPlayerHolder.instance.initialize(playerItem, asset: asset)
			
			return task
	}
}