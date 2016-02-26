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
	var parent: JSON?
	//var path: String? = "/"
	var resources: [CloudResource]? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		automaticallyAdjustsScrollViewInsets = false
	}
	
	override func viewDidAppear(animated: Bool) {
				//let url = "https://cloud-api.yandex.net:443/v1/disk"
				//		let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=%2F"
				//let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=/"
				let url = "https://cloud-api.yandex.net:443/v1/disk/resources"
				//let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Documents"
				guard let token = OAuthResourceBase.Yandex.tokenId else {
					resourceContent = nil
					self.tableView.reloadData()
					return
				}
				title = parent == nil ? "Root" : parent?["name"].string
				let headers = ["Authorization": token]
				let parameters: [String: AnyObject] = ["path": parent?["path"].string ?? "/"]
				Alamofire.request(.GET, url, parameters: parameters, encoding: .URL, headers: headers).responseData { response in
					//Alamofire.request(.GET, url, headers: headers).responseData { response in
					guard let data = response.data else {
						return
					}
					self.resourceContent = JSON(data: data)
					if let obj = self.resourceContent?["test1"]["test2"] {
						print(obj)
					}
					
					dispatch_async(dispatch_get_main_queue()) {
						self.tableView.reloadData()
					}
				}
		
		
//		YandexCloudJsonResource.loadRootResources(OAuthResourceBase.Yandex) { res in
//			self.resources = res
//			dispatch_async(dispatch_get_main_queue()) {
//				self.tableView.reloadData()
//			}
//		}
		//YandexCloudJsonResource.test(YandexOAuthResource.Yandex) { data in
		//	print(YandexOAuthResource.Yandex)
		//}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		//guard let controller = storyboard?.instantiateViewControllerWithIdentifier("DetailsView") as? DetailsController else {
//		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController
//			where resourceContent?["_embedded"]["items"][indexPath.row]["type"].string == "dir" else {
//				return
//		}
		//controller.path = resourceContent?["_embedded"]["items"][indexPath.row]["path"].string
		//controller.parent = resourceContent?["_embedded"]["items"][indexPath.row]
		//navigationController?.pushViewController(controller, animated: true)	}
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		//return resourceContent?["_embedded"]["items"].count ?? 0
		return resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		//let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
		let cell = tableView.dequeueReusableCellWithIdentifier("SimpleCell", forIndexPath: indexPath)
		//cell.textLabel?.text = resourceContent?["_embedded"]["items"][indexPath.row]["name"].string ?? "unresolved"
		cell.textLabel?.text = resources?[indexPath.row].name ?? "unresolved"
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