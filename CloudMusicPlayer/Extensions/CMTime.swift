//
//  CMTime.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTime {
	public var asString: String {
		let seconds = UInt(CMTimeGetSeconds(self))
		let minutes = UInt(seconds / 60)
		return String(format: "%02d: %02d", minutes, seconds - minutes * 60)
	}
	
	public var seconds: Float64 {
		return CMTimeGetSeconds(self)
	}
}