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

public enum StreamTaskEvents {
	/// Send this event if CacheProvider specified
	case CacheData(CacheProvider)
	/// Send this event only if CacheProvider is nil
	case ReceiveData(NSData)
	case ReceiveResponse(NSHTTPURLResponseProtocol)
	case Error(NSError)
	case Success(cache: CacheProvider?)
	//case StreamProgress(UInt64, UInt64)
}

public protocol StreamDataTaskProtocol : StreamTaskProtocol {
	var request: NSMutableURLRequestProtocol { get }
	var taskProgress: Observable<StreamTaskEvents> { get }
	//var httpUtilities: HttpUtilitiesProtocol { get }
	var sessionConfiguration: NSURLSessionConfiguration { get }
	var cacheProvider: CacheProvider? { get }
}

public class StreamDataTask {
	public let uid: String
	
	private var bag = DisposeBag()
	public let request: NSMutableURLRequestProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	public let sessionConfiguration: NSURLSessionConfiguration
	public var cacheProvider: CacheProvider?
	internal var response: NSHTTPURLResponseProtocol?
		
	internal lazy var dataTask: NSURLSessionDataTaskProtocol = { [unowned self] in
		return self.session.dataTaskWithRequest(self.request)
		}()
	
	internal lazy var observer: UrlSessionStreamObserverProtocol = { [unowned self] in
		let observer = self.httpUtilities.createUrlSessionStreamObserver()
		//observer.sessionProgress.bindNext { result in
			
		//	}.addDisposableTo(self.bag)
		return observer
		}()
	
	internal lazy var session: NSURLSessionProtocol = { [unowned self] in
		return self.httpUtilities.createUrlSession(self.sessionConfiguration, delegate: self.observer as? NSURLSessionDelegate, queue: nil)
		}()
	
	public init(request: NSMutableURLRequestProtocol, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
	            sessionConfiguration: NSURLSessionConfiguration = .defaultSessionConfiguration(), cacheProvider: CacheProvider?) {
		self.request = request
		self.httpUtilities = httpUtilities
		self.sessionConfiguration = sessionConfiguration
		self.cacheProvider = cacheProvider
		uid = NSUUID().UUIDString
	}
	
	public lazy var taskProgress: Observable<StreamTaskEvents> = { [unowned self] in
		return self.observer.sessionProgress.map { result in
				switch result {
				case .ReceiveData(let data):
					if let cacheProvider = self.cacheProvider {
						cacheProvider.appendData(data)
						return StreamTaskEvents.CacheData(cacheProvider)
					} else {
						return StreamTaskEvents.ReceiveData(data)
					}
					//self.cacheProvider?.appendData(data)
					//return StreamTaskEvents.ReceiveData(cache: self.cacheProvider)
				case .ReceiveResponce(let response):
					self.response = response
					self.cacheProvider?.expectedDataLength = response.expectedContentLength
					return StreamTaskEvents.ReceiveResponse(response)
				case .Error(let error): return StreamTaskEvents.Error(error)
				case .Success: return StreamTaskEvents.Success(cache: self.cacheProvider)
				}
			}.shareReplay(1)
		}()
	
	deinit {
		print("StreamDataTask deinit")
	}
}

extension StreamDataTask : StreamDataTaskProtocol {
//	public var taskProgress: Observable<StreamTaskEvents> {
//		return observer.sessionProgress.shareReplay(1)
//	}
	

	
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