//
//  NSURLSessionDataDelegate.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public enum SessionDataEvents {
	case didReceiveResponse(session: NSURLSessionProtocol, dataTask: NSURLSessionDataTaskProtocol, response: NSURLResponseProtocol,
		completion: (NSURLSessionResponseDisposition) -> Void)
	case didReceiveData(session: NSURLSessionProtocol, dataTask: NSURLSessionDataTaskProtocol, data: NSData)
	case didCompleteWithError(session: NSURLSessionProtocol, dataTask: NSURLSessionTaskProtocol, error: NSError?)
}

@objc public class NSURLSessionDataEventsObserver : NSObject, NSURLSessionDataDelegate {
	internal var sessionEvents = PublishSubject<SessionDataEvents>()
}

extension NSURLSessionDataEventsObserver {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse,
		completionHandler: (NSURLSessionResponseDisposition) -> Void) {
			sessionEvents.onNext(.didReceiveResponse(session: session, dataTask: dataTask, response: response, completion: completionHandler))
	}
	
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		sessionEvents.onNext(.didReceiveData(session: session, dataTask: dataTask, data: data))
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		sessionEvents.onNext(.didCompleteWithError(session: session, dataTask: task, error: error))
	}
}