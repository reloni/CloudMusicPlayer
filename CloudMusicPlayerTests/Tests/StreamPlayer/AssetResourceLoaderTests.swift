//
//  AssetResourceLoaderTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class AssetResourceLoaderTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	var httpClient: HttpClientProtocol!
	var streamObserver: UrlSessionStreamObserver!
	var avAssetObserver: AVAssetResourceLoaderEventsObserver!
	var cacheTask: StreamDataTask!
	
	//let sleepInterval = 0.02
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		streamObserver = UrlSessionStreamObserver()
		request = FakeRequest(url: NSURL(string: "https://test.com"))
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
		utilities.fakeSession = session
		utilities.streamObserver = streamObserver
		httpClient = HttpClient(urlSession: session, httpUtilities: utilities)
		//cacheTask = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: false, targetMimeType: nil) as! StreamDataCacheTask
		cacheTask = utilities.createStreamDataTask(NSUUID().UUIDString, request: request,
		                                           sessionConfiguration: NSURLSession.defaultConfig,
		                                           cacheProvider: MemoryCacheProvider(uid: NSUUID().UUIDString)) as! StreamDataTask
		avAssetObserver = AVAssetResourceLoaderEventsObserver()
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
		utilities.streamObserver = nil
		utilities = nil
		streamObserver = nil
		cacheTask = nil
		avAssetObserver = nil
	}
	
	func testReceiveResponseAndGetCorrectUtiTypeFromResponseMimeType() {
		let fakeResponse = FakeResponse(contentLenght: Int64(26))
		fakeResponse.MIMEType = "audio/mpeg"
		
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
		                                                     dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
					
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
				
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
			}.addDisposableTo(bag)
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertTrue(assetLoader.response as? FakeResponse === fakeResponse, "Should cache correct response")
		XCTAssertEqual("public.mp3", assetLoader.contentUti, "Should get mime from response and convert to correct uti")
	}
	
	func testOverrideContentType() {
		let fakeResponse = FakeResponse(contentLenght: Int64(26))
		fakeResponse.MIMEType = "audio/mpeg"
		
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
		                                                     dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
					
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
			}.addDisposableTo(bag)
		
		// create asset loader and override content type with aac audio
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: ContentType.aac, createSchedulerForObserving: false)
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertTrue(assetLoader.response as? FakeResponse === fakeResponse, "Should cache correct response")
		XCTAssertEqual("public.aac-audio", assetLoader.contentUti, "Should return correct overriden uti type")
	}
	
	func testReceiveNewLoadingRequest() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		// should wait untill background schediler perform tasks in another thread
		//NSThread.sleepForTimeInterval(sleepInterval)
		
		XCTAssertEqual(1, assetLoader.currentLoadingRequests.count)
		XCTAssertEqual(assetRequest.hash, assetLoader.currentLoadingRequests.first?.hash)
	}
	
	func testNotCacheSameLoadingRequestMoreThanOnce() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		
		// send this event to start internal observing
		self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		// should wait untill background schediler perform tasks in another thread
		//NSThread.sleepForTimeInterval(sleepInterval)
		
		XCTAssertEqual(1, assetLoader.currentLoadingRequests.count)
		XCTAssertEqual(assetRequest.hash, assetLoader.currentLoadingRequests.first?.hash)
	}
	
	func testRemoveCanceledLoadingRequest() {
		let assetRequest1 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		let assetRequest2 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		
		// send this event to start internal observing
		self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
		avAssetObserver.publishSubject.onNext(.DidCancelLoading(assetRequest1))
		
		// should wait untill background schediler perform tasks in another thread
		//NSThread.sleepForTimeInterval(sleepInterval)
		
		XCTAssertEqual(1, assetLoader.currentLoadingRequests.count)
		XCTAssertEqual(assetRequest2.hash, assetLoader.currentLoadingRequests.first?.hash)
	}
	
	func testRespondWithCorrectDataForOneContentRequest() {
		let contentRequest = FakeAVAssetResourceLoadingContentInformationRequest()
		contentRequest.contentLength = 0
		let dataRequest = FakeAVAssetResourceLoadingDataRequest()
		dataRequest.requestedLength = 22
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: contentRequest,
			dataRequest: dataRequest)
		
		let testData = ["First", "Second", "Third", "Fourth"]
		let sendedData = NSMutableData()
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					let fakeResponse = FakeResponse(contentLenght: Int64(dataRequest.requestedLength))
					fakeResponse.MIMEType = "audio/mpeg"
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
						// simulate delay
						NSThread.sleepForTimeInterval(0.01)
					}
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
		}.addDisposableTo(bag)
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		// should wait untill background schediler perform tasks in another thread (caching not complete at this time)
		//NSThread.sleepForTimeInterval(sleepInterval)

		XCTAssertTrue(sendedData.isEqualToData(dataRequest.respondedData), "Check correct data sended to dataRequest")
		XCTAssertEqual(0, assetLoader.currentLoadingRequests.count, " Check remove loading request from collection of pending requests")
		XCTAssertTrue(assetRequest.finished, "Check loading request if finished")
		XCTAssertTrue(contentRequest.byteRangeAccessSupported, "Should set byteRangeAccessSupported to true")
		XCTAssertEqual(contentRequest.contentLength, Int64(dataRequest.requestedLength), "Check correct content length")
		XCTAssertEqual(contentRequest.contentType, "public.mp3", "Check correct mime type")
	}
	
	func testRespondWithCorrectDataForTwoConcurrentRequests() {
		let contentRequest1 = FakeAVAssetResourceLoadingContentInformationRequest()
		contentRequest1.contentLength = 0
		let dataRequest1 = FakeAVAssetResourceLoadingDataRequest()
		dataRequest1.requestedLength = 11
		let assetRequest1 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: contentRequest1,
			dataRequest: dataRequest1)
		
		let contentRequest2 = FakeAVAssetResourceLoadingContentInformationRequest()
		contentRequest2.contentLength = 0
		let dataRequest2 = FakeAVAssetResourceLoadingDataRequest()
		dataRequest2.requestedLength = 11
		dataRequest2.currentOffset = 11
		dataRequest2.requestedOffset = 11
		let assetRequest2 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: contentRequest2,
			dataRequest: dataRequest2)
		
		let testData = ["First", "Second", "Third", "Fourth"]
		let sendedData = NSMutableData()
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					let fakeResponse = FakeResponse(contentLenght: 22)
					fakeResponse.MIMEType = "audio/mpeg"
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
					
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
						// simulate delay
						NSThread.sleepForTimeInterval(0.01)
					}
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
			}.addDisposableTo(bag)
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents,
		                                      targetAudioFormat: nil, createSchedulerForObserving: false)
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		// should wait untill background schediler perform tasks in another thread (caching not complete at this time)
		//NSThread.sleepForTimeInterval(sleepInterval)
		
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(0, 11)).isEqualToData(dataRequest1.respondedData), "Check half of data sended to first dataRequest")
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(11, 11)).isEqualToData(dataRequest2.respondedData), "Check second half of data sended to secondRequest")
		XCTAssertEqual(0, assetLoader.currentLoadingRequests.count, "Check remove loading request from collection of pending requests")
		
		XCTAssertTrue(assetRequest1.finished, "Check loading first request if finished")
		XCTAssertTrue(contentRequest1.byteRangeAccessSupported, "Should set first request byteRangeAccessSupported to true")
		XCTAssertEqual(contentRequest1.contentLength, 22, "Check correct content length of first request")
		XCTAssertEqual(contentRequest1.contentType, "public.mp3", "Check correct mime type of first")
	}
	
//	func testCacheCorrectDataOnDisk() {
//		let contentRequest = FakeAVAssetResourceLoadingContentInformationRequest()
//		contentRequest.contentLength = 0
//		let dataRequest = FakeAVAssetResourceLoadingDataRequest()
//		dataRequest.requestedLength = 22
//		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: contentRequest,
//		                                                     dataRequest: dataRequest)
//		
//		let testData = ["First", "Second", "Third", "Fourth"]
//		let sendedData = NSMutableData()
//		
//		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
//		
//		session.task?.taskProgress.bindNext { [unowned self] progress in
//			if case .resume(let tsk) = progress {
//				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
//				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
//					let fakeResponse = FakeResponse(contentLenght: Int64(dataRequest.requestedLength))
//					fakeResponse.MIMEType = "audio/mpeg"
//					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
//					
//					for i in 0...testData.count - 1 {
//						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
//						sendedData.appendData(sendData)
//						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
//						// simulate delay
//						NSThread.sleepForTimeInterval(0.01)
//					}
//					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
//				}
//			} else if case .cancel = progress {
//				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
//				// so fulfill expectation here after checking if session was invalidated
//				if self.session.isInvalidatedAndCanceled {
//					// set reference to nil (simutale real session dispose)
//					self.utilities.streamObserver = nil
//					self.streamObserver = nil
//					sessionInvalidationExpectation.fulfill()
//				}
//			}
//			}.addDisposableTo(bag)
//		
//		let saveOnDiskCacheTask = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig,
//		                                                        saveCachedData: true, targetMimeType: nil) as! StreamDataCacheTask
//		var cachedDataUrl: NSURL?
//		saveOnDiskCacheTask.taskProgress.bindNext { result in
//			if case .SuccessWithCache(let success) = result {
//				cachedDataUrl = success.url
//			}
//		}.addDisposableTo(bag)
//		
//		
//		let loader = AssetResourceLoader(cacheTask: saveOnDiskCacheTask.taskProgress, assetLoaderEvents: avAssetObserver.loaderEvents)
//		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
//		
//		saveOnDiskCacheTask.resume()
//		
//		waitForExpectationsWithTimeout(1, handler: nil)
//		// should wait untill background schediler perform tasks in another thread (caching not complete at this time)
//		NSThread.sleepForTimeInterval(0.01)
//		
//		if let cachedDataUrl = cachedDataUrl, data = NSData(contentsOfURL: cachedDataUrl) {
//			XCTAssertTrue(sendedData.isEqualToData(data), "Check equality of sended and cached data")
//			try! NSFileManager.defaultManager().removeItemAtURL(cachedDataUrl)
//		} else {
//			XCTFail("Cached data should be equal to sended data")
//		}
//		
//		XCTAssertTrue(sendedData.isEqualToData(dataRequest.respondedData), "Check correct data sended to dataRequest")
//		XCTAssertEqual(0, loader.currentLoadingRequests.count, " Check remove loading request from collection of pending requests")
//		XCTAssertTrue(assetRequest.isLoadingFinished, "Check loading request if finished")
//		XCTAssertTrue(contentRequest.byteRangeAccessSupported, "Should set byteRangeAccessSupported to true")
//		XCTAssertEqual(contentRequest.contentLength, Int64(dataRequest.requestedLength), "Check correct content length")
//		XCTAssertEqual(contentRequest.contentType, "public.mp3", "Check correct mime type")
//	}
}
