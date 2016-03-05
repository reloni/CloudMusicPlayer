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
import RxCocoa
import RxSwift
import AVFoundation

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let viewModel = CloudResourcesViewModel()
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		navigationItem.title = viewModel.parent?.name ?? "/"
		if let parent = viewModel.parent {
			parent.loadChilds { res in
				self.viewModel.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		} else if navigationController?.viewControllers.first == self {
			YandexDiskCloudJsonResource.loadRootResources(OAuthResourceBase.Yandex) { res in
				self.viewModel.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func play(track: CloudAudioResource) {
		track.getDownloadUrl { url in
			guard let url = url else {
				return
			}

			streamPlayer.play(url, customHttpHeaders: track.getRequestHeaders())
		}
	}
	
	func stop() {
		streamPlayer.stop()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController,
		 resource = viewModel.resources?[indexPath.row] where viewModel.resources?[indexPath.row].type == "dir"	else {
			return
		}

		controller.viewModel.parent = resource
		navigationController?.pushViewController(controller, animated: true)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let resource = viewModel.resources![indexPath.row]
		
		if let resource = resource as? CloudAudioResource {
			let cell = tableView.dequeueReusableCellWithIdentifier("CloudTrackCell", forIndexPath: indexPath) as! CloudTrackCell
			cell.track = resource
			cell.playButton.rx_tap.bindNext { [unowned self] in
				guard let track = cell.track else {
					return
				}
				self.play(track)
				}.addDisposableTo(viewModel.bag)
			cell.stopButton.rx_tap.bindNext { [unowned self] in
				self.stop()
			}.addDisposableTo(viewModel.bag)
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("CloudFolderCell", forIndexPath: indexPath) as! CloudFolderCell
		cell.folderNameLabel.text = viewModel.resources?[indexPath.row].name ?? "unresolved"
		return cell
	}
}