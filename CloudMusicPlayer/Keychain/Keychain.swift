//
//  Keychain.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 26.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

// Original code on: http://www.splinter.com.au/2015/06/21/swift-keychain-wrapper/

import Security
import Foundation

enum KeychainError: ErrorType {
	case Unimplemented
	case Param
	case Allocate
	case NotAvailable
	case AuthFailed
	case DuplicateItem
	case ItemNotFound
	case InteractionNotAllowed
	case Decode
	case Unknown
	
	/// Returns the appropriate error for the status, or nil if it
	/// was successful, or Unknown for a code that doesn't match.
	static func errorFromOSStatus(rawStatus: OSStatus) ->
		KeychainError? {
			if rawStatus == errSecSuccess {
				return nil
			} else {
				// If the mapping doesn't find a match, return unknown.
				return mapping[rawStatus] ?? .Unknown
			}
	}
	
	static let mapping: [Int32: KeychainError] = [
		errSecUnimplemented: .Unimplemented,
		errSecParam: .Param,
		errSecAllocate: .Allocate,
		errSecNotAvailable: .NotAvailable,
		errSecAuthFailed: .AuthFailed,
		errSecDuplicateItem: .DuplicateItem,
		errSecItemNotFound: .ItemNotFound,
		errSecInteractionNotAllowed: .InteractionNotAllowed,
		errSecDecode: .Decode
	]
}

struct SecItemWrapper {
	static func matching(query: [String: AnyObject]) throws -> AnyObject? {
		var rawResult: AnyObject?
		let rawStatus = SecItemCopyMatching(query, &rawResult)
		// Immediately take the retained value, so it won't leak
		// in case it needs to throw.
		
		if let error = KeychainError.errorFromOSStatus(rawStatus) {
			throw error
		}

		return rawResult
	}
	
	static func add(attributes: [String: AnyObject]) throws -> AnyObject? {
		var rawResult: AnyObject?
		let rawStatus = SecItemAdd(attributes, &rawResult)
		
		if let error = KeychainError.errorFromOSStatus(rawStatus) {
			throw error
		}

		return rawResult
	}
	
	static func update(query: [String: AnyObject],
		attributesToUpdate: [String: AnyObject]) throws {
			let rawStatus = SecItemUpdate(query, attributesToUpdate)
			if let error = KeychainError.errorFromOSStatus(rawStatus) {
				throw error
			}
	}
	static func delete(query: [String: AnyObject]) throws {
		let rawStatus = SecItemDelete(query)
		if let error = KeychainError.errorFromOSStatus(rawStatus) {
			throw error
		}
	}
}

struct Keychain {
	static func deleteAccount(account: String) {
		do {
			try SecItemWrapper.delete([
				kSecClass as String: kSecClassGenericPassword,
				kSecAttrService as String: Constants.service,
				kSecAttrAccount as String: account,
				kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
				])
		} catch KeychainError.ItemNotFound {
			// Ignore this error.
		} catch let error {
			NSLog("deleteAccount error: \(error)")
		}
	}
	
	static func dataForAccount(account: String) -> NSData? {
		do {
			let query = [
				kSecClass as String: kSecClassGenericPassword,
				kSecAttrService as String: Constants.service,
				kSecAttrAccount as String: account,
				kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
				kSecReturnData as String: kCFBooleanTrue as CFTypeRef,
			]
			let result = try SecItemWrapper.matching(query)
			return result as? NSData
		} catch KeychainError.ItemNotFound {
			// Ignore this error, simply return nil.
			return nil
		} catch let error {
			NSLog("dataForAccount error: \(error)")
			return nil
		}
	}
	
	static func stringForAccount(account: String) -> String? {
		if let data = dataForAccount(account) {
			return NSString(data: data,
				encoding: NSUTF8StringEncoding) as? String
		} else {
			return nil
		}
	}
	
	static func setData(data: NSData,
		forAccount account: String,
		synchronizable: Bool,
		background: Bool) {
			do {
				// Remove the item if it already exists.
				// This saves having to deal with SecItemUpdate.
				// Reasonable people may disagree with this approach.
				deleteAccount(account)
				
				// Add it.
				try SecItemWrapper.add([
					kSecClass as String: kSecClassGenericPassword,
					kSecAttrService as String: Constants.service,
					kSecAttrAccount as String: account,
					kSecAttrSynchronizable as String: synchronizable ?
						kCFBooleanTrue : kCFBooleanFalse,
					kSecValueData as String: data,
					kSecAttrAccessible as String: background ?
						kSecAttrAccessibleAfterFirstUnlock :
					kSecAttrAccessibleWhenUnlocked,
					])
			} catch let error {
				NSLog("setData error: \(error)")
			}
	}
	
	static func setString(string: String?,
		forAccount account: String,
		synchronizable: Bool,
		background: Bool) {
			if let string = string {
				let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
				setData(data,
					forAccount: account,
					synchronizable: synchronizable,
					background: background)
			} else {
				deleteAccount(account)
			}
	}
	
	struct Constants {
		// FIXME: Change this to the name of your app or company!
		static let service = "CloudMusicPlayer"
	}
}