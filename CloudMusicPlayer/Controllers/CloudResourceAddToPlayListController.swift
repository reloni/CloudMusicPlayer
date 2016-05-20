//
//  CloudResourceController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class CloudResourceAddToPlayListController: UIViewController {
	var model: CloudResourceModel!
	let bag = DisposeBag()
	
	@IBOutlet weak var selectAllSwitch: UISwitch!
	@IBOutlet weak var selectAllLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
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
				cell.setSelected(false, animated: false)
			}
		}
	}
	
	func showChilds(indexPath: NSIndexPath) {
		let resource = model.cachedContent[indexPath.row]
		if resource.type == .Folder,
			let controller = storyboard?.instantiateViewControllerWithIdentifier("AddToPlayListView") as? CloudResourceAddToPlayListController {
			controller.model = CloudResourceModel(resource: resource, cloudResourceClient: model.cloudResourceClient)
			navigationController?.pushViewController(controller, animated: true)
			tableView.deselectRowAtIndexPath(indexPath, animated: false)
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

extension CloudResourceAddToPlayListController : UITableViewDelegate {
	//func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		//guard !tableView.editing else { return }
		//let resource = model.cachedContent[indexPath.row]
		//if resource.type == .Folder,
		//	let controller = storyboard?.instantiateViewControllerWithIdentifier("AddToPlayListView") as? CloudResourceAddToPlayListController {
		//	controller.model = CloudResourceModel(resource: resource, cloudResourceClient: model.cloudResourceClient)
		//	navigationController?.pushViewController(controller, animated: true)
		//}
	//}
	
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