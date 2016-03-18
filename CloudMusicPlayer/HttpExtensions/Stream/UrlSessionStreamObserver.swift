//
//  NSURLSessionDelegate.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public enum StreamDataResult {
	case StreamedData(NSData)
	case StreamedResponse(NSHTTPURLResponse)
	case Error(NSError)
	case Success(UInt64)
	case StreamProgress(UInt64, Int64)
}

public protocol UrlSessionStreamObserverProtocol {
	var sessionProgress: Observable<StreamDataResult> { get }
}

@objc public class UrlSessionStreamObserver : NSObject {
	public let subject = PublishSubject<StreamDataResult>()
	private var totalDataReceived: UInt64 = 0
	private var expectedDataLength: Int64 = 0
	deinit {
		print("UrlSessionStreamObserver deinit")
	}
}

extension UrlSessionStreamObserver : UrlSessionStreamObserverProtocol {
	public var sessionProgress: Observable<StreamDataResult> {
		return subject
	}
}

extension UrlSessionStreamObserver : NSURLSessionDataDelegate {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		if let response = response as? NSHTTPURLResponse {
			expectedDataLength = response.expectedContentLength
			subject.onNext(.StreamedResponse(response))
		}
		
		completionHandler(.Allow)
	}
	
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		totalDataReceived += UInt64(data.length)
		subject.onNext(.StreamedData(data))
		subject.onNext(.StreamProgress(totalDataReceived, expectedDataLength))
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let error = error {
			subject.onNext(.Error(error))
		} else {
			subject.onNext(.Success(totalDataReceived))
		}
		subject.onCompleted()
		session.invalidateAndCancel()
	}
}

