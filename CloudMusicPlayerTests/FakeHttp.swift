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
	public func addValue(value: String, forHTTPHeaderField: String) {
		headers[forHTTPHeaderField] = value
	}
}

public enum FakeDataTaskMethods {
	case resume(FakeDataTask)
	case suspend(FakeDataTask)
}

public class FakeDataTask : NSURLSessionDataTaskProtocol {
	let completion: DataTaskResult?
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
	public func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return FakeDataTask(completion: completionHandler)
	}
	
	public func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return FakeDataTask(completion: completionHandler)
	}
}