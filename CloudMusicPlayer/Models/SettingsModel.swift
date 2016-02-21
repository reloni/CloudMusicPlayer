//
//  SettingsModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

internal class SettingsModel {
	internal let yandexOauth = OAuthResourceBase.Yandex
	internal let isSetUp: Variable<Bool>
	private let bag = DisposeBag()
	init() {
		isSetUp = Variable(yandexOauth.tokenId != nil)
		if let yandexOauth = yandexOauth as? OAuthResourceBase {
			yandexOauth.rx_observe(String.self, "tokenId").subscribeNext { [weak self] id in
				if let strongSelf = self {
					strongSelf.isSetUp.value = id != nil
				}
			}.addDisposableTo(bag)
		}
	}
}