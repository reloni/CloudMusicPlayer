//
//  JSON.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol SJSON {
	subscript(key key: String) -> SJSON? { get }
	subscript(index index: Int) -> SJSON? { get }
	func forKey(key: String) -> SJSON?
	func forIndex(index: Int) -> SJSON?
}

extension NSNull : SJSON {
	public subscript(key key: String) -> SJSON? { return nil }
	public subscript(index index: Int) -> SJSON? { return nil }
	public func forKey(key: String) -> SJSON? {
		return nil
	}
	public func forIndex(index: Int) -> SJSON? {
		return nil
	}
}

extension NSNumber : SJSON {
	public subscript(key key: String) -> SJSON? { return nil }
	public subscript(index index: Int) -> SJSON? { return nil }
	public func forKey(key: String) -> SJSON? {
		return nil
	}
	public func forIndex(index: Int) -> SJSON? {
		return nil
	}
}

extension NSString : SJSON {
	public subscript(key key: String) -> SJSON? { return nil }
	public subscript(index index: Int) -> SJSON? { return nil }
	public func forKey(key: String) -> SJSON? {
		return nil
	}
	public func forIndex(index: Int) -> SJSON? {
		return nil
	}
}

extension NSArray : SJSON {
	public subscript(key key: String) -> SJSON? { return nil }
	public subscript(index index: Int) -> SJSON? { return index < count && index >= 0 ? convertToSJSON(self[index]) : nil }
	public func forKey(key: String) -> SJSON? {
		return nil
	}
	public func forIndex(index: Int) -> SJSON? {
		return self[index: index]
	}
}

extension NSDictionary : SJSON {
	public subscript(key key: String) -> SJSON? { return convertToSJSON(self[key]) }
	public subscript(index index: Int) -> SJSON? { return nil }
	public func forKey(key: String) -> SJSON? {
		return self[key: key]
	}
	public func forIndex(index: Int) -> SJSON? {
		return nil
	}
}

extension NSData {
	public func asSJSON() -> SJSON? {
		return convertToSJSON(self)
	}
}

extension SJSON {
	public func rawData(options: NSJSONWritingOptions = NSJSONWritingOptions(rawValue: 0)) -> NSData? {
		guard let object = self as? AnyObject where NSJSONSerialization.isValidJSONObject(object) else {
			return nil
		}
		
		return try? NSJSONSerialization.dataWithJSONObject(object, options: options)
	}
	
	public var asString: String? {
		return self as? String
	}
	
	public var asInt: Int? {
		return self as? Int
	}
}

public func convertToSJSON(object: AnyObject?) -> SJSON? {
	if let some: AnyObject = object {
		switch some {
		case let null as NSNull:        return null
		case let number as NSNumber:    return number
		case let string as NSString:    return string
		case let array as NSArray:      return array
		case let dict as NSDictionary:  return dict
		default:                        return nil
		}
	} else {
		return nil
	}
}

public func convertToSJSON(data: NSData) -> SJSON? {
	let jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
	if let jsonData = jsonData {
		return convertToSJSON(jsonData)
	}
	return nil
}