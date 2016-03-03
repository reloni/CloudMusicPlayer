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

public enum StreamDataResult {
	case StreamedData(NSData)
	case StreamedResponse(NSHTTPURLResponse)
	case Error(NSError)
	case Success
}

public struct StreamDataTaskManager {
	public static var tasks = [String: StreamDataTask]()
	
	public static func createTask(request: NSMutableURLRequest) -> Observable<StreamDataResult>? {
		return Observable.create { observer in
			let task = StreamDataTask(request: request)
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
				tasks.removeValueForKey(task.uid)
				}.addDisposableTo(task.bag)
			
			task.response.asObservable().bindNext { response in
				guard let response = response else {
					return
				}
				observer.onNext(.StreamedResponse(response))
				}.addDisposableTo(task.bag)
			
			task.resume()
			
			return AnonymousDisposable {
				task.dataTask?.cancel()
				tasks.removeValueForKey(task.uid)
			}
		}.shareReplay(1)
	}
}

@objc public class StreamDataTask : NSObject {
	private var bag = DisposeBag()
	private let request: NSMutableURLRequest
	private var response = Variable<NSHTTPURLResponse?>(nil)
	private var latestReceivedData = PublishSubject<NSData>()//Variable<NSData>(NSData())
	private var error = PublishSubject<NSError?>()//Variable<NSError?>(nil)
	private var dataTask: NSURLSessionDataTask?
	private var uid: String {
		return request.URLString
	}
	private var session: NSURLSession?
	
	public init(request: NSMutableURLRequest) {
		self.request = request
	}
	
	deinit {
		print("StreamDataTask deinit")
	}
	
	public convenience init(url: NSURL, headers: [String: String]? = nil) {
		let newRequest = NSMutableURLRequest(URL: url)
		headers?.forEach { header, value in
			newRequest.addValue(value, forHTTPHeaderField: header)
		}
		self.init(request: newRequest)
	}
	
	public func resume() {
		let session = NSURLSession(configuration: .defaultSessionConfiguration(),
			delegate: self,
			delegateQueue: NSOperationQueue.mainQueue())
		dataTask = session.dataTaskWithRequest(request)
		self.session = session
		dataTask?.resume()
	}
}

extension StreamDataTask : NSURLSessionDataDelegate {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		self.response.value = response as? NSHTTPURLResponse
		
		completionHandler(.Allow)
	}

	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		latestReceivedData.onNext(data)
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		self.error.onNext(error)
		self.error.onCompleted()
		latestReceivedData.onCompleted()
		session.invalidateAndCancel()
	}
}