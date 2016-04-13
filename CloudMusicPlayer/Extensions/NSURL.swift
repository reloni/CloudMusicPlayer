//
//  NSURL.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSURL {
	public func fileExists() -> Bool {
		if let path = path {
			return NSFileManager.fileExistsAtPath(path, isDirectory: false)
		}
		return false
	}
}