//
//  ObservableValueWithError.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol ResultType { }
extension Result : ResultType { }

public enum Result<T> {
	case success(Box<T>)
	case error(ErrorType)
}

public class Box<T> {
	public let value: T
	
	public init(value: T) {
		self.value = value
	}
}