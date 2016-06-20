//
//  CacheState.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit

extension CacheState {
	func getImage() -> UIImage {
		switch self {
		case .notExisted: return MainModel.sharedInstance.itemInCloudImage
		case .inPermanentStorage: return MainModel.sharedInstance.itemInPermanentStorageImage
		case .inTempStorage: return MainModel.sharedInstance.itemInTempStorageImage
		}
	}
}