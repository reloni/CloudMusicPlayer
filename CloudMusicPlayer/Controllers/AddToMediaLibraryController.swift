//
//  CloudResourceController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class AddToMediaLibraryController: UIViewController {
	var model: CloudResourceModel!
	let bag = DisposeBag()
	
	@IBOutlet weak var selectAllSwitch: UISwitch!
	@IBOutlet weak var selectAllLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var cancelButton: UIBarButtonItem!
	@IBOutlet weak var doneButton: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		//tableView.separatorInset.left = 0
		navigationItem.title = model.displayName
		tableView.setEditing(true, animated: false)
		
		let tableCellTap = UITapGestureRecognizer(target: self, action: #selector(self.tableCellTap))
		tableCellTap.cancelsTouchesInView = false
		tableView.addGestureRecognizer(tableCellTap)
		
		model.content.observeOn(MainScheduler.instance).bindNext { [weak self] _ in
			self?.tableView.reloadData()
			}.addDisposableTo(bag)
		
		cancelButton.rx_tap.bindNext { [weak self] in
			self?.dismissViewControllerAnimated(true, completion: nil)
		}.addDisposableTo(bag)
		
		doneButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			if let selectedRows = object.tableView.indexPathsForSelectedRows {
				MainModel.sharedInstance.loadMetadataToLibrary(selectedRows.map { object.model.cachedContent[$0.row] })
			}
			object.dismissViewControllerAnimated(true, completion: nil)
		}.addDisposableTo(bag)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.reloadData()
	}
	
	func tableCellTap(recognizer: UIGestureRecognizer) {
		let location = recognizer.locationInView(tableView)
		if let indexPath = tableView.indexPathForRowAtPoint(location) {
			guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? FolderInfoCell else { return }
			if cell.folderNameLabel.pointInside(recognizer.locationInView(cell.folderNameLabel), withEvent: nil) {
				showChilds(indexPath)
			}
		}
	}
	
	func showChilds(indexPath: NSIndexPath) {
		let resource = model.cachedContent[indexPath.row]
		if resource.type == .Folder,
			let controller = ViewControllers.addToMediaLibraryController.getController() as? AddToMediaLibraryController {
			controller.model = CloudResourceModel(resource: resource, cloudResourceClient: model.cloudResourceClient)
			navigationController?.pushViewController(controller, animated: true)
		}
	}
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/
	
}

extension AddToMediaLibraryController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.cachedContent.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("FolderInfoCell", forIndexPath: indexPath) as! FolderInfoCell
		cell.setDisplayResource(model.cachedContent[indexPath.row])
		cell.refresh()
		return cell
	}
}