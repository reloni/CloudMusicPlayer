//
//  GoogleOAuthResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

public class GoogleOAuthResource : OAuthResourceBase {
	public static let id = "com.antonefimenko.cloudmusicplayer"
	public static let tokenUrl = "https://www.googleapis.com/oauth2/v4/token"
	internal init() {
		super.init(id: GoogleOAuthResource.id, authUrl: "https://accounts.google.com/o/oauth2/v2/auth?response_type=code",
		           clientId: "904693090582-807d6m390ms26lis6opjfbrjnr0qns7k.apps.googleusercontent.com", tokenId: nil)
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public func getAuthUrl() -> NSURL? {
		if let clientId = clientId {
			return NSURL(string: "\(authBaseUrl)&client_id=\(clientId)&redirect_uri=\(id):/cmp.ru&scope=https://www.googleapis.com/auth/drive.readonly")
		}
		return nil
	}
	
	public func parseCallbackUrl(url: String) -> String? {
		if let start = url.rangeOfString("code=")?.endIndex {
			let substring = url.substringFromIndex(start)
			let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
			let code = substring.substringWithRange(substring.startIndex..<end)
			
			// perform second request in order to finally receive access token
			let request = HttpUtilities().createUrlRequest(NSURL(baseUrl: GoogleOAuthResource.tokenUrl, parameters: ["code": code,
				"client_id": clientId!, "redirect_uri": "\(id):/cmp.ru", "grant_type": "authorization_code"])!)
			request.setHttpMethod("POST")
			do {
				let client = HttpClient()
				let array = try client.loadJsonData(request).toBlocking().toArray()
				if let result = array.first {
					return result["access_token"].string
				}
			} catch {
				return nil
			}
		}
		return nil
	}
	
	override public func refreshToken(httpClient: HttpClientProtocol) -> Observable<JSON> {
		guard let clientId = clientId, refreshTokenId = refreshTokenId,
			url = NSURL(baseUrl: GoogleOAuthResource.tokenUrl,
			            parameters: ["client_id": clientId, "refresh_token": refreshTokenId, "grant_type": "refresh_token"]) else { return Observable.empty() }
		let request = httpClient.httpUtilities.createUrlRequest(url, headers: nil)
		request.setHttpMethod("POST")
		return httpClient.loadJsonData(request).doOnNext { json in
			if let token = json["access_token"].string {
				self.tokenId = token
			}
		}
	}
}

extension OAuthResourceManager {
	public static func getGoogleResource(userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults(),
	                                     manager: OAuthResourceManager = OAuthResourceManager()) -> OAuthResource {
		return manager.loadResource(GoogleOAuthResource.id, userDefaults: userDefaults) ?? {
			let newResource = GoogleOAuthResource()
			manager.addResource(newResource)
			newResource.saveResource(userDefaults)
			return newResource
			}()
	}
}