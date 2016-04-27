//
//  DownloadManagerTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 12.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
import RxTests
@testable import CloudMusicPlayer

class DownloadManagerTests: XCTestCase {
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCreateLocalFileStreamTask() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let file = NSFileManager.temporaryDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: nil, attributes: nil)
		let task = manager.createDownloadTaskSync(file.path!, priority: .High)
		XCTAssertTrue(task is LocalFileStreamDataTask, "Should create instance of LocalFileStreamDataTask")
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add task to pending tasks")
		XCTAssertEqual(PendingTaskPriority.High, manager.pendingTasks.first?.1.priority, "Should create pending task with correct priority")
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
	}
	
	func testNotCreateLocalFileStreamTaskForNotExistedFile() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let file = NSFileManager.temporaryDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		let task = manager.createDownloadTaskSync(file.path!, priority: .Normal)
		XCTAssertNil(task, "Should not create a task")
		XCTAssertEqual(0, manager.pendingTasks.count, "Should not add task to pending tasks")
	}
	
	func testCreateUrlStreamTask() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let task = manager.createDownloadTaskSync("https://somelink.com", priority: .Normal)
		XCTAssertTrue(task is StreamDataTask, "Should create instance of StreamDataTask")
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add task to pending tasks")
	}
	
	func testNotCreateStreamTaskForIncorrectScheme() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let task = manager.createDownloadTaskSync("incorrect://somelink.com", priority: .Normal)
		XCTAssertNil(task, "Should not create a task")
		XCTAssertEqual(0, manager.pendingTasks.count, "Should not add task to pending tasks")
	}
	
	func testReturnPendingTask() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let file = NSFileManager.temporaryDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: nil, attributes: nil)
		// create task and add it to pending tasks
		let newTask = LocalFileStreamDataTask(uid: file.path!.streamResourceUid, filePath: file.path!)!
		manager.pendingTasks[newTask.uid] = PendingTask(task: newTask)
		
		// create download task for same file
		let task = manager.createDownloadTaskSync(file.path!, priority: .Normal) as? LocalFileStreamDataTask
		XCTAssertTrue(newTask === task, "Should return same instance of task")
		XCTAssertEqual(1, manager.pendingTasks.count, "Should not add new task to pending tasks")
		file.deleteFile()
	}
	
	func testReturnLocalFileStreamTaskForUrlIfExistedInStorage() {
		let fileStorage = LocalNsUserDefaultsStorage()
		let manager = DownloadManager(saveData: false, fileStorage: fileStorage, httpUtilities: HttpUtilities())
		// create new file in temp storage directory
		let file = fileStorage.tempStorageDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: nil, attributes: nil)
		// save this file in fileStorageCache
		fileStorage.tempStorageDictionary["https://somelink.com"] = file.lastPathComponent!
		// create download task
		let task = manager.createDownloadTaskSync("https://somelink.com", priority: .Normal)
		XCTAssertTrue(task is LocalFileStreamDataTask, "Should create instance of LocalFileStreamDataTask, because file exists in cache")
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add task to pending tasks")
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
	}
	
	func testThreadSafetyForCreationNewTask() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		
		for _ in 0...10 {
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
				manager.createDownloadTaskSync("https://somelink.com", priority: .Normal)
			}
		}
		
		NSThread.sleepForTimeInterval(0.05)
		XCTAssertEqual(1, manager.pendingTasks.count, "Check only one task created")
	}
	
	func testDownloadObservableForIncorrectUrl() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
	
		let errorExpectation = expectationWithDescription("Should send error message")
		manager.createDownloadObservable("wrong://test.com", priority: .Normal).doOnError { error in
			let error = error as NSError
			XCTAssertEqual(error.code, DownloadManagerError.UnsupportedUrlSchemeOrFileNotExists.rawValue, "Check returned error with correct errorCode")
			XCTAssertEqual(error.userInfo["Url"] as? String, "wrong://test.com", "Check returned correct url in error info")
			XCTAssertEqual(error.userInfo["Uid"] as? String, "wrong://test.com", "Check returned correct uid in error info")
				
			errorExpectation.fulfill()
		}.subscribe().addDisposableTo(bag)
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testDownloadObservableForNotExistedFile() {
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		
		let errorExpectation = expectationWithDescription("Should send error message")
		manager.createDownloadObservable("/Path/To/Not/existed.file", priority: .Normal).doOnError { error in
			let error = error as NSError
			XCTAssertEqual(error.code, DownloadManagerError.UnsupportedUrlSchemeOrFileNotExists.rawValue, "Check returned error with correct errorCode")
			XCTAssertEqual(error.userInfo["Url"] as? String, "/Path/To/Not/existed.file", "Check returned correct url in error info")
			XCTAssertEqual(error.userInfo["Uid"] as? String, "/Path/To/Not/existed.file", "Check returned correct uid in error info")
				
			errorExpectation.fulfill()
			
			}.subscribe().addDisposableTo(bag)
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testCorrectCreateAndDisposeDownloadObservable() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		
		let downloadTaskCancelationExpectation = expectationWithDescription("Should cancel underlying task")
		// simulate http request
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					let response = FakeResponse(contentLenght: 0)
					response.MIMEType = "audio/mpeg"
					streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: session, dataTask: tsk,
						response: response, completion: { _ in }))
					
					let data = NSData()
					streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: session, dataTask: tsk, data: data))
					streamObserver.sessionEventsSubject.onNext(SessionDataEvents.didCompleteWithError(session: session, dataTask: tsk, error: nil))
				}
			} else if case FakeDataTaskMethods.cancel = e {
				downloadTaskCancelationExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities)
		
		let successExpectation = expectationWithDescription("Should receive success message")
		manager.createDownloadObservable("https://test.com", priority: .Normal).bindNext { e in
			if case StreamTaskEvents.Success = e {
				
				successExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add task to pending")
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, manager.pendingTasks.count, "Should remove task from pending")
	}
	
	func testCorrectCreateAndDisposeDownloadObservableWhenReceiveError() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		
		let downloadTaskCancelationExpectation = expectationWithDescription("Should cancel underlying task")
		// simulate http request
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					let response = FakeResponse(contentLenght: 0)
					response.MIMEType = "audio/mpeg"
					streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: session, dataTask: tsk,
						response: response, completion: { _ in }))
					
					let data = NSData()
					streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: session, dataTask: tsk, data: data))
					let error = NSError(domain: "DownloadManagerTests", code: 15, userInfo: nil)
					streamObserver.sessionEventsSubject.onNext(SessionDataEvents.didCompleteWithError(session: session, dataTask: tsk, error: error))
				}
			} else if case FakeDataTaskMethods.cancel = e {
				downloadTaskCancelationExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities)
		
		let errorExpectation = expectationWithDescription("Should receive error message")
		manager.createDownloadObservable("https://test.com", priority: .Normal).doOnError { error in
			let error = error as NSError
			XCTAssertEqual(15, error.code, "Check receive error with correct code")
			errorExpectation.fulfill()
			}.subscribe().addDisposableTo(bag)
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add task to pending")
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, manager.pendingTasks.count, "Should remove task from pending")
	}
	
	func testSaveData() {
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		let saveData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		provider.appendData(saveData)
		let manager = DownloadManager(saveData: true, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let file = manager.saveData(provider)
		if let file = file, restoredData = NSData(contentsOfURL: file) {
			XCTAssertTrue(restoredData.isEqualToData(saveData), "Check saved data equal to cached data")
		} else {
			XCTFail("Failed to restore saved data")
		}
		file?.deleteFile()
	}
	
	func testNotSaveData() {
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		let saveData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		provider.appendData(saveData)
		// create manager and set saveData to false
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilities())
		let file = manager.saveData(provider)
		XCTAssertNil(file, "Should not return saved file")
	}
	
	func testCacheCorrectDataIfHasMoreThanOneObservers() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		
		let sendData = ["first", "second", "third", "fourth"]
		let sendedData = NSMutableData()
		let downloadTaskCancelationExpectation = expectationWithDescription("Should cancel underlying task")
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					let response = FakeResponse(contentLenght: 0)
					response.MIMEType = "audio/mpeg"
					streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: session, dataTask: tsk,
						response: response, completion: { _ in }))
					
					for i in 0...sendData.count - 1 {
						let dataToSend = sendData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(dataToSend)
						streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: session, dataTask: tsk, data: dataToSend))
						NSThread.sleepForTimeInterval(0.05)
					}
					streamObserver.sessionEventsSubject.onNext(SessionDataEvents.didCompleteWithError(session: session, dataTask: tsk, error: nil))
				}
			} else if case FakeDataTaskMethods.cancel = e {
				downloadTaskCancelationExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities)
		
		// first subscription
		let successExpectation = expectationWithDescription("Should receive success message")
		manager.createDownloadObservable("https://test.com", priority: .Normal).bindNext { e in
			if case StreamTaskEvents.Success(let cacheProvider) = e {
				XCTAssert(sendedData.isEqualToData(cacheProvider?.getData() ?? NSData()))
				successExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		// second subscription
		let successSecondObservableExpectation = expectationWithDescription("Should receive success message")
		manager.createDownloadObservable("https://test.com", priority: .Normal).bindNext { e in
			if case StreamTaskEvents.Success(let cacheProvider) = e {
				XCTAssert(sendedData.isEqualToData(cacheProvider?.getData() ?? NSData()))
				successSecondObservableExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		XCTAssertEqual(1, manager.pendingTasks.count, "Should add only one task to pending")
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, manager.pendingTasks.count, "Should remove task from pending")
		XCTAssertEqual(1, session.task?.resumeInvokeCount, "Should invoke resume on DataTask only once")
	}
	
	func testCancelTaskWhenObservableDisposing() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session

		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities)
		
		let observable = manager.createDownloadObservable("http://test.com", priority: .Normal).subscribe()
		XCTAssertEqual(1, manager.pendingTasks.count, "Check add task to pending")
		observable.dispose()
		XCTAssertEqual(0, manager.pendingTasks.count, "Check remove task from pending")
		XCTAssertEqual(true, session.task?.isCancelled, "Check underlying task canceled")
	}
	
	func testCancelTaskOnlyAfterLastObservableDisposed() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities)
		
		let firstObservable = manager.createDownloadObservable("http://test.com", priority: .Normal).subscribe()
		let secondObservable = manager.createDownloadObservable("http://test.com", priority: .Normal).subscribe()
		let thirdObservable = manager.createDownloadObservable("http://test.com", priority: .Normal).subscribe()
		XCTAssertEqual(1, manager.pendingTasks.count, "Check add task to pending")
		
		firstObservable.dispose()
		XCTAssertEqual(1, manager.pendingTasks.count, "Check still has task in pending")
		XCTAssertEqual(false, session.task?.isCancelled, "Check underlying task not canceled")
		
		secondObservable.dispose()
		XCTAssertEqual(1, manager.pendingTasks.count, "Check still has task in pending")
		XCTAssertEqual(false, session.task?.isCancelled, "Check underlying task not canceled")
		
		thirdObservable.dispose()
		XCTAssertEqual(0, manager.pendingTasks.count, "Check remove task from pending")
		XCTAssertEqual(true, session.task?.isCancelled, "Check underlying task canceled")
	}
	
	func testNotStartNewTaskWhenHaveAnotherPendingTask() {
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		
		let manager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: httpUtilities, simultaneousTasksCount: 1,
		                              runningTaskCheckTimeout: 1)
		
		// create task, start it and add to pending tasks
		let runningTask = httpUtilities.createStreamDataTask("http://test.com", request: httpUtilities.createUrlRequest(
			NSURL(baseUrl: "http://test.com", parameters: nil)!, headers: nil), sessionConfiguration: NSURLSession.defaultConfig, cacheProvider: nil)
		runningTask.resume()
		manager.pendingTasks[runningTask.uid] = PendingTask(task: runningTask)
		
		// create another task and add to pendings too
		let newTask = httpUtilities.createStreamDataTask("http://test.com", request: httpUtilities.createUrlRequest(
			NSURL(baseUrl: "http://test2.com", parameters: nil)!, headers: nil), sessionConfiguration: NSURLSession.defaultConfig, cacheProvider: nil)
		manager.pendingTasks[newTask.uid] = PendingTask(task: newTask)
		
		// create PublishSubject, that will simutale task check interval
		let interval = PublishSubject<Int>()
		// start monitoring of second task
		manager.monitorTask(newTask.uid, monitoringInterval: interval).subscribe().addDisposableTo(bag)
		
		XCTAssertEqual(false, newTask.resumed, "Check new task not started")
		interval.onNext(1)
		XCTAssertEqual(false, newTask.resumed, "Check new task not started after monitoring tick")
		
		// cancel current task
		runningTask.cancel()
		interval.onNext(1)
		XCTAssertEqual(true, newTask.resumed, "Check new task started after completion of previous task")
	}
}
