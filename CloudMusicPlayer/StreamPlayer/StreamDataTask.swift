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
	case Success(UInt64)
	case StreamProgress(UInt64, Int64)
}

public struct StreamDataTaskManager {
	private static var tasks = [String: StreamDataTask]()
	
	public static func createTask(request: NSMutableURLRequest) -> Observable<StreamDataResult>? {
		return Observable.create { observer in
			let task = StreamDataTask(request: request)
			tasks[task.uid] = task
			
			task.taskProgress.bindNext { result in
				observer.onNext(result)

				if case .Success = result {
					tasks.removeValueForKey(task.uid)
				}
				
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
	private var totalDataReceived: UInt64 = 0
	private var expectedDataLength: Int64 = 0
	private let taskProgress = PublishSubject<StreamDataResult>()
	private var dataTask: NSURLSessionDataTask?
	private var uid: String {
		return request.URL?.absoluteString ?? ""
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
			delegateQueue: nil)
		dataTask = session.dataTaskWithRequest(request)
		self.session = session
		dataTask?.resume()
	}
}

extension StreamDataTask : NSURLSessionDataDelegate {
	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		if let response = response as? NSHTTPURLResponse {
			expectedDataLength = response.expectedContentLength
			taskProgress.onNext(.StreamedResponse(response))
		}
		
		completionHandler(.Allow)
	}

	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		totalDataReceived += UInt64(data.length)
		taskProgress.onNext(.StreamedData(data))
		taskProgress.onNext(.StreamProgress(totalDataReceived, expectedDataLength))
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let error = error {
			taskProgress.onNext(.Error(error))
		} else {
			taskProgress.onNext(.Success(totalDataReceived))
		}
		taskProgress.onCompleted()
		session.invalidateAndCancel()
	}
}