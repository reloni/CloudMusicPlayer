//
//  CloudResourceModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

class CloudResourceModel {
	let resource: CloudResource
	let cloudResourceClient: CloudResourceClientType
	
	init(resource: CloudResource, cloudResourceClient: CloudResourceClientType) {
		self.resource = resource
		self.cloudResourceClient = cloudResourceClient
	}
	
	var displayName: String {
		return resource.name
	}
	
	var content: Observable<[CloudResource]> {
		return cloudResourceClient.loadChildResources(resource, loadMode: CloudResourceLoadMode.CacheAndRemote)
	}
}