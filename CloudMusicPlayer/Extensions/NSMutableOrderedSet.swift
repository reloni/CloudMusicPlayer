//
//  NSMutableOrderedSet.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSMutableOrderedSet {
	public func getIndexOfObject(object: AnyObject) -> Int? {
		let index = indexOfObject(object)
		return index != NSNotFound ? index : nil
	}
}