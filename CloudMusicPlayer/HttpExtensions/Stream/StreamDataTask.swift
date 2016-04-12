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

public protocol StreamTaskEventsProtocol { }

public enum StreamTaskEvents : StreamTaskEventsProtocol {
	/// Send this event if CacheProvider specified
	case CacheData(CacheProvider)
	/// Send this event only if CacheProvider is nil
	case ReceiveData(NSData)
	case ReceiveResponse(NSHTTPURLResponseProtocol)
	case Error(NSError)
	case Success(cache: CacheProvider?)
}

public protocol StreamDataTaskProtocol : StreamTaskProtocol {
	var request: NSMutableURLRequestProtocol { get }
	var taskProgress: Observable<StreamTaskEvents> { get }
	var sessionConfiguration: NSURLSessionConfiguration { get }
	var cacheProvider: CacheProvider? { get }
}

public class StreamDataTask {
	public let uid: String

	public let request: NSMutableURLRequestProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	public let sessionConfiguration: NSURLSessionConfiguration
	public var cacheProvider: CacheProvider?
	internal var response: NSHTTPURLResponseProtocol?
		
	internal lazy var dataTask: NSURLSessionDataTaskProtocol = { [unowned self] in
		return self.session.dataTaskWithRequest(self.request)
		}()
	
	internal lazy var observer: NSURLSessionDataEventsObserverProtocol = { [unowned self] in
			return self.httpUtilities.createUrlSessionStreamObserver()
		}()
	
	internal lazy var session: NSURLSessionProtocol = { [unowned self] in
		return self.httpUtilities.createUrlSession(self.sessionConfiguration, delegate: self.observer as? NSURLSessionDataDelegate, queue: nil)
		}()
	
	public init(taskUid: String, request: NSMutableURLRequestProtocol, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
	            sessionConfiguration: NSURLSessionConfiguration = .defaultSessionConfiguration(), cacheProvider: CacheProvider?) {
		self.request = request
		self.httpUtilities = httpUtilities
		self.sessionConfiguration = sessionConfiguration
		self.cacheProvider = cacheProvider
		uid = taskUid
	}
	
	public lazy var taskProgress: Observable<StreamTaskEvents> = { [unowned self] in
		return self.observer.sessionEvents.filter { e in
			if case .didReceiveResponse(_, _, let response, let completionHandler) = e {
				completionHandler(.Allow)
				return response as? NSHTTPURLResponseProtocol != nil
			} else { return true }
			}.map { e -> StreamTaskEvents in
				switch e {
				case .didReceiveResponse(_, _, let response, _):
					self.response = response as? NSHTTPURLResponseProtocol
					self.cacheProvider?.expectedDataLength = self.response!.expectedContentLength
					//self.cacheProvider?.contentMimeType = self.response!.MIMEType
					self.cacheProvider?.setContentMimeType(self.response!.getMimeType())
					return StreamTaskEvents.ReceiveResponse(self.response!)
				case .didReceiveData(_, _, let data):
					if let cacheProvider = self.cacheProvider {
						cacheProvider.appendData(data)
						return StreamTaskEvents.CacheData(cacheProvider)
					} else {
						return StreamTaskEvents.ReceiveData(data)
					}
				case .didCompleteWithError(let session, _, let error):
					session.invalidateAndCancel()
					
					if let error = error {
						return StreamTaskEvents.Error(error)
					}
					
					return StreamTaskEvents.Success(cache: self.cacheProvider)
				}
			}.shareReplay(1)
		}()
	
	deinit {
		print("StreamDataTask deinit")
	}
}

extension StreamDataTask : StreamDataTaskProtocol {
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