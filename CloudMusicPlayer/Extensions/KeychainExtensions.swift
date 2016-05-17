//
//  KeychainExtensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension Keychain {
	public init() {
		self.init(service: "CloudMusicPlayer")
	}
}