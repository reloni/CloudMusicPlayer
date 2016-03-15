//
//  FakeHttp.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import CloudMusicPlayer
import RxSwift

public class FakeRequest : NSMutableURLRequestProtocol {
	var headers = [String: String]()
	public var URL: NSURL?
	
	public init(url: NSURL? = nil) {
		self.URL = url
	}
	
	public func addValue(value: String, forHTTPHeaderField: String) {
		headers[forHTTPHeaderField] = value
	}
}

public enum FakeDataTaskMethods {
	case resume(FakeDataTask)
	case suspend(FakeDataTask)
}

public class FakeDataTask : NSURLSessionDataTaskProtocol {
	var completion: DataTaskResult?
	let taskProgress = PublishSubject<FakeDataTaskMethods>()
	
	public init(completion: DataTaskResult?) {
		self.completion = completion
	}
	
	public func resume() {
		taskProgress.onNext(.resume(self))
	}
	
	public func suspend() {
		taskProgress.onNext(.suspend(self))
	}
}

public class FakeSession : NSURLSessionProtocol {
	var task: FakeDataTask?
	
	public init(fakeTask: FakeDataTask? = nil) {
		task = fakeTask
	}
	
	public func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		guard let task = self.task else {
			return FakeDataTask(completion: completionHandler)
		}
		task.completion = completionHandler
		return task
	}
	
	public func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		guard let task = self.task else {
			return FakeDataTask(completion: completionHandler)
		}
		task.completion = completionHandler
		return task
	}
}

public class FakeHttpUtilities : HttpUtilitiesProtocol {
	public func createUrlRequest(baseUrl: String, parameters: [String : String]?) -> NSMutableURLRequestProtocol? {
		return FakeRequest(url: NSURL(baseUrl: baseUrl, parameters: parameters))
	}
}