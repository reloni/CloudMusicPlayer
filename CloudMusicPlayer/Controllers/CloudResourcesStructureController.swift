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
	
	var resources: [CloudResource]?
	var parent: CloudResource?
	
	private let bag = DisposeBag()
	
	var player = StreamAudioPlayer()
	var avPlayer = AVPlayer()
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		
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
			YandexDiskCloudJsonResource.loadRootResources(OAuthResourceBase.Yandex) { res in
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
	
	func play(track: CloudAudioResource) {
		track.getDownloadUrl { url in
			guard let url = url else {
				return
			}
			self.player.customHttpHeaders = track.getRequestHeaders()
			//self.player.play("http://freemusicarchive.org/music/download/d93cc6c7058b32441eaef7ea0715be244ba9b293")
			self.player.play(url)
			//self.player.play("https://drive.google.com/file/d/0ByhKrpwk2445ZFdWcEwyLUNVSFE/view?usp=sharing")
		}
	}
	
	func stop() {
		player.stop()
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
		let resource = resources![indexPath.row]
		
		if let resource = resource as? CloudAudioResource {
			let cell = tableView.dequeueReusableCellWithIdentifier("CloudTrackCell", forIndexPath: indexPath) as! CloudTrackCell
			cell.track = resource
			cell.playButton.rx_tap.observeOn(MainScheduler.instance).bindNext { [unowned self] in
				guard let track = cell.track else {
					return
				}
				self.play(track)
				}.addDisposableTo(bag)
			cell.stopButton.rx_tap.observeOn(MainScheduler.instance).bindNext { [unowned self] in
				self.stop()
			}.addDisposableTo(bag)
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("CloudFolderCell", forIndexPath: indexPath) as! CloudFolderCell
		cell.folderNameLabel.text = resources?[indexPath.row].name ?? "unresolved"
		return cell
	}
}