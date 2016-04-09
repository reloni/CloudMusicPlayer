//
//  RxPlayer+RxExtensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension RxPlayer {	
	public func rx_observe() -> Observable<PlayerEvents> {
		return playerEvents
	}
}