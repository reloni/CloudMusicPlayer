//
//  GoogleDriveCloudAudioJsonResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 02.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

public class GoogleDriveCloudAudioJsonResource : GoogleDriveCloudJsonResource, CloudAudioResource {
	internal var downloadResourceUrl: NSURL? {
		return NSURL(baseUrl: "\(resourcesUrl)/\(uid)", parameters: ["alt": "media"])
	}
	
	public var downloadUrl: Observable<String> {
		guard let url = downloadResourceUrl else {
			return Observable.empty()
		}
		
		return Observable.create { observer in
			observer.onNext(url.absoluteString)
			observer.onCompleted()
			return NopDisposable.instance
		}
	}
}
