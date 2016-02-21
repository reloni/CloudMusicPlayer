//
//  SettingsController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class SettingsController: UIViewController {
	@IBOutlet weak var logInButton: UIButton!
	
	@IBOutlet weak var logOutButton: UIButton!
	
	let model = SettingsModel()
	
	private let bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		logInButton.rx_tap.bindNext { [unowned self] in
			if let url = self.model.yandexOauth.getAuthUrl?() {
				UIApplication.sharedApplication().openURL(url)
			}
		}.addDisposableTo(bag)
		
		logOutButton.rx_tap.bindNext { [unowned self] in
			self.model.yandexOauth.tokenId = nil
			self.model.yandexOauth.saveResource()
		}.addDisposableTo(bag)
		
		model.isSetUp.asDriver().asDriver(onErrorJustReturn: false).map { !$0 }.drive(logInButton.rx_enabled).addDisposableTo(bag)
		model.isSetUp.asDriver().asDriver(onErrorJustReturn: false).drive(logOutButton.rx_enabled).addDisposableTo(bag)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}