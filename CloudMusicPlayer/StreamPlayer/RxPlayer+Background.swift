//
//  RxPlayer+Background.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit

extension RxPlayer {
	public func setUIApplication(uiApplication: UIApplicationType) {
		self.uiApplication = uiApplication
	}
	
	public func beginBackgroundTask() {
		guard let uiApplication = uiApplication else { return }
		beginBackgroundTask(uiApplication)
	}
	
	internal func beginBackgroundTask(application: UIApplicationType) {
		print("bagin background task")
		let currentIdentifier = backgroundTaskIdentifier
		
		backgroundTaskIdentifier = application.beginBackgroundTaskWithExpirationHandler { [weak self] in
			print("end background task callback invoked")
			if let backgroundTaskIdentifier = self?.backgroundTaskIdentifier {
				application.endBackgroundTask(backgroundTaskIdentifier)
			}
			self?.backgroundTaskIdentifier = nil
		}
		
		if let currentIdentifier = currentIdentifier {
			application.endBackgroundTask(currentIdentifier)
		}
	}
	
	public func endBackgroundTask() {
		guard let uiApplication = uiApplication else { return }
		endBackgroundTask(uiApplication)
	}
	
	internal func endBackgroundTask(application: UIApplicationType) {
		print("end background task")
		if let backgroundTaskIdentifier = backgroundTaskIdentifier {
			if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
				application.endBackgroundTask(backgroundTaskIdentifier)
			}
			self.backgroundTaskIdentifier = nil
		}
	}
}