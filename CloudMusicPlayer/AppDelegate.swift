//
//  AppDelegate.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import RxSwift
import MediaPlayer

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
	func getController() -> UIViewController {
		switch self {
		case .rootTabBarController: return Storyboards.main.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addToMediaLibraryNavigationController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addToMediaLibraryController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		case .addItemsToPlayListController: return Storyboards.cloudAccounts.getStoryboard().instantiateViewControllerWithIdentifier(rawValue)
		}
	}
}

//var streamPlayer = StreamAudioPlayer(allowSaveCachedData: true)
//var rxPlayer = RxPlayer(repeatQueue: false, downloadManager: DownloadManager(saveData: true, fileStorage: LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true),
//													httpUtilities: HttpUtilities()), streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: RealmMediaLibrary())

class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let bag = DisposeBag()

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		#if DEBUG
			NSLog("Documents Path: %@", NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first ?? "")
		#endif
		
		
		let player = RxPlayer(repeatQueue: false,
		                      downloadManager: DownloadManager(saveData: true, fileStorage: LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true),
														httpUtilities: HttpUtilities()),
		                      streamPlayerUtilities: StreamPlayerUtilities(),
		                      mediaLibrary: RealmMediaLibrary())
		let cloudResourceClient = CloudResourceClient(cacheProvider: RealmCloudResourceCacheProvider())
		MainModel.sharedInstance = MainModel(player: player, userDefaults: NSUserDefaults.standardUserDefaults(), cloudResourceClient: cloudResourceClient)
		MainModel.sharedInstance.player.setUIApplication(UIApplication.sharedApplication())
		
		let cloudResourceLoader = CloudResourceLoader(cacheProvider: cloudResourceClient.cacheProvider!,
		                                              rootCloudResources: [YandexDiskCloudJsonResource.typeIdentifier:
																										YandexDiskCloudJsonResource.getRootResource(HttpClient(), oauth: YandexOAuth())])
		MainModel.sharedInstance.player.streamResourceLoaders.append(cloudResourceLoader)
		
		//do {
		//	try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: .DefaultToSpeaker)
		//	try AVAudioSession.sharedInstance().setActive(true)
		//} catch let error as NSError {
		//	NSLog("Error while set up audio session \(error.localizedDescription)")
		//}
		
		MainModel.sharedInstance.player.playerEvents.bindNext { event in
			print("player event: \(event)")
			switch event {
			//case PlayerEvents.CurrentItemChanged: fallthrough
			case PlayerEvents.Stopped: fallthrough
			case PlayerEvents.Paused: fallthrough
			case PlayerEvents.Started: fallthrough
			case PlayerEvents.Resumed:
				guard let info = MainModel.sharedInstance.player.getCurrentItemMetadataForNowPlayingCenter() else {
					MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
					break
				}
				MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
			default: break
			}
		}.addDisposableTo(bag)
		
		
//		Observable<Int>.interval(1, scheduler: MainScheduler.instance).bindNext { _ in
//			print("Resource count: \(RxSwift.resourceCount)")
//		}.addDisposableTo(bag)
		
		becomeFirstResponder()
		UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
		
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let initialController = storyboard.instantiateViewControllerWithIdentifier("RootTabBarController")
		window?.rootViewController = initialController
		window?.makeKeyAndVisible()
		
		return true
	}
	
	
	
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override func remoteControlReceivedWithEvent(event: UIEvent?) {
		if event?.type == .RemoteControl {
			switch event!.subtype {
			case UIEventSubtype.RemoteControlPlay: MainModel.sharedInstance.player.resume(true)
			case UIEventSubtype.RemoteControlStop: MainModel.sharedInstance.player.pause()
			case UIEventSubtype.RemoteControlPause: MainModel.sharedInstance.player.pause()
			case UIEventSubtype.RemoteControlTogglePlayPause: print("remote control toggle play/pause")
			case UIEventSubtype.RemoteControlNextTrack: MainModel.sharedInstance.player.toNext(true)
			case UIEventSubtype.RemoteControlPreviousTrack: MainModel.sharedInstance.player.toPrevious(true)
			default: super.remoteControlReceivedWithEvent(event)
			}
		} else {
			super.remoteControlReceivedWithEvent(event)
		}
	}
	
	// вызывается при вызове приложения по URL схеме
	// настраивается в  Info.plist в разделе URL types/URL Schemes
	func application(application: UIApplication,
	                 openURL url: NSURL, options: [String: AnyObject]) -> Bool {
		//if let result = OAuthResourceManager().parseCallbackUrl(url.absoluteString) {
		//	result.resource.tokenId = result.token
		//	result.resource.saveResource()
		//}
		OAuthAuthenticator.sharedInstance.processCallbackUrl(url.absoluteString).doOnCompleted {
			print("oauth authorization completed")
			}.doOnNext { oauth in
				print("type: \(oauth.oauthTypeId) new token: \(oauth.accessToken) refresh token: \(oauth.refreshToken)")
		}.subscribe().addDisposableTo(bag)
	
		return true
	}
//	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
////		if let result = OAuthResourceManager().parseCallbackUrl(url.absoluteString) {
////			result.resource.tokenId = result.token
////			result.resource.saveResource()
////		}
//		
//		var options: [String: AnyObject] = [UIApplicationOpenURLOptionsSourceApplicationKey: sourceApplication!,
//		                                    UIApplicationOpenURLOptionsAnnotationKey: annotation]
//		let handled = GIDSignIn.sharedInstance().handleURL(url,
//		                                                   sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String,
//		                                                   annotation: options[UIApplicationOpenURLOptionsAnnotationKey])
//		print(handled)
//		// [1] Dismiss webview once url is passed to extract authorization code
//		//UIApplication.sharedApplication().keyWindow?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
//		
//		return true
//	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
		print("applicationWillResignActive")
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		//SharedSettings.Instance.saveData()
		print("applicationDidEnterBackground")
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
		print("applicationWillEnterForeground")
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		print("applicationDidBecomeActive")
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		//SharedSettings.Instance.saveData()
		self.saveContext()
	}

	// MARK: - Core Data stack

	lazy var applicationDocumentsDirectory: NSURL = {
	    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.AntonEfimenko.CloudMusicPlayer" in the application's documents Application Support directory.
	    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
	    return urls[urls.count-1]
	}()

	lazy var managedObjectModel: NSManagedObjectModel = {
	    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
	    let modelURL = NSBundle.mainBundle().URLForResource("CloudMusicPlayer", withExtension: "momd")!
	    return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
	    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
	    // Create the coordinator and store
	    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
	    var failureReason = "There was an error creating or loading the application's saved data."
	    do {
	        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
	    } catch {
	        // Report any error we got.
	        var dict = [String: AnyObject]()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
	        dict[NSLocalizedFailureReasonErrorKey] = failureReason

	        dict[NSUnderlyingErrorKey] = error as NSError
	        let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
	        // Replace this with code to handle the error appropriately.
	        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	        NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
	        abort()
	    }
	    
	    return coordinator
	}()

	lazy var managedObjectContext: NSManagedObjectContext = {
	    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
	    let coordinator = self.persistentStoreCoordinator
	    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
	    managedObjectContext.persistentStoreCoordinator = coordinator
	    return managedObjectContext
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    if managedObjectContext.hasChanges {
	        do {
	            try managedObjectContext.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
	            abort()
	        }
	    }
	}

}

