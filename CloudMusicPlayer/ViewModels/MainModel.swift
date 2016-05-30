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

class MainModel {
	static var sharedInstance: MainModel!
	
	let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	let player: RxPlayer
	var loadMetadataTasks = [String: Disposable]()
	let isMetadataLoadInProgressSubject = BehaviorSubject<Bool>(value: false)
	var isMetadataLoadInProgress: Observable<Bool> {
		return isMetadataLoadInProgressSubject
	}
	
	init(player: RxPlayer) {
		self.player = player
	}
	
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
		return Observable.create { observer in
			let task = resources.toObservable().flatMap{ resource -> Observable<CloudResource> in
				if resource is CloudAudioResource {
					return Observable.just(resource)
				} else {
					return resource.loadChildResourcesRecursive()
				}
				}.filter { $0 is CloudAudioResource
				}.map { item -> StreamResourceIdentifier in return item as! StreamResourceIdentifier
				}.flatMap { self.player.loadMetadata($0) }.doOnCompleted { observer.onCompleted() }.subscribe()
			
			return AnonymousDisposable {
				task.dispose()
				observer.onCompleted()
			}
		}
	}
}