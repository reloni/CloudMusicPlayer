//
//  AddTrackToPlayListController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class AddItemsToPlayListController: UIViewController {
	@IBOutlet weak var cancelButton: UIBarButtonItem!
	@IBOutlet weak var createPlayListButton: UIBarButtonItem!
	@IBOutlet weak var doneButton: UIBarButtonItem!
	@IBOutlet weak var tableVeiw: UITableView!
	
	var model: AddItemsToPlayListModel!
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//self.title = "Add to play list"
		tableVeiw.setEditing(true, animated: false)
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = DisposeBag()
	}
	
	override func viewWillAppear(animated: Bool) {
		cancelButton.rx_tap.bindNext { [weak self] in
			self?.dismissViewControllerAnimated(true, completion: nil)
		}.addDisposableTo(bag)
		
		createPlayListButton.rx_tap.bindNext { [weak self] in
			self?.showNewAlbumNameAlert()
		}.addDisposableTo(bag)
		
		doneButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			if let selectedRows = object.tableVeiw.indexPathsForSelectedRows {
				let selectedPlayLists = selectedRows.map { MainModel.sharedInstance.playLists?[$0.row] }.filter { $0 != nil }.map { $0! }
				object.model.addItemsToPlayLists(selectedPlayLists)
			}
			object.dismissViewControllerAnimated(true, completion: nil)
		}.addDisposableTo(bag)
	}
	
	func showNewAlbumNameAlert() {
		let alert = UIAlertController(title: "Enter play list name", message: nil, preferredStyle: .Alert)
		alert.addTextFieldWithConfigurationHandler {
			$0.placeholder = "Play list name"
		}
		let ok = UIAlertAction(title: "OK", style: .Default) { [weak self] _ in
			if let newPlayListName = alert.textFields?.first?.text {
				do {
					try MainModel.sharedInstance.player.mediaLibrary.createPlayList(newPlayListName)
					self?.tableVeiw.reloadData()
				} catch { }
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancel)
		alert.addAction(ok)
		alert.view.setNeedsLayout()
		presentViewController(alert, animated: true, completion: nil)
	}
}

extension AddItemsToPlayListController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return MainModel.sharedInstance.playLists?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PlayListCell", forIndexPath: indexPath) as! PlayListCell
		cell.playListNameLabel.text = MainModel.sharedInstance.playLists?[indexPath.row]?.name
		return cell
	}
}