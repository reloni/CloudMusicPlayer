//
//  SettingsModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

internal class SettingsViewModel {
	internal let yandexOauth = OAuthResourceManager.getYandexResource()
	internal let googleOauth = OAuthResourceManager.getGoogleResource()
	internal let isYandexSetUp: Variable<Bool>
	internal let isGoogleSetUp: Variable<Bool>
	private let bag = DisposeBag()
	init() {
		isYandexSetUp = Variable(yandexOauth.tokenId != nil)
		isGoogleSetUp = Variable(googleOauth.tokenId != nil)
		
		if let yandexOauth = yandexOauth as? OAuthResourceBase {
			yandexOauth.rx_observe(String.self, "tokenId").subscribeNext { [weak self] id in
				if let strongSelf = self {
					strongSelf.isYandexSetUp.value = id != nil
				}
			}.addDisposableTo(bag)
		}
		
//		if let googleOauth = googleOauth as? OAuthResourceBase {
//			googleOauth.rx_observe(String.self, "tokenId").subscribeNext { [weak self] id in
//				if let strongSelf = self {
//					strongSelf.isGoogleSetUp.value = id != nil
//				}
//				}.addDisposableTo(bag)
//		}
	}
}