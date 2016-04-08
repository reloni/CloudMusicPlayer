//
//  RxPlayerTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class RxPlayerTests: XCTestCase {
	
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testShit() {
		let player = RxPlayer()
		player.rx_observe().dispatch().bindNext { e in
			print("Dispatch: \(e)")
		}.addDisposableTo(bag)
		player.rx_observe().bindNext { e in
			print("Observe: \(e)")
		}.addDisposableTo(bag)
		
		
		player.addFirst("ololo")
		GlobalPlayerHolder.instance.subject.onNext(.Started)
		
		//player.playUrl("http://some.com", clearQueue: true, contentTypeOverride: .mp3)
		
		NSThread.sleepForTimeInterval(1)
	}
	
}
