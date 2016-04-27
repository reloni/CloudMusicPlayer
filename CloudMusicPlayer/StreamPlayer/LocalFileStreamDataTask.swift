//
//  LocalFileStreamDataTask.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 12.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public class LocalFileStreamDataTask {
	public let uid: String
	public var resumed: Bool = false
	public internal(set) var cacheProvider: CacheProvider?
	public let filePath: NSURL
	internal let subject = PublishSubject<StreamTaskEvents>()
	
	public init?(uid: String, filePath: String, provider: CacheProvider? = nil) {
		if !NSFileManager.fileExistsAtPath(filePath, isDirectory: false) { return nil }
		self.uid = uid
		self.filePath = NSURL(fileURLWithPath: filePath)
		if let provider = provider { self.cacheProvider = provider } else {
			self.cacheProvider = MemoryCacheProvider(uid: uid)
		}
	}
	
	deinit {
		print("LocalFileStreamDataTask deinit")
	}
}

extension LocalFileStreamDataTask : StreamDataTaskProtocol {
	public var taskProgress: Observable<StreamTaskEvents> {
		return subject.shareReplay(1)
	}
	
	public func resume() {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
			guard let data = NSData(contentsOfFile: self.filePath.path!) else {
				self.subject.onNext(StreamTaskEvents.Success(cache: nil))
				self.subject.onCompleted()
				return
			}
			
			self.resumed = true
			let response = LocalFileResponse(expectedContentLength: Int64(data.length),
			                                 mimeType: ContentTypeDefinition.getMimeTypeFromFileExtension(self.filePath.pathExtension!))
			
			self.subject.onNext(StreamTaskEvents.ReceiveResponse(response))
			
			self.cacheProvider?.appendData(data)
			self.cacheProvider?.setContentMimeType(response.getMimeType())
			
			// simulate delay to be sure that player started loading
			for _ in 0...5 {
				self.subject.onNext(StreamTaskEvents.CacheData(self.cacheProvider!))
				NSThread.sleepForTimeInterval(0.01)
			}
			
			self.subject.onNext(StreamTaskEvents.Success(cache: nil))
			
			self.resumed = false
			self.subject.onCompleted()
		}
	}
	
	public func cancel() {
		resumed = false
	}
	
	public func suspend() {
		resumed = false
	}
}

public class LocalFileResponse {
	public var expectedContentLength: Int64
	public var MIMEType: String?
	init(expectedContentLength: Int64, mimeType: String? = nil) {
		self.expectedContentLength = expectedContentLength
		self.MIMEType = mimeType
	}
}

extension LocalFileResponse : NSHTTPURLResponseProtocol { }