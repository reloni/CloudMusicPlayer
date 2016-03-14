//
//  NSURL.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSURL {
	public convenience init?(baseUrl: String, parameters: [String: String]?) {
		if let parameters = parameters, components = NSURLComponents(string: baseUrl) {
			components.queryItems = parameters.map { NSURLQueryItem(name: $0, value: $1) }
			self.init(string: components.URLString)
		} else {
			self.init(string: baseUrl)
		}
	}
}