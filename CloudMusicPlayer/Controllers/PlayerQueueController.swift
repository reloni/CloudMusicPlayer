//
//  PlayerQueueController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class PlayerQueueController: UIViewController {
	var tableViewController: UniversalTableViewController!
	var shouldReloadTable = false
	let bag = DisposeBag()

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let controller = segue.destinationViewController as? UniversalTableViewController
			where segue.identifier == Segues.playerQueueControllerEmbeddedTable.rawValue else { return }
		
		tableViewController = controller
		tableViewController.tableDelegate = self
		tableViewController.tableDataSource = self
	}
	
	func createMenu(trackUid: String, mainModel: MainModel) -> UIAlertController {
		let alert = UIAlertController(title: "Choose action", message: nil, preferredStyle: .ActionSheet)
		
		switch mainModel.player.downloadManager.fileStorage.getItemState(trackUid) {
		case .inPermanentStorage: alert.addAction(UIAlertAction.mediaActionsTrackDefaultDeleteAction(trackUid, model: mainModel))
		case .inTempStorage:
			alert.addAction(UIAlertAction.mediaActionsTrackDefaultSaveAction(trackUid, model: mainModel))
			alert.addAction(UIAlertAction.mediaActionsTrackDefaultDeleteAction(trackUid, model: mainModel))
		case .notExisted: alert.addAction(UIAlertAction.mediaActionsTrackDefaultDownloadAction(trackUid, model: mainModel))
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancel)
		
		return alert
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		MainModel.sharedInstance.player.playerEvents.bindNext { [weak self] event in
			switch event {
			case PlayerEvents.AddNewItem: fallthrough
			case PlayerEvents.AddNewItems: fallthrough
			case PlayerEvents.RemoveItem: fallthrough
			case PlayerEvents.InitWithNewItems:
				self?.shouldReloadTable = true
			default: break
			}
		}.addDisposableTo(bag)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if shouldReloadTable {
			tableViewController.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
			shouldReloadTable = false
		}
	}
}

extension PlayerQueueController : UITableViewDataSource { }

extension PlayerQueueController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return MainModel.sharedInstance.player.count
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return ViewConstants.commonCellHeight
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		guard let queueItem = MainModel.sharedInstance.player.getItemAtPosition(indexPath.row) else {
			fatalError("Cann't return TrackCell for index \(indexPath.row)")
		}
		
		guard let track = (try? MainModel.sharedInstance.player.mediaLibrary.getTrackByUid(queueItem.streamIdentifier.streamResourceUid)) ?? nil else {
			return tableViewController.getLastItemCell("Track not found", itemsCount: 0, indexPath: indexPath)
		}
		
		let cell = tableViewController.getTrackCell(track, indexPath: indexPath, mainModel: MainModel.sharedInstance)
		
		cell.showMenuButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			let alert = object.createMenu(track.uid, mainModel: MainModel.sharedInstance)
			alert.view.setNeedsLayout()
			object.presentViewController(alert, animated: true, completion: nil)
			}.addDisposableTo(cell.bag)
		
		tableViewController.subscribeTrackCellToDefaultEvents(cell, trackUid: track.uid, containerUid: MainModel.sharedInstance.currentPlayingContainerUid ?? "",
		                                                      mainModel: MainModel.sharedInstance)
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let selectedQueueItem = MainModel.sharedInstance.player.getItemAtPosition(indexPath.row) else {
				return
		}
		
		MainModel.sharedInstance.toggleTrack(selectedQueueItem.streamIdentifier.streamResourceUid)
	}
}