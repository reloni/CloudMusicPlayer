//
//  ConcurrentDispatchQueueScheduler.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension ConcurrentDispatchQueueScheduler {
	static var utility: ConcurrentDispatchQueueScheduler {
		return ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	}
}