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
	
	public func getAnyObjectAtIndex(index: Int) -> AnyObject? {
		guard index != NSNotFound && index >= 0 && index < count else { return nil }
		return self[index]
	}
	
	public func getObjectAtIndex<T>(index: Int) -> T? {
		return getAnyObjectAtIndex(index) as? T
	}
}