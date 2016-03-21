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
				task.dataTask.cancel()
				tasks.removeValueForKey(task.uid)
			}
		}.shareReplay(1)
	}
}

public protocol StreamDataTaskProtocol {
	var request: NSMutableURLRequestProtocol { get }
	var taskProgress: Observable<StreamDataResult> { get }
	func resume()
	func suspend()
	func cancel()
}

public class StreamDataTask {
	private var bag = DisposeBag()
	public let request: NSMutableURLRequestProtocol
	internal let httpUtilities: HttpUtilitiesProtocol
	internal let sessionConfiguration: NSURLSessionConfiguration
	
	private var uid: String {
		return request.URL?.URLString ?? ""
	}
	
	internal lazy var dataTask: NSURLSessionDataTaskProtocol = { [unowned self] in
		return self.session.dataTaskWithRequest(self.request)
	}()
	
	internal lazy var observer: UrlSessionStreamObserverProtocol = { [unowned self] in
		let observer = self.httpUtilities.createUrlSessionStreamObserver()
		observer.sessionProgress.bindNext { result in
			
			}.addDisposableTo(self.bag)
		return observer
	}()
	
	internal lazy var session: NSURLSessionProtocol = { [unowned self] in
		return self.httpUtilities.createUrlSession(self.sessionConfiguration, delegate: self.observer as? NSURLSessionDelegate, queue: nil)
	}()
	
	public init(request: NSMutableURLRequestProtocol, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
		sessionConfiguration: NSURLSessionConfiguration = .defaultSessionConfiguration()) {
		self.request = request
		self.httpUtilities = httpUtilities
		self.sessionConfiguration = sessionConfiguration
	}
	
	deinit {
		print("StreamDataTask deinit")
	}
}

extension StreamDataTask : StreamDataTaskProtocol {
	public var taskProgress: Observable<StreamDataResult> {
		return observer.sessionProgress
	}
	
	public func resume() {
		dataTask.resume()
	}
	
	public func suspend() {
		dataTask.suspend()
	}
	
	public func cancel() {
		dataTask.cancel()
	}
}