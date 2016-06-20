//
//  MainModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import UIKit

class MainModel {
	static var sharedInstance: MainModel!
	
	var latestShuffleMode: Bool
	let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	let player: RxPlayer
	let cloudResourceClient: CloudResourceClientType
	var loadMetadataTasks = [String: Disposable]()
	let isMetadataLoadInProgressSubject = BehaviorSubject<Bool>(value: false)
	var isMetadataLoadInProgress: Observable<Bool> {
		return isMetadataLoadInProgressSubject
	}
	let userDefaults: NSUserDefaultsProtocol
	
	init(player: RxPlayer, userDefaults: NSUserDefaultsProtocol, cloudResourceClient: CloudResourceClientType) {
		self.player = player
		self.userDefaults = userDefaults
		self.cloudResourceClient = cloudResourceClient
		latestShuffleMode = player.shuffleQueue
	}
	
	/// Uid of current track container playing (uid of Artist, Album or PlayList)
	var currentPlayingContainerUid: String? {
		get {
			return userDefaults.loadData("currentPlayingContainerUid")
		}
		set {
			userDefaults.saveData(newValue ?? "", forKey: "currentPlayingContainerUid")
		}
	}
	
	lazy var albumPlaceHolderImage: UIImage = {
		return UIImage(named: "Album Place Holder")!
	}()
	
	lazy var itemInCloudImage: UIImage = {
		return UIImage(named: "Item in cloud")!
	}()
	
	lazy var itemInTempStorageImage: UIImage = {
		return UIImage(named: "Item in temp storage")!
	}()
	
	lazy var itemInPermanentStorageImage: UIImage = {
		return UIImage(named: "Item in permanent storage")!
	}()
	
	var artists: MediaCollection<ArtistType>? {
		return (try? player.mediaLibrary.getArtists()) ?? nil
	}
	
	var albums: MediaCollection<AlbumType>? {
		return (try? player.mediaLibrary.getAlbums()) ?? nil
	}

	var tracks: MediaCollection<TrackType>? {
		return (try? player.mediaLibrary.getTracks()) ?? nil
	}
	
	var playLists: MediaCollection<PlayListType>? {
		return (try? player.mediaLibrary.getPlayLists()) ?? nil
	}
	
	func addArtistToPlayList(artist: ArtistType, playList: PlayListType) {
		let tracks = artist.albums.map { $0.tracks.map { $0 } }.flatMap { $0 }
		let _ = try? player.mediaLibrary.addTracksToPlayList(playList, tracks: tracks)
	}
	
	func addAlbumToPlayList(album: AlbumType, playList: PlayListType) {
		let _ = try? player.mediaLibrary.addTracksToPlayList(playList, tracks: album.tracks.map { $0 })
	}
	
	func addTracksToPlayList(tracks: [TrackType], playList: PlayListType) {
		if playList.uid == currentPlayingContainerUid {
			currentPlayingContainerUid = ""
		}
		let _ = try? player.mediaLibrary.addTracksToPlayList(playList, tracks: tracks)
	}
	
	func loadPlayerState() {
		do {
			let playerPersistanceProvider = RealmRxPlayerPersistenceProvider()
			try playerPersistanceProvider.loadPlayerState(player)
			latestShuffleMode = player.shuffleQueue
		} catch let error as NSError {
			NSLog("Error while load player state: \(error.localizedDescription)")
		}
	}
	
	func savePlayerState() {
		do {
			let persistance = RealmRxPlayerPersistenceProvider()
			try persistance.savePlayerState(MainModel.sharedInstance.player)
		} catch let error as NSError {
			NSLog("Error while save player state: \(error.localizedDescription)")
		}
	}
}