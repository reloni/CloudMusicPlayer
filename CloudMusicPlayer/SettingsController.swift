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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func logIn(sender: AnyObject) {
		let url = "https://oauth.yandex.ru/authorize?response_type=token&client_id=6556b9ed6fb146ea824d2e1f0d98f09b"
		if let nsUrl = NSURL(string: url) {
			UIApplication.sharedApplication().openURL(nsUrl)
		}
	}
	
	@IBAction func logOut(sender: AnyObject) {
	}
	
}