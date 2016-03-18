//
//  FakeStream.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import CloudMusicPlayer
import RxSwift

//enum FakeStreamDataTaskMethods {
//	case resume(FakeStreamDataTask)
//	case suspend(FakeStreamDataTask)
//	case cancel(FakeStreamDataTask)
//}
//
//class FakeStreamDataTask : StreamDataTaskProtocol {
//	let observer: UrlSessionStreamObserverProtocol
//	
//	var taskProgress: Observable<StreamDataResult> {
//		return observer.sessionProgress
//	}
//	
//	var methods = PublishSubject<FakeStreamDataTaskMethods>()
//	let httpUtilities: HttpUtilitiesProtocol
//	let request: NSMutableURLRequestProtocol
//	
//	init(request: NSMutableURLRequestProtocol, observer: UrlSessionStreamObserverProtocol, httpUtilities: HttpUtilitiesProtocol) {
//		self.request = request
//		self.observer = observer
//		self.httpUtilities = httpUtilities
//	}
//	
//	func resume() {
//		methods.onNext(.resume(self))
//	}
//	
//	func suspend() {
//		methods.onNext(.suspend(self))
//	}
//	
//	func cancel() {
//		methods.onNext(.cancel(self))
//	}
//}

//class FakeUrlSessionStreamObserver : UrlSessionStreamObserverProtocol {
//	let subject = PublishSubject<StreamDataResult>()
//	var sessionProgress: Observable<StreamDataResult> {
//		return subject
//	}
//}