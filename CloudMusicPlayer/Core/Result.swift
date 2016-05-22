//
//  ObservableValueWithError.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public enum Result<T> {
	case success(Box<T>)
	case error(CustomErrorType)
}

public class Box<T> {
	let value: T
	
	init(value: T) {
		self.value = value
	}
}