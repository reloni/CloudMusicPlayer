//
//  MediaLibraryModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

class MediaLibraryModel {
	let player: RxPlayer
	var newLibraryItems = [StreamResourceIdentifier]()
	
	init(player: RxPlayer) {
		self.player = player
	}
	
	func addToMediaLibrary(resource: CloudResource) {
		
	}
	
	func addNewLibraryItems(items: [StreamResourceIdentifier]) {
		newLibraryItems.appendContentsOf(items)
	}
	
	func loadNewItemsToLibrary() {
		
	}
}