//
//  SwiftyJson.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
	public func safeRawData() -> NSData? {
		return try? rawData()
	}
}