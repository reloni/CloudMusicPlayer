//
//  GCD.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 10.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public enum QueueQOS {
	case MainQueue
	case Utility
}

public struct DispatchQueue {
	public static func async(qos: QueueQOS, block: () -> ()) {
		var queue: dispatch_queue_t!
		switch qos {
		case .MainQueue: queue = dispatch_get_main_queue()
		case .Utility: queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
		}
		
		dispatch_async(queue, block)
	}
}