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

public protocol StreamTaskProtocol {
	var uid: String { get }
	func resume()
	func suspend()
	func cancel()
}

public protocol StreamDataTaskProtocol : StreamTaskProtocol {
	var request: NSMutableURLRequestProtocol { get }
	var taskProgress: Observable<StreamDataResult> { get }
	var httpUtilities: HttpUtilitiesProtocol { get }
	var sessionConfiguration: NSURLSessionConfiguration { get }
}

public class StreamDataTask {
	public let uid: String
	
	private var bag = DisposeBag()
	public let request: NSMutableURLRequestProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	public let sessionConfiguration: NSURLSessionConfiguration
		
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
			uid = NSUUID().UUIDString
	}
	
	deinit {
		print("StreamDataTask deinit")
	}
}

extension StreamDataTask : StreamDataTaskProtocol {
	public var taskProgress: Observable<StreamDataResult> {
		return observer.sessionProgress.shareReplay(1)
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