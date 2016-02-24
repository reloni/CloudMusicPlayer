//
//  DetailsController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class DetailsController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	var resourceContent: JSON?
	var directory: String?
	override func viewDidLoad() {
		
	}
	
	override func viewDidAppear(animated: Bool) {
		guard let directory = directory else {
			return
		}
		let url = "https://cloud-api.yandex.net:443/v1/disk/resources?path=" + directory
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
}

extension DetailsController : UITableViewDelegate {
	
	func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
		//		UIViewController *myController = [self.storyboard instantiateViewControllerWithIdentifier:@"MyGenericTableViewController"];
		//		[self.navigationController pushViewController: myController animated:YES];
//		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("DetailsView") as? DetailsController else {
//			return
//		}
//		navigationController?.pushViewController(controller, animated: true)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resourceContent?["_embedded"]["items"].count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		//let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
		let cell = tableView.dequeueReusableCellWithIdentifier("SimpleCell", forIndexPath: indexPath)
		cell.textLabel?.text = resourceContent?["_embedded"]["items"][indexPath.row]["name"].string ?? "unresolved"
		return cell
	}
}
