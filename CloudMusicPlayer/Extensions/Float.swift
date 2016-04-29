//
//  Float.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension Float {
	public var asTimeString: String {
		let minutes = Int(self / 60)
		return String(format: "%02d: %02d", minutes, Int(self) - minutes * 60)
	}
}