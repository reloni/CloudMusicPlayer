//
//  Main.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 10.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import Foundation

private func delegateClassName() -> String? {
	return NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate) : nil	
}

UIApplicationMain(Process.argc, Process.unsafeArgv, nil, delegateClassName())
