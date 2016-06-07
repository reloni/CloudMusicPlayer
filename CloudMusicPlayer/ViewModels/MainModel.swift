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
	}
	
	var isShuffleEnabled: Bool {
		get {
			guard let value: Bool = userDefaults.loadData("isShuffleEnabled") else { return false }
			return value
		}
		set {
			userDefaults.saveData(newValue, forKey: "isShuffleEnabled")
		}
	}
	
	var isRepeatEnabled: Bool {
		get {
			return player.repeatQueue
		}
		set {
			player.repeatQueue = newValue
			userDefaults.saveData(newValue, forKey: "isRepeatEnabled")
		}
	}
	
	lazy var albumPlaceHolderImage: UIImage = {
		return UIImage(named: "Album Place Holder")!
	}()
	
	var artists: MediaCollection<ArtistType, RealmArtist>? {
		return (try? player.mediaLibrary.getArtists()) ?? nil
	}
	
	var albums: MediaCollection<AlbumType, RealmAlbum>? {
		return (try? player.mediaLibrary.getAlbums()) ?? nil
	}

	var tracks: MediaCollection<TrackType, RealmTrack>? {
		return (try? player.mediaLibrary.getTracks()) ?? nil
	}
	
	var playLists: MediaCollection<PlayListType, RealmPlayList>? {
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
		let _ = try? player.mediaLibrary.addTracksToPlayList(playList, tracks: tracks)
	}
	
	func loadMetadataObjectForTrackByIndex(index: Int) -> Observable<MediaItemMetadata?> {
		return Observable.create { [weak self] observer in
			guard let track = (try? self?.player.mediaLibrary.getTracks()[index]) ?? nil else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			let metadata = MediaItemMetadata(resourceUid: track.uid,
				artist: track.artist.name,
				title: track.title,
				album: track.album.name,
				artwork: track.album.artwork,
				duration: track.duration)
			
			observer.onNext(metadata)
			observer.onCompleted()
			
			return NopDisposable.instance
			}.subscribeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
	}
	
	func loadMetadataObjectForAlbumByIndex(index: Int) -> Observable<MediaItemMetadata?> {
		return Observable.create { [weak self] observer in
			guard let album = (try? self?.player.mediaLibrary.getAlbums()[index]) ?? nil else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			let metadata = MediaItemMetadata(resourceUid: "",
				artist: album.artist.name,
				title: nil,
				album: album.name,
				artwork: album.artwork,
				duration: nil)
			
			observer.onNext(metadata)
			observer.onCompleted()
			
			return NopDisposable.instance
			}.subscribeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
	}
	
	func loadMetadataObjectForTrackInPlayListByIndex(index: Int, playList: PlayListType) -> Observable<MediaItemMetadata?> {
		return Observable.create { observer in
			guard let track = playList.items[index] else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			let metadata = MediaItemMetadata(resourceUid: track.uid,
				artist: track.artist.name,
				title: track.title,
				album: track.album.name,
				artwork: track.album.artwork,
				duration: track.duration)
			
			observer.onNext(metadata)
			observer.onCompleted()
			
			return NopDisposable.instance
			}
	}
	
	func cancelMetadataLoading() {
		loadMetadataTasks.forEach { $0.1.dispose() }
		loadMetadataTasks.removeAll()
		isMetadataLoadInProgressSubject.onNext(false)
	}
	
	func loadMetadataToLibrary(resources: [CloudResource]) {
		isMetadataLoadInProgressSubject.onNext(true)
		let taskUid = NSUUID().UUIDString
		let task = createMetadataLoadTask(resources).observeOn(serialScheduler).doOnCompleted { [weak self] in
			guard let object = self else { return }
			object.loadMetadataTasks[taskUid] = nil
			if object.loadMetadataTasks.count == 0 && (try? object.isMetadataLoadInProgressSubject.value()) == true {
				object.isMetadataLoadInProgressSubject.onNext(false)
			}
		}.subscribeOn(serialScheduler).subscribe()
		loadMetadataTasks[taskUid] = task
	}
	
	func createMetadataLoadTask(resources: [CloudResource]) -> Observable<Void> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			let task = resources.toObservable().flatMap{ resource -> Observable<CloudResource> in
				if resource is CloudAudioResource {
					return Observable.just(resource)
				} else {
					
					return object.cloudResourceClient.loadChildResourcesRecursive(resource, loadMode: CloudResourceLoadMode.RemoteOnly)
						.flatMapLatest { result -> Observable<CloudResource> in
							if case Result.success(let box) = result {
								return box.value.toObservable()
							} else {
								return Observable.empty()
							}
					}
					//return resource.loadChildResourcesRecursive()
				}
				}.filter { $0 is CloudAudioResource
				}.map { item -> StreamResourceIdentifier in return item as! StreamResourceIdentifier
				}.flatMap { object.player.loadMetadata($0) }.doOnCompleted { observer.onCompleted() }.subscribe()
			
			return AnonymousDisposable {
				task.dispose()
				observer.onCompleted()
			}
		}
	}
	
	func loadPlayerState() {
		do {
			let playerPersistanceProvider = RealmRxPlayerPersistenceProvider()
			try playerPersistanceProvider.loadPlayerState(player)
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