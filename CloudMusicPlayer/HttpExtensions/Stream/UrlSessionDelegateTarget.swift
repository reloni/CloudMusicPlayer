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
	var sessionProgress: PublishSubject<StreamDataResult> { get }
}

@objc public class UrlSessionStreamObserver : NSObject {
	public let sessionProgress = PublishSubject<StreamDataResult>()
	private var totalDataReceived: UInt64 = 0
	private var expectedDataLength: Int64 = 0
	deinit {
		print("UrlSessionStreamObserver deinit")
	}
}

extension UrlSessionStreamObserver : UrlSessionStreamObserverProtocol { }

extension UrlSessionStreamObserver : NSURLSessionDataDelegate {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		if let response = response as? NSHTTPURLResponse {
			expectedDataLength = response.expectedContentLength
			sessionProgress.onNext(.StreamedResponse(response))
		}
		
		completionHandler(.Allow)
	}
	
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		totalDataReceived += UInt64(data.length)
		sessionProgress.onNext(.StreamedData(data))
		sessionProgress.onNext(.StreamProgress(totalDataReceived, expectedDataLength))
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let error = error {
			sessionProgress.onNext(.Error(error))
		} else {
			sessionProgress.onNext(.Success(totalDataReceived))
		}
		sessionProgress.onCompleted()
		session.invalidateAndCancel()
	}
}

