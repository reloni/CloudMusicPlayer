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
	var streamObserver: NSURLSessionDataEventsObserver!
	var avAssetObserver: AVAssetResourceLoaderEventsObserver!
	var cacheTask: StreamDataTask!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		streamObserver = NSURLSessionDataEventsObserver()
		request = FakeRequest(url: NSURL(string: "https://test.com"))
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
		utilities.fakeSession = session
		utilities.streamObserver = streamObserver
		httpClient = HttpClient(urlSession: session, httpUtilities: utilities)
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
		
		let assetLoadCompletion = expectationWithDescription("Should complete asset loading")
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
					
					self.streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
				
					self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
				}
			}
			}.addDisposableTo(bag)
		
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			XCTAssertTrue(e.receivedResponse as? FakeResponse === fakeResponse, "Should cache correct response")
			XCTAssertEqual("public.mp3", e.utiType, "Should get mime from response and convert to correct uti")
			assetLoadCompletion.fulfill()
			}.addDisposableTo(bag)
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testOverrideContentType() {
		let fakeResponse = FakeResponse(contentLenght: Int64(26))
		fakeResponse.MIMEType = "audio/mpeg"
		
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
		                                                     dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoadCompletion = expectationWithDescription("Should complete asset loading")
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
					
					self.streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
				}
			}
			}.addDisposableTo(bag)
		
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: ContentType.aac).bindNext { e in
			XCTAssertTrue(e.receivedResponse as? FakeResponse === fakeResponse, "Should cache correct response")
			XCTAssertEqual("public.aac-audio", e.utiType, "Should return correct overriden uti type")
			assetLoadCompletion.fulfill()
		}.addDisposableTo(bag)
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testReceiveNewLoadingRequest() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let expectation = expectationWithDescription("Should receive result from asset loader")
		var result: (receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])?
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			result = e
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(1, result?.resultRequestCollection.count)
		XCTAssertEqual(assetRequest.hash, result?.resultRequestCollection.first?.1.hash)
	}
	
	func testNotCacheSameLoadingRequestMoreThanOnce() {
		let assetRequest = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoadingCompletion = expectationWithDescription("Should complete asset loading")
		
		var result: (receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])?
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			result = e
			assetLoadingCompletion.fulfill()
			}.addDisposableTo(bag)
		
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		
		self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(1, result?.resultRequestCollection.count)
		XCTAssertEqual(assetRequest.hash, result?.resultRequestCollection.first?.1.hash)
	}
	
	func testRemoveCanceledLoadingRequest() {
		let assetRequest1 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		let assetRequest2 = FakeAVAssetResourceLoadingRequest(contentInformationRequest: FakeAVAssetResourceLoadingContentInformationRequest(),
			dataRequest: FakeAVAssetResourceLoadingDataRequest())
		
		let assetLoadingCompletion = expectationWithDescription("Should complete asset loading")
		
		var result: (receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])?
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			result = e
			assetLoadingCompletion.fulfill()
			}.addDisposableTo(bag)
		
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
		avAssetObserver.publishSubject.onNext(.DidCancelLoading(assetRequest1))
		
		self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: FakeDataTask(completion: nil), error: nil))
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(1, result?.resultRequestCollection.count)
		XCTAssertEqual(assetRequest2.hash, result?.resultRequestCollection.first?.1.hash)
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
		
		let assetLoadingCompletion = expectationWithDescription("Should complete asset loading")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					let fakeResponse = FakeResponse(contentLenght: Int64(dataRequest.requestedLength))
					fakeResponse.MIMEType = "audio/mpeg"
					self.streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
						// simulate delay
						NSThread.sleepForTimeInterval(0.01)
					}
					self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
				}
			}
		}.addDisposableTo(bag)
		
		var result: (receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])?
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			result = e
			assetLoadingCompletion.fulfill()
			}.addDisposableTo(bag)
		
		avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest))
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)

		XCTAssertTrue(sendedData.isEqualToData(dataRequest.respondedData), "Check correct data sended to dataRequest")
		XCTAssertEqual(0, result?.resultRequestCollection.count, " Check remove loading request from collection of pending requests")
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
		
		let assetLoadingCompletion = expectationWithDescription("Should complete asset loading")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					let fakeResponse = FakeResponse(contentLenght: 22)
					fakeResponse.MIMEType = "audio/mpeg"
					self.streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: { _ in }))
					
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest1))
					self.avAssetObserver.publishSubject.onNext(.ShouldWaitForLoading(assetRequest2))
					
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
						// simulate delay
						NSThread.sleepForTimeInterval(0.01)
					}
					self.streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
				}
			}
			}.addDisposableTo(bag)
		
		var result: (receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])?
		cacheTask.taskProgress.loadWithAsset(assetEvents: avAssetObserver.loaderEvents, targetAudioFormat: nil).bindNext { e in
			result = e
			assetLoadingCompletion.fulfill()
			}.addDisposableTo(bag)
		
		cacheTask.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(0, 11)).isEqualToData(dataRequest1.respondedData), "Check half of data sended to first dataRequest")
		XCTAssertTrue(sendedData.subdataWithRange(NSMakeRange(11, 11)).isEqualToData(dataRequest2.respondedData), "Check second half of data sended to secondRequest")
		XCTAssertEqual(0, result?.resultRequestCollection.count, "Check remove loading request from collection of pending requests")
		
		XCTAssertTrue(assetRequest1.finished, "Check loading first request if finished")
		XCTAssertTrue(contentRequest1.byteRangeAccessSupported, "Should set first request byteRangeAccessSupported to true")
		XCTAssertEqual(contentRequest1.contentLength, 22, "Check correct content length of first request")
		XCTAssertEqual(contentRequest1.contentType, "public.mp3", "Check correct mime type of first")
	}
}
