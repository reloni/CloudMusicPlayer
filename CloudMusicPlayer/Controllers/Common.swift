//
//  ViewConstants.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 16.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit

enum Storyboards : String {
	case main = "Main"
	case cloudAccounts = "CloudAccounts"
	func getStoryboard() -> UIStoryboard {
		switch self {
		case .main: return UIStoryboard(name: rawValue, bundle: nil)
		case .cloudAccounts: return UIStoryboard(name: rawValue, bundle: nil)
		}
	}
}

enum ViewControllers : String {
	case rootTabBarController = "RootTabBarController"
	case addToMediaLibraryNavigationController = "AddToMediaLibraryNavigationController"
	case addToMediaLibraryController = "AddToMediaLibraryController"
	case addItemsToPlayListController = "AddItemsToPlayListView"
	case universalTableVeiw = "UniversalTableVeiw"
	case playListInfoView = "PlayListInfoView"
	func getController() -> UIViewController {
		switch self {
		case .rootTabBarController: return Storyboards.main.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addToMediaLibraryNavigationController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addToMediaLibraryController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addItemsToPlayListController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .universalTableVeiw: return Storyboards.main.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .playListInfoView: return Storyboards.main.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		}
	}
}

enum Segues : String {
	case mediaLibraryControllerEmbeddedTable = "MediaLibrarySceneShowTable"
	case playListInfoControllerEmbeddedTable = "PlayListSceneShowTracksTable"
	case mediaLibraryControllerToPlayListInfo = "ShowPlayListInfo"
	case playerQueueControllerEmbeddedTable = "PlayerQueueSceneShowTable"
}

struct ViewConstants {
	static let trackProgressBarHeight = CGFloat(integerLiteral: 2)
	static let playListHeaderHeight = CGFloat(integerLiteral: 90)
	static let commonCellHeight = CGFloat(integerLiteral: 65)
	static let itemsCountCellHeight = CGFloat(integerLiteral: 25)
}