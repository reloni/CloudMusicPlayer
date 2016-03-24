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
	var cacheTask: StreamDataCacheTask!
	
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
		cacheTask = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: false, targetMimeType: nil) as! StreamDataCacheTask
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
	
	func testReceiveNewLoadingRequest() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: avAssetObserver.loaderEvents, observeInNewScheduler: false)
		self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		XCTAssertEqual(1, assetLoader.currentLoadingRequests.count)
		XCTAssertEqual(assetRequest.hash, assetLoader.currentLoadingRequests.first?.hash)
	}
	
	func testNotCacheSameLoadingRequestMoreThanOnce() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: avAssetObserver.loaderEvents, observeInNewScheduler: false)
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		XCTAssertEqual(1, assetLoader.currentLoadingRequests.count)
		XCTAssertEqual(assetRequest.hash, assetLoader.currentLoadingRequests.first?.hash)
	}
	
	func testRemoveCanceledLoadingRequest() {
		let assetRequest1 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		let assetRequest2 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: avAssetObserver.loaderEvents, observeInNewScheduler: false)
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
		avAssetObserver.publishSubject.onNext(.DidCancelLoading(assetRequest1))
		
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
		
		let loader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: avAssetObserver.loaderEvents, observeInNewScheduler: false)
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)

		XCTAssertTrue(sendedData.isEqualToData(dataRequest.respondedData), "Check correct data sended to dataRequest")
		XCTAssertEqual(0, loader.currentLoadingRequests.count, " Check remove loading request from collection of pending requests")
		XCTAssertTrue(assetRequest.isLoadingFinished, "Check loading request if finished")
		XCTAssertTrue(contentRequest.byteRangeAccessSupported, "Should set byteRangeAccessSupported to true")
		XCTAssertEqual(contentRequest.contentLength, Int64(dataRequest.requestedLength), "Check correct content length")
		XCTAssertEqual(contentRequest.contentType, "public.mp3", "Check correct mime type")
	}
	
	func testRespondWithCorrectDataForFirstRequestAndDropSecond() {
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
					
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
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
		
		let loader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: avAssetObserver.loaderEvents, observeInNewScheduler: false)
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		print("Len1: \(dataRequest1.respondedData.length) Len2: \(dataRequest2.respondedData.length)")
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(11, 11)).isEqualToData(dataRequest2.respondedData), "Check half of data sended to first dataRequest")
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(11, 11)).isEqualToData(dataRequest2.respondedData), "Check second half of data sended to secondRequest")
		XCTAssertEqual(0, loader.currentLoadingRequests.count, "Check remove loading request from collection of pending requests")
		
		XCTAssertTrue(assetRequest1.isLoadingFinished, "Check loading first request if finished")
		XCTAssertTrue(contentRequest1.byteRangeAccessSupported, "Should set first request byteRangeAccessSupported to true")
		XCTAssertEqual(contentRequest1.contentLength, 22, "Check correct content length of first request")
		XCTAssertEqual(contentRequest1.contentType, "public.mp3", "Check correct mime type of first")
	}
}
