//
//  MainModel+LoadMetadata.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 16.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension MainModel {
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
}