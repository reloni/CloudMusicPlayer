//
//  NSURLSessionDelegate.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public enum UrlSessionEvents {
	case ReceiveData(NSData)
	case ReceiveResponce(NSHTTPURLResponseProtocol)
	case Error(NSError)
	case Success()
	//case StreamProgress(UInt64, Int64)
}

public protocol UrlSessionStreamObserverProtocol {
	var sessionProgress: Observable<UrlSessionEvents> { get }
}

@objc public class UrlSessionStreamObserver : NSURLSessionDataEventsObserver {
	private let bag = DisposeBag()
	private let publishSubject = PublishSubject<UrlSessionEvents>()
	//private var totalDataReceived: UInt64 = 0
	//private var expectedDataLength: Int64 = 0
	
	public override init() {
		super.init()
		bindToEvents()
	}
	
	private func bindToEvents() {
		sessionEvents.bindNext { [unowned self] response in
		 switch response {
				case .didReceiveResponse(_, _, let response, let completionHandler):
					if let response = response as? NSHTTPURLResponseProtocol {
						//self.expectedDataLength = response.expectedContentLength
						self.publishSubject.onNext(.ReceiveResponce(response))
					}
					completionHandler(.Allow)
				case .didReceiveData(_,_, let data):
					//self.totalDataReceived += UInt64(data.length)
					self.publishSubject.onNext(.ReceiveData(data))
					//self.publishSubject.onNext(.StreamProgress(self.totalDataReceived, self.expectedDataLength))
				case .didCompleteWithError(let session, _, let error):
					if let error = error {
						self.publishSubject.onNext(.Error(error))
					} else {
						//self.publishSubject.onNext(.Success(self.totalDataReceived))
						self.publishSubject.onNext(.Success())
					}
					self.publishSubject.onCompleted()
					session.invalidateAndCancel()
			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("UrlSessionStreamObserver deinit")
	}
}

extension UrlSessionStreamObserver : UrlSessionStreamObserverProtocol {
	public var sessionProgress: Observable<UrlSessionEvents> {
		return publishSubject
	}
}