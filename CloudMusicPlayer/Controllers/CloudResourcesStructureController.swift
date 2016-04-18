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
		if let identifier = track as? StreamResourceIdentifier {
			//streamPlayer.playUrl(identifier, createNewQueue: true, customHttpHeaders: track.getRequestHeaders())
			rxPlayer.playUrl(identifier)
		} else {
			track.downloadUrl?.bindNext { result in
				guard let url = result else { return }
				//streamPlayer.play(url, customHttpHeaders: track.getRequestHeaders())
				//streamPlayer.playUrl(url, createNewQueue: true, customHttpHeaders: track.getRequestHeaders())
				rxPlayer.playUrl(url)
				
				}.addDisposableTo(bag!)
		}
	}
	
	func stop() {
		//rxPlayer.stop()
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

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
		
		let cell = tableView.dequeueReusableCellWithIdentifier("CloudFolderCell", forIndexPath: indexPath) as! CloudFolderCell
		cell.folderNameLabel.text = resource.name ?? "unresolved"
		
		if resource.type == "dir" {
			cell.playButton.rx_tap.flatMapLatest { _ -> Observable<CloudRequestResult> in
				return resource.loadChilds() ?? Observable<CloudRequestResult>.just(CloudRequestResult.Success(nil))
				}.bindNext { result in
					if case .Success(let childs) = result {
						if let childs = childs {
							rxPlayer.initWithNewItems(childs.filter { $0 is CloudAudioResource }.map { $0 as! StreamResourceIdentifier })
							print("Player items count: \(rxPlayer.count)")
						}
					}
				}.addDisposableTo(bag!)
		} else {
			cell.playButton.hidden = true
		}
		return cell
	}
}