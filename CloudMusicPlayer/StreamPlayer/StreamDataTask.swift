//
//  StreamConnection.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public enum StreamResult {
	case StreamedData(NSData)
	case StreamedResponse(NSHTTPURLResponse)
	case Error(NSError)
	case Success
}

public struct UrlStreamManager {
	private static var tasks = [String: UrlStreamDataTask]()
	
	private static func task(session: NSURLSession, request: NSMutableURLRequest) -> Observable<StreamResult>? {
		return Observable.create { observer in
			let task = UrlStreamDataTask(session: session, request: request)
			tasks[task.uid] = task
			
			task.latestReceivedData.asObservable().bindNext { data in
				observer.on(.Next(.StreamedData(data)))
				}.addDisposableTo(task.bag)
			
			task.error.asObservable().bindNext { error in
				if let error = error {
					observer.onNext(.Error(error))
				} else {
					observer.onNext(.Success)
				}
				observer.onCompleted()
				}.addDisposableTo(task.bag)
			
			task.response.asObservable().bindNext { response in
				guard let response = response else {
					return
				}
				observer.onNext(.StreamedResponse(response))
				}.addDisposableTo(task.bag)
			
			return AnonymousDisposable {
				task.dataTask.cancel()
				tasks[task.uid] = nil
			}
		}
	}
}

@objc public class UrlStreamDataTask : NSObject {
	private var bag = DisposeBag()
	private let request: NSMutableURLRequest
	private var response = Variable<NSHTTPURLResponse?>(nil)
	private var latestReceivedData = Variable<NSData>(NSData())
	private var error = Variable<NSError?>(nil)
	private var dataTask: NSURLSessionDataTask
	private var uid: String {
		return request.URLString
	}
	
	private init(session: NSURLSession, request: NSMutableURLRequest) {
		self.request = request
		dataTask = session.dataTaskWithRequest(request)
		dataTask.resume()
	}
	
	private convenience init(session: NSURLSession, url: NSURL, headers: [String: String]? = nil) {
		let newRequest = NSMutableURLRequest(URL: url)
		headers?.forEach { header, value in
			newRequest.addValue(value, forHTTPHeaderField: header)
		}
		self.init(session: session, request: newRequest)
	}
}

extension UrlStreamDataTask : NSURLSessionDataDelegate {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		//print("didReceiveResponse")
		self.response.value = response as? NSHTTPURLResponse
		
		completionHandler(.Allow)
	}
	
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		//print("didReceiveData")
		latestReceivedData.value = data
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		//print("didCompleteWithError")
		self.error.value = error
	}
}