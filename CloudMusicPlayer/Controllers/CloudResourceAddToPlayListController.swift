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
		
		model.content.observeOn(MainScheduler.instance).bindNext { [weak self] _ in
			self?.tableView.reloadData()
			}.addDisposableTo(bag)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let resource = model.cachedContent[indexPath.row]
		if resource.type == .Folder,
			let controller = storyboard?.instantiateViewControllerWithIdentifier("AddToPlayListView") as? CloudResourceAddToPlayListController {
			controller.model = CloudResourceModel(resource: resource, cloudResourceClient: model.cloudResourceClient)
			navigationController?.pushViewController(controller, animated: true)
		}
	}
	
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