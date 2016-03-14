//
//  CloudResourceManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 25.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

public class HttpRequestManager {
	public static let sharedInstance: HttpRequestManagerProtocol = HttpRequestManager()
	
	public static func loadDataForCloudResource(resource: CloudResource, completion: (json: JSON?) -> ()) {
		loadDataForCloudResource(Alamofire.request(.GET, resource.baseUrl, parameters: resource.getRequestParameters(),
			encoding: .URL, headers: resource.getRequestHeaders()), completion: completion)
	}
	
	public static func loadDataForCloudResource(request: Request, completion: (json: JSON?) -> ()) {
		request.responseData { response in
				if let data = response.data {
					completion(json: JSON(data: data))
				} else {
					completion(json: nil)
				}
		}
	}
}

extension HttpRequestManager : HttpRequestManagerProtocol {
	public func loadJsonData(request: NSMutableURLRequestProtocol, session: NSURLSessionProtocol = NSURLSession.sharedSession())
		-> Observable<HttpRequestResult> {
		return Observable.create { observer in
			
			let task = session.dataTaskWithRequest(request) { data, response, error in
				if let error = error {
					observer.onNext(.Error(error))
					observer.onCompleted()
					return
				}
				
				guard let data = data else {
					observer.onNext(.Success)
					observer.onCompleted()
					return
				}
				
				observer.onNext(.SuccessJson(JSON(data: data)))
				observer.onCompleted()
			}
			
			task.resume()
			
			return AnonymousDisposable {
				task.suspend()
			}
		}
	}
	
	public func loadDataForCloudResource(resource: CloudResource, session: NSURLSessionProtocol = NSURLSession.sharedSession()) -> Observable<HttpRequestResult>? {
		guard let url = NSURL(string: resource.baseUrl) else {
			return nil
		}
		
		return loadJsonData(NSMutableURLRequest(URL: url), session: session)
	}
}
