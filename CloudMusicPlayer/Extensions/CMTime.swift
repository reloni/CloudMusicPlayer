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
		//let seconds = UInt(CMTimeGetSeconds(self))
		guard let sec: Float64 = self.seconds else { return "0: 00" }
		let minutes = Int(sec / 60)
		return String(format: "%02d: %02d", minutes, Int(sec) - minutes * 60)
	}
	
	public var seconds: Float64? {
		let sec = CMTimeGetSeconds(self)
		return isnan(sec) ? nil : sec
	}
}