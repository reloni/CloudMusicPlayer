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
//import Alamofire
import RxCocoa
import RxSwift
import AVFoundation

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let viewModel = CloudResourcesViewModel()
	var bag: DisposeBag?
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		bag = DisposeBag()
		
		navigationItem.title = viewModel.parent?.name ?? "/"
		if let parent = viewModel.parent {
			parent.loadChilds()?.observeOn(MainScheduler.instance).bindNext { [unowned self] result in
				if case .Success(let childs) = result {
					self.viewModel.resources = childs
					self.tableView.reloadData()
				}
			}.addDisposableTo(bag!)
		} else if navigationController?.viewControllers.first == self {
			YandexDiskCloudJsonResource.loadRootResources(OAuthResourceManager.getYandexResource())?.observeOn(MainScheduler.instance).bindNext { [unowned self] result in
				if case .Success(let childs) = result {
					self.viewModel.resources = childs
					self.tableView.reloadData()
				}
			}.addDisposableTo(bag!)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = nil
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func play(track: CloudAudioResource) {
		track.downloadUrl?.bindNext { result in
			guard let url = result else { return }
			//streamPlayer.play(url, customHttpHeaders: track.getRequestHeaders())
			streamPlayer.playUrl(url, customHttpHeaders: track.getRequestHeaders(), resourceMimeType: "audio/mpeg")
		}.addDisposableTo(bag!)
	}
	
	func stop() {
		streamPlayer.stop()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController,
//		 resource = viewModel.resources?[indexPath.row] where viewModel.resources?[indexPath.row].type == "dir" else {
//			return
//		}

		if viewModel.resources?[indexPath.row].type == "dir", let resource = viewModel.resources?[indexPath.row],
			controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController {
		
			controller.viewModel.parent = resource
			navigationController?.pushViewController(controller, animated: true)
		} else if let audio  = viewModel.resources?[indexPath.row] as? CloudAudioResource {
			self.play(audio)
		}
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let resource = viewModel.resources![indexPath.row]
		
//		if let resource = resource as? CloudAudioResource {
//			let cell = tableView.dequeueReusableCellWithIdentifier("CloudTrackCell", forIndexPath: indexPath) as! CloudTrackCell
//			cell.track = resource
//			cell.playButton.rx_tap.bindNext { [unowned self] in
//				guard let track = cell.track else {
//					return
//				}
//				self.play(track)
//				}.addDisposableTo(viewModel.bag)
//			cell.stopButton.rx_tap.bindNext { [unowned self] in
//				self.stop()
//			}.addDisposableTo(viewModel.bag)
//			return cell
//		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("CloudFolderCell", forIndexPath: indexPath) as! CloudFolderCell
		cell.folderNameLabel.text = resource.name ?? "unresolved"
		return cell
	}
}