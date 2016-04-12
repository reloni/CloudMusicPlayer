//
//  ContentTypeDefinitionParsingTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 12.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class ContentTypeDefinitionParsingTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testConvertExtensionToUti() {
		XCTAssertEqual(ContentTypeDefinition.getUtiTypeFromFileExtension("mp3"), "public.mp3")
	}
	
	func testConvertExtensionToMime() {
		XCTAssertEqual(ContentTypeDefinition.getMimeTypeFromFileExtension("mp3"), "audio/mpeg")
	}
	
	func testConvertMimeToUti() {
		XCTAssertEqual(ContentTypeDefinition.getUtiFromMime("audio/mpeg"), "public.mp3")
	}
	
	func testConvertMimeToExtension() {
		XCTAssertEqual(ContentTypeDefinition.getFileExtensionFromMime("audio/mpeg"), "mp3")
	}
	
	func testConvertUtiTiMime() {
		XCTAssertEqual(ContentTypeDefinition.getMimeTypeFromUti("public.mp3"), "audio/mpeg")
	}
	
	func testConvertUtiToExtension() {
		XCTAssertEqual(ContentTypeDefinition.getFileExtensionFromUti("public.mp3"), "mp3")
	}
}
