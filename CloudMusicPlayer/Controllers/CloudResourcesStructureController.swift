//
//  CloudResourcesStructureController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	
	var resourceContent: JSON?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		automaticallyAdjustsScrollViewInsets = false
	}

	override func viewDidAppear(animated: Bool) {
		//let url = "https://cloud-api.yandex.net:443/v1/disk"
//		let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=%2F"
		let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=/"
		guard let token = OAuthResourceBase.Yandex.tokenId else {
            resourceContent = nil
            self.tableView.reloadData()
			return
		}
		let headers = [
			"Authorization": token
		]
		
		Alamofire.request(.GET, url, headers: headers).responseData { response in
			guard let data = response.data else {
				return
			}
			self.resourceContent = JSON(data: data)
			dispatch_async(dispatch_get_main_queue()) {
				self.tableView.reloadData()
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resourceContent?["_embedded"]["items"].count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		//let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        let cell = tableView.dequeueReusableCellWithIdentifier("SimpleCell", forIndexPath: indexPath)
		cell.textLabel?.text = resourceContent?["_embedded"]["items"][indexPath.row]["name"].string ?? "unresolved"
		return cell
	}
	
//	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
//		forRowAtIndexPath indexPath: NSIndexPath) {
//			if(editingStyle == UITableViewCellEditingStyle.Delete) {
//				places.removeAtIndex(indexPath.row)
//				self.placesTable.reloadData()
//			}
//	}
	
//	func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
//		selectedPlace = places[indexPath.row]
//		return indexPath
//	}
}