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
import AVFoundation
import RxSwift

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var playTestButton: UIBarButtonItem!
	
	var resources: [CloudResource]?
	var parent: CloudResource?
	
	var player: AVPlayer?
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		
		playTestButton.rx_tap.bindNext {
			if let url = NSURL(string: "https://freemusicarchive.org/music/download/5320ffff3f02dcdfaa77ead96d3833b68e3c0ef3") {
				self.player = AVPlayer(URL: url)
				self.player?.play()
			}
		}.addDisposableTo(bag)
		
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		title = parent?.name ?? "Root"
		if let parent = parent {
			parent.loadChilds { res in
				self.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		} else if navigationController?.viewControllers.first == self {
			YandexCloudJsonResource.loadRootResources(OAuthResourceBase.Yandex) { res in
				self.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController,
		 resource = resources?[indexPath.row] where resources?[indexPath.row].type == "dir"	else {
			return
		}

		controller.parent = resource
		navigationController?.pushViewController(controller, animated: true)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("SimpleCell", forIndexPath: indexPath)
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