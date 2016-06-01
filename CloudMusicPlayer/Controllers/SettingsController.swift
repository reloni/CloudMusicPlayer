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
	@IBOutlet weak var googleLogInButton: UIButton!
	
	@IBOutlet weak var logOutButton: UIButton!
	@IBOutlet weak var googleLogOutButton: UIButton!
	
	@IBOutlet weak var permanentStorageLabel: UILabel!
	@IBOutlet weak var tempStorageLabel: UILabel!
	@IBOutlet weak var temporaryFolderLabel: UILabel!
	@IBOutlet weak var clearStorageButton: UIButton!
	@IBOutlet weak var deleteCachedFilesButton: UIButton!

	let model = SettingsViewModel()
	
	private let bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
		logInButton.rx_tap.bindNext {
			//if let url = self.model.yandexOauth.getAuthUrl?() {
			//	UIApplication.sharedApplication().openURL(url)
			//}
			if let url = YandexOAuth().authUrl {
				OAuthAuthenticator.sharedInstance.addConnection(YandexOAuth())
				UIApplication.sharedApplication().openURL(url)
			}
		}.addDisposableTo(bag)
		
		googleLogInButton.rx_tap.bindNext {
			//if let url = self.model.googleOauth.getAuthUrl?() {
			//	UIApplication.sharedApplication().openURL(url)
			//}
			if let url = GoogleOAuth().authUrl {
				OAuthAuthenticator.sharedInstance.addConnection(GoogleOAuth())
				UIApplication.sharedApplication().openURL(url)
			}
		}.addDisposableTo(bag)
		
		logOutButton.rx_tap.bindNext {
			YandexOAuth().clearTokens()
			//self.model.yandexOauth.tokenId = nil
			//self.model.yandexOauth.saveResource()
		}.addDisposableTo(bag)
		
		googleLogOutButton.rx_tap.bindNext {
			GoogleOAuth().clearTokens()
			//self.model.googleOauth.tokenId = nil
			//self.model.googleOauth.saveResource()
			}.addDisposableTo(bag)
		
		model.isYandexSetUp.asDriver(onErrorJustReturn: false).map { !$0 }.drive(logInButton.rx_enabled).addDisposableTo(bag)
		model.isYandexSetUp.asDriver(onErrorJustReturn: false).drive(logOutButton.rx_enabled).addDisposableTo(bag)
		
		model.isGoogleSetUp.asDriver(onErrorJustReturn: false).map { !$0 }.drive(googleLogInButton.rx_enabled).addDisposableTo(bag)
		model.isGoogleSetUp.asDriver(onErrorJustReturn: false).drive(googleLogOutButton.rx_enabled).addDisposableTo(bag)
		
		clearStorageButton.rx_tap.flatMapLatest { _ -> Observable<StorageSize> in
			MainModel.sharedInstance.player.downloadManager.fileStorage.clearStorage()
			try! MainModel.sharedInstance.player.mediaLibrary.clearLibrary()
			return MainModel.sharedInstance.player.downloadManager.fileStorage.calculateSize()
			}.observeOn(MainScheduler.instance).bindNext { [unowned self] size in
				self.permanentStorageLabel.text = "\(Float64(size.permanentStorage) / (1024 * 1024)) Mb"
				self.tempStorageLabel.text = "\(Float64(size.tempStorage) / (1024 * 1024)) Mb"
				self.temporaryFolderLabel.text = "\(Float64(size.temporary) / (1024 * 1024)) Mb"
			}.addDisposableTo(bag)
		
		deleteCachedFilesButton.rx_tap.flatMapLatest { _ -> Observable<StorageSize> in
			MainModel.sharedInstance.player.downloadManager.fileStorage.clearStorage()
			return MainModel.sharedInstance.player.downloadManager.fileStorage.calculateSize()
			}.observeOn(MainScheduler.instance).bindNext { [weak self] size in
				self?.permanentStorageLabel.text = "\(Float64(size.permanentStorage) / (1024 * 1024)) Mb"
				self?.tempStorageLabel.text = "\(Float64(size.tempStorage) / (1024 * 1024)) Mb"
				self?.temporaryFolderLabel.text = "\(Float64(size.temporary) / (1024 * 1024)) Mb"
		}.addDisposableTo(bag)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		MainModel.sharedInstance.player.downloadManager.fileStorage.calculateSize().observeOn(MainScheduler.instance).bindNext { [unowned self] size in
			self.permanentStorageLabel.text = "\(Float64(size.permanentStorage) / (1024 * 1024)) Mb"
			self.tempStorageLabel.text = "\(Float64(size.tempStorage) / (1024 * 1024)) Mb"
			self.temporaryFolderLabel.text = "\(Float64(size.temporary) / (1024 * 1024)) Mb"
			}.addDisposableTo(bag)
	}
}