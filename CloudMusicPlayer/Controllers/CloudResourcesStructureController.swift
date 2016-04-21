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

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var stackView: UIStackView!
	
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
			parent.loadChildResources().observeOn(MainScheduler.instance).doOnError { [unowned self] in self.showAlert($0 as NSError) }
				.bindNext { [unowned self] childs in
				self.viewModel.resources = childs
				self.tableView.reloadData()
			}.addDisposableTo(bag!)
		} else if navigationController?.viewControllers.first == self {
			YandexDiskCloudJsonResource.loadRootResources(OAuthResourceManager.getYandexResource(), httpRequest: HttpClient(),
				cacheProvider: CloudResourceNsUserDefaultsCacheProvider(loadCachedData: true))?
				.observeOn(MainScheduler.instance).doOnError { [unowned self] in self.showAlert($0 as NSError) }
				.bindNext { [unowned self] childs in
					self.viewModel.resources = childs
					self.tableView.reloadData()
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
	
	override func viewWillDisappear(animated: Bool) {
		bag = nil
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func play(track: CloudAudioResource) {
		if let identifier = track as? StreamResourceIdentifier {
			rxPlayer.playUrl(identifier)
		} else {
			track.downloadUrl?.bindNext { result in
				guard let url = result else { return }
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
		
		if resource.type == "dir" {
			cell.bag = DisposeBag()
			cell.playButton.rx_tap.shareReplay(1).flatMapLatest { _ -> Observable<[StreamResourceIdentifier]> in
				print("tap")
				return resource.loadChildResources(.RemoteOnly).map { e in return e.filter { $0 is CloudAudioResource }.map { $0 as! StreamResourceIdentifier } }
				}.bindNext { [weak self] items in
					rxPlayer.initWithNewItems(items)
					dispatch_async(dispatch_get_main_queue()) {
						self?.performSegueWithIdentifier("ShowPlayerQueueSegue", sender: self)
					}
					rxPlayer.resume(true)
					print("Player items count: \(rxPlayer.count)")
			}.addDisposableTo(cell.bag)
		} else {
			cell.playButton.hidden = true
		}
		return cell
	}
}