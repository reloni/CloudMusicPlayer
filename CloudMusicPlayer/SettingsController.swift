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
	
	@IBOutlet weak var logOutButton: UIButton!
	
	private let yandexOauth = OAuthResourceBase.Yandex
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		logInButton.enabled = yandexOauth.tokenId == nil
		logOutButton.enabled = yandexOauth.tokenId != nil
	}
	
	@IBAction func logIn(sender: AnyObject) {
		if let url = yandexOauth.getAuthUrl?() {
			UIApplication.sharedApplication().openURL(url)
		}
	}
	
	@IBAction func logOut(sender: AnyObject) {
		yandexOauth.tokenId = nil
		yandexOauth.saveResource()
		logInButton.enabled = yandexOauth.tokenId == nil
		logOutButton.enabled = yandexOauth.tokenId != nil
	}
}