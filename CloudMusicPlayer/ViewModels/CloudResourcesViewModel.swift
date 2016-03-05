//
//  CloudResourcesModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

class CloudResourcesViewModel {
	var resources: [CloudResource]?
	var parent: CloudResource?
	let bag = DisposeBag()
}