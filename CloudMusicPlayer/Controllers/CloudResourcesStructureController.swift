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
import RxCocoa
import RxSwift
import AVFoundation

let cloudResourceClient = CloudResourceClient(cacheProvider: RealmCloudResourceCacheProvider())

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var stackView: UIStackView!
	
	@IBOutlet weak var errorLabel: UILabel!
	let viewModel = CloudResourcesViewModel()
	var bag: DisposeBag?
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		super.viewDidLoad()
	}
	
	override func viewWillAppear(animated: Bool) {
		errorLabel.hidden = true
	}
	
	override func viewDidAppear(animated: Bool) {
		bag = DisposeBag()
		
		navigationItem.title = viewModel.parent?.name ?? "/"
		if let parent = viewModel.parent {
			cloudResourceClient.loadChildResources(parent, loadMode: .CacheAndRemote).observeOn(MainScheduler.instance)
				.bindNext { [weak self] result in
					if case Result.success(let box) = result {
						self?.viewModel.resources = box.value
						self?.tableView.reloadData()
					} else if case Result.error(let error) = result {
						self?.showErrorLabel(error as NSError)
					}
				}.addDisposableTo(bag!)
		} else if navigationController?.viewControllers.first == self {
			cloudResourceClient.loadChildResources(YandexDiskCloudJsonResource.getRootResource(oauth: YandexOAuth()),
				loadMode: .CacheAndRemote).observeOn(MainScheduler.instance)
				.bindNext { [weak self] result in
					if case Result.success(let box) = result {
						self?.viewModel.resources = box.value
						self?.tableView.reloadData()
					}else if case Result.error(let error) = result {
						self?.showErrorLabel(error as NSError)
					}
				}.addDisposableTo(bag!)
		}
	}
	
	func showAlert(error: NSError) {
		let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
		let ok = UIAlertAction(title: "OK", style: .Default) { [unowned self] _ in
			self.dismissViewControllerAnimated(true, completion: nil)
		}
		alert.addAction(ok)
		presentViewController(alert, animated: true, completion: nil)
	}
	
	func showErrorLabel(error: NSError) {
		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.errorLabel.hidden = false
			self.errorLabel.text = error.localizedDescription
		}) { _ in
			UIView.animateWithDuration(0.5, delay: 2.0, options: [], animations: { [unowned self] in self.errorLabel.hidden = true }, completion: nil)
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
			MainModel.sharedInstance.player.playUrl(identifier)
		} else {
			track.downloadUrl.bindNext { url in
				MainModel.sharedInstance.player.playUrl(url)
				}.addDisposableTo(bag!)
		}
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if viewModel.resources?[indexPath.row].type == .Folder, let resource = viewModel.resources?[indexPath.row],
			controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController {
		
			controller.viewModel.parent = resource
			navigationController?.pushViewController(controller, animated: true)
		} else if let audio  = viewModel.resources?[indexPath.row] as? CloudAudioResource {
			self.play(audio)
			//self.performSegueWithIdentifier("ShowPlayerQueueSegue", sender: self)
		}
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let resource = viewModel.resources![indexPath.row]
		
		let cell = tableView.dequeueReusableCellWithIdentifier("CloudFolderCell", forIndexPath: indexPath) as! CloudFolderCell
		cell.folderNameLabel.text = resource.name ?? "unresolved"
		
		if resource.type == .Folder {
			// create new bag to dispose previous observers
			cell.bag = DisposeBag()
//			cell.playButton.rx_tap.bindNext {
//				resource.loadChildResourcesRecursive().filter { $0 is CloudAudioResource }.map { $0 as! StreamResourceIdentifier }.toArray()
//					.bindNext { [weak self] items in
//						MainModel.sharedInstance.player.initWithNewItems(items)
//						dispatch_async(dispatch_get_main_queue()) {
//							self?.performSegueWithIdentifier("ShowPlayerQueueSegue", sender: self)
//						}
//						MainModel.sharedInstance.player.resume(true)
//						print("Player items count: \(MainModel.sharedInstance.playLists?.count)")
//				}.addDisposableTo(cell.bag)
//			}.addDisposableTo(cell.bag)
		} else {
			cell.playButton.hidden = true
		}
		return cell
	}
}