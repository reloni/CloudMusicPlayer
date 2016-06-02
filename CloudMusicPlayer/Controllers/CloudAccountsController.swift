//
//  CloudAccountsController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class CloudAccountsController: UIViewController {
	let model = CloudAccountsModel()
	let bag = DisposeBag()
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var cancelButton: UIBarButtonItem!
	//@IBOutlet weak var doneButton: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		
		navigationItem.title = "Accounts"
		
		//automaticallyAdjustsScrollViewInsets = false
		//tableView.separatorInset.left = 0
		
		cancelButton.rx_tap.bindNext { [weak self] in self?.dismissViewControllerAnimated(true, completion: nil) }.addDisposableTo(bag)
		//doneButton.rx_tap.bindNext { [weak self] in self?.dismissViewControllerAnimated(true, completion: nil) }.addDisposableTo(bag)
		
		OAuthAuthenticator.sharedInstance.processedAuthentications.bindNext { [weak self] _ in
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
	
	func getCell(indexPath: NSIndexPath) -> UITableViewCell {
		let account = indexPath.section == 0 ? model.notLoggedAccounts[indexPath.row].oauth : model.loggedAccounts[indexPath.row].oauth
		if account.accessToken != nil {
			let cell = tableView.dequeueReusableCellWithIdentifier("ExistedAccountCell", forIndexPath: indexPath) as! ExistedAccountCell
			cell.accountNameLabel.text = account.resourceDescription
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("NewAccountCell", forIndexPath: indexPath) as! NewAccountCell
			cell.accountNameLabel.text = account.resourceDescription
			return cell
		}
	}
	
	func authenticate(account: OAuthType) {
		guard let url = account.authUrl else { return }
		OAuthAuthenticator.sharedInstance.addConnection(account)
		UIApplication.sharedApplication().openURL(url)
	}
}

extension CloudAccountsController : UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch(section) {
		case 0: return model.notLoggedAccounts.count > 0 ? "Available accounts" : nil
		case 1: return model.loggedAccounts.count > 0 ? "Connected accounts" : nil
		default: return nil
		}
	}
	
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if indexPath.section == 0 {
			return UITableViewCellEditingStyle.None
		} else {
			return UITableViewCellEditingStyle.Delete
		}
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete && indexPath.section == 1 {
			let account = model.loggedAccounts[indexPath.row].oauth
			account.clearTokens()
			tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
		}
	}
}

extension CloudAccountsController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? model.notLoggedAccounts.count : model.loggedAccounts.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return getCell(indexPath)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 {
			authenticate(model.notLoggedAccounts[indexPath.row].oauth)
		} else if indexPath.section == 1,
			let controller = ViewControllers.addToMediaLibraryController.getController() as? AddToMediaLibraryController {
		//storyboard?.instantiateViewControllerWithIdentifier("AddToMediaLibraryController") as? AddToMediaLibraryController {
			controller.model = CloudResourceModel(resource: model.loggedAccounts[indexPath.row].root,
			                                      cloudResourceClient: CloudResourceClient(cacheProvider: RealmCloudResourceCacheProvider()))
			navigationController?.pushViewController(controller, animated: true)
		}
	}
}