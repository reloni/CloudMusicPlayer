//
//  RxPlayer+Dispatch.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift


extension RxPlayer {
	public func startQueueDispatching() -> Observable<Void> {
		return dispatchQueueScheduler
	}
}

extension Observable where Element : PlayerEventType {
	public func dispatchQueue() -> Observable<Void> {
		return self.filter { e in
			if case .DispatchQueue = e as! PlayerEvents { return true } else { return false }
			}.flatMap { e in
				return Observable<Void>.create { observer in
					guard case .DispatchQueue = e as! PlayerEvents else { observer.onCompleted(); return NopDisposable.instance }
					
					print("Dispatching queue")
					
					observer.onCompleted()
					
					return AnonymousDisposable {
						print("disposing queue dispatcher")
						observer.onCompleted()
					}
				}
		
		}
	}
}