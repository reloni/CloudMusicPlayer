//
//  CustomErrorType.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol CustomErrorType : ErrorType {
	func userInfo() -> Dictionary<String,String>
	func errorDomain() -> String
	func errorCode() -> Int
	func errorDescription() -> String
	func error() -> NSError
}

extension CustomErrorType {
	public func error() -> NSError {
		return NSError(domain: self.errorDomain(), code: self.errorCode(), userInfo: self.userInfo())
	}
	
	public func userInfo() -> Dictionary<String, String> {
		return [NSLocalizedDescriptionKey: errorDescription()]
	}
	
	public func asResult<T>() -> Result<T> {
		return Result<T>.error(self)
	}
}
