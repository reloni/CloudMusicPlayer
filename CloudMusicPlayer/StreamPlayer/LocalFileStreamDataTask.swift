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
	internal let subject = PublishSubject<StreamTaskResult>()
	
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
	public var taskProgress: Observable<StreamTaskResult> {
		return subject.shareReplay(1)
	}
	
	public func resume() {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [weak self] in
			guard let object = self, cacheProvider = object.cacheProvider else { return }
			
			guard let data = NSData(contentsOfFile: object.filePath.path!) else {
				object.subject.onNext(StreamTaskEvents.Success(cache: nil).asResult())
				object.subject.onCompleted()
				return
			}
			
			object.resumed = true
			let response = LocalFileResponse(expectedContentLength: Int64(data.length),
			                                 mimeType: ContentTypeDefinition.getMimeTypeFromFileExtension(object.filePath.pathExtension!))
			
			object.subject.onNext(StreamTaskEvents.ReceiveResponse(response).asResult())
			
			cacheProvider.setContentMimeTypeIfEmpty(response.getMimeType())
			cacheProvider.appendData(data)
			
			object.subject.onNext(StreamTaskEvents.CacheData(cacheProvider).asResult())
			object.subject.onNext(StreamTaskEvents.Success(cache: nil).asResult())
			
			object.resumed = false
			object.subject.onCompleted()
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