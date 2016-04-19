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
	
	@IBOutlet weak var permanentStorageLabel: UILabel!
	@IBOutlet weak var tempStorageLabel: UILabel!
	@IBOutlet weak var temporaryFolderLabel: UILabel!
	@IBOutlet weak var clearStorageButton: UIButton!

	let model = SettingsViewModel()
	
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
		
		clearStorageButton.rx_tap.flatMapLatest { _ -> Observable<StorageSize> in
			rxPlayer.downloadManager.fileStorage.clearStorage()
			return rxPlayer.downloadManager.fileStorage.calculateSize()
			}.observeOn(MainScheduler.instance).bindNext { [unowned self] size in
				self.permanentStorageLabel.text = "\(Float64(size.permanentStorage) / (1024 * 1024)) Mb"
				self.tempStorageLabel.text = "\(Float64(size.tempStorage) / (1024 * 1024)) Mb"
				self.temporaryFolderLabel.text = "\(Float64(size.temporary) / (1024 * 1024)) Mb"
			}.addDisposableTo(bag)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		rxPlayer.downloadManager.fileStorage.calculateSize().observeOn(MainScheduler.instance).bindNext { [unowned self] size in
			self.permanentStorageLabel.text = "\(Float64(size.permanentStorage) / (1024 * 1024)) Mb"
			self.tempStorageLabel.text = "\(Float64(size.tempStorage) / (1024 * 1024)) Mb"
			self.temporaryFolderLabel.text = "\(Float64(size.temporary) / (1024 * 1024)) Mb"
			}.addDisposableTo(bag)
	}
}