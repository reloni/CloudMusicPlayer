//
//  SettingsController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

import UIKit

class SettingsController: UIViewController {
	@IBOutlet weak var logInButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		logInButton.enabled = OAuthResourceBase.Yandex.tokenId == nil
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func logIn(sender: AnyObject) {
//		let url = "https://oauth.yandex.ru/authorize?response_type=token&client_id=6556b9ed6fb146ea824d2e1f0d98f09b"
//		if let nsUrl = NSURL(string: url) {
//			UIApplication.sharedApplication().openURL(nsUrl)
//		}
		if let url = OAuthResourceBase.getResourceById(CloudResourceType.Yandex)?.getAuthUrl() {
			UIApplication.sharedApplication().openURL(url)
		}
	}
	
	@IBAction func logOut(sender: AnyObject) {
	}
	
}