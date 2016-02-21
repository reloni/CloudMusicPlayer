//
//  CloudResourcesStructureController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	
	var resourceContent: AnyObject?
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(animated: Bool) {
		//let url = "https://cloud-api.yandex.net:443/v1/disk"
		let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=%2F"
		let yaResource = OAuthResourceBase.Yandex
		if let nsUrl = NSURL(string: url), token = yaResource.tokenId {
			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let req = NSMutableURLRequest(URL: nsUrl)
			req.setValue(token, forHTTPHeaderField: "Authorization")
			let task = session.dataTaskWithRequest(req, completionHandler: { (data, response, error) -> Void in
				if let content = data {
					//let result = try NSJSONSerialization.JSONObjectWithData(content, options: .MutableContainers)
					//let a = result["system_folders"]!!["applications"]!
					if let result = try? NSJSONSerialization.JSONObjectWithData(content, options: .MutableContainers) {
						self.resourceContent = result
//						let a = ((result as? Dictionary<String, AnyObject>)!["_embedded"] as? Dictionary<String, AnyObject>)!["items"] as? Dictionary<String, AnyObject>
//						for b in (a?.keys)! {
//							print(b)
//						}
						//self.tableView.reloadData()
						//let a = result["_embedded"]!!["items"] as! [AnyObject]
						//print((a[0] as! Dictionary<String, String>)["name"])
						dispatch_async(dispatch_get_main_queue()) {
							self.tableView.reloadData()
						}
					}
				}
			})
			task.resume()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let data = resourceContent as? Dictionary<String, AnyObject> {
			return data.count
		}
		
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
		//cell.textLabel?.text = "test"
		if let data = resourceContent!["_embedded"]??["items"] as? [AnyObject] {
			if let directory = data[indexPath.row]["name"] as? String {
				cell.textLabel?.text = directory
			}
			
		}
		return cell
		
//		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
//		cell.textLabel?.font = UIFont.systemFontOfSize(12)
//		cell.textLabel?.text = places[indexPath.row].placeDescription
//		return cell
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