//
//  NSURLSessionDelegate.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public enum UrlSessionEvents {
	case ReceiveData(NSData)
	case ReceiveResponce(NSHTTPURLResponseProtocol)
	case Error(NSError)
	case Success()
}

public protocol UrlSessionStreamObserverProtocol {
	var sessionProgress: Observable<UrlSessionEvents> { get }
}

@objc public class UrlSessionStreamObserver : NSURLSessionDataEventsObserver, UrlSessionStreamObserverProtocol {
	public override init() {
		super.init()
	}
	
	deinit {
		print("UrlSessionStreamObserver deinit")
	}
	
	public lazy var sessionProgress: Observable<UrlSessionEvents> = { [unowned self] in
		return self.sessionEvents.filter { e in
			if case .didReceiveResponse(_, _, let response, let completionHandler) = e {
				completionHandler(.Allow)
				return response as? NSHTTPURLResponseProtocol != nil
			} else { return true }
			}.map { e in
				switch e {
				case .didReceiveResponse(_, _, let response, _):
					return UrlSessionEvents.ReceiveResponce(response as! NSHTTPURLResponseProtocol)
				case .didReceiveData(_, _, let data):
					return UrlSessionEvents.ReceiveData(data)
				case .didCompleteWithError(let session, _, let error):
					session.invalidateAndCancel()
					if let error = error { return UrlSessionEvents.Error(error) }
					return UrlSessionEvents.Success()
				}
			}.shareReplay(1)
		}()
}