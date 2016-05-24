//
//  MainModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

class MainModel {
	let player: RxPlayer
	
	init(player: RxPlayer) {
		self.player = player
	}
}