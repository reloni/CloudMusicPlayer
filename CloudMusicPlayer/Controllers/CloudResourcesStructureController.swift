//
//  CloudResourcesStructureController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
import AVFoundation
import RxSwift
import RxCocoa
import MobileCoreServices

class CloudResourcesStructureController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var playTestButton: UIBarButtonItem!
	
	var resources: [CloudResource]?
	var parent: CloudResource?
	
	var player: AVPlayer?
	var bag = DisposeBag()
	var respondedLength: Int64 = 0
	
	var delegateQueue: dispatch_queue_t?
	
	var pendingRequests = [AVAssetResourceLoadingRequest]()
	//var connection: NSURLConnection?
	var response: NSHTTPURLResponse?
	var dataTask: NSURLSessionDataTask?
	var data: NSMutableData?
	private lazy var session: NSURLSession = {
		return NSURLSession(configuration: .defaultSessionConfiguration(),
			delegate: self,
			delegateQueue: NSOperationQueue.mainQueue())
	}()
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		
		playTestButton.rx_tap.bindNext {
//			if let url = NSURL(string: "http://freemusicarchive.org/music/download/ee7f72ac94c50d8d570d24d6bb91522dba1ed061") {
//				self.player = AVPlayer(URL: url)
//				self.player?.play()
//			}
			self.playSong()
		}.addDisposableTo(bag)
		
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		title = parent?.name ?? "Root"
		if let parent = parent {
			parent.loadChilds { res in
				self.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		} else if navigationController?.viewControllers.first == self {
			YandexCloudJsonResource.loadRootResources(OAuthResourceBase.Yandex) { res in
				self.resources = res
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func playSong() {
		//		if let queue = delegateQueue {
		//			//dispatch_ca
		//		}
		//delegateQueue = dispatch_queue_create("testQueue", nil)
		//dispatch_sync(delegateQueue!) {
		//dispatch_async(dispatch_get_main_queue()) {
		//print("main thread \(NSThread.isMainThread())")
			if let url = NSURL(string: "shit://freemusicarchive.org/music/download/ee7f72ac94c50d8d570d24d6bb91522dba1ed061") {
				let asset = AVURLAsset(URL: url)
				asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
				//asset.resourceLoader.setDelegate(self, queue: self.delegateQueue)
				let playerItem = AVPlayerItem(asset: asset)
				self.player = AVPlayer(playerItem: playerItem)
				//if player?.status == .ReadyToPlay
				playerItem.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
					if let strong = self {
						print("player status: \(status?.rawValue)")
						if status == .ReadyToPlay {
							strong.player?.play()
						}
					}
					}.addDisposableTo(self.bag)
			}
		//}
	}
	
	func processPendingRequests() {
//		guard let delegateQueue = delegateQueue else {
//			return
//		}
		//print("main thread \(NSThread.isMainThread())")
		//dispatch_async(dispatch_get_main_queue()) {
		//dispatch_sync(self.delegateQueue!) {
		//print("pending req: \(self.pendingRequests.count)")
			self.pendingRequests = self.pendingRequests.filter { request in
				if let contentInformationRequest = request.contentInformationRequest {
					self.fillInContentInformation(contentInformationRequest)
				}
				
				if let dataRequest = request.dataRequest {
					if self.isRequestCompleteAfterRespondingToRequestedData(dataRequest) {
						request.finishLoading()
						return false
					}
				}
				return true
			}
		
		//print("pending req: \(self.pendingRequests.count)")
		//}
	}
	
	private func fillInContentInformation(request: AVAssetResourceLoadingContentInformationRequest) {
		guard let MIMEType = response?.MIMEType, contentLength = response?.expectedContentLength else {
			return
		}
		
		request.byteRangeAccessSupported = true
		request.contentLength = contentLength
		if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
			request.contentType = contentType.takeUnretainedValue() as String
		}
	}
	
	private func isRequestCompleteAfterRespondingToRequestedData(request: AVAssetResourceLoadingDataRequest) -> Bool {
		guard let data = self.data else {
			return false
		}
		print("requestedLength: \(request.requestedLength)")
		print("requestedOffset: \(request.requestedOffset)")
		print("currentOffset\(request.currentOffset)")
		
		let startOffset = request.currentOffset != 0 ? request.currentOffset : request.requestedOffset
		
		if Int64(data.length) < startOffset {
			return false
		}
		
		//let unreadBytesLength = totalDataLengthReceived - startOffset
		let unreadBytesLength = Int64(data.length) - startOffset
		let responseLength = min(Int64(request.requestedLength), unreadBytesLength)
		//NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
		
//		//if Int64(data.length) < responseLength {
//		//	return false
//		//}
		if responseLength == 0 {
			return false
		}
		let range = NSMakeRange(Int(startOffset), Int(responseLength))
		print("start offset: \(startOffset) response len: \(responseLength) data len: \(data.length)")
		print("Respond range: \(range)")
		respondedLength += responseLength
		print("respondedLength \(respondedLength)")
		request.respondWithData(data.subdataWithRange(range))
		
		//if startOffset > 0 {
		//	data.replaceBytesInRange(range, withBytes: nil, length: 0)
		//}
		
		let endOffset = startOffset + request.requestedLength
		let didRespondFully = (Int64(data.length) >= endOffset)
		print(didRespondFully)
		return didRespondFully
	}
}

extension CloudResourcesStructureController : AVAssetResourceLoaderDelegate {
	func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		print("shouldWaitForLoadingOfRequestedResource")
		
		if dataTask == nil {
			if let url = NSURL(string: "http://freemusicarchive.org/music/download/ee7f72ac94c50d8d570d24d6bb91522dba1ed061") {
				let request = NSURLRequest(URL: url)
				let task = session.dataTaskWithRequest(request)
//				let task = session.dataTaskWithRequest(request) {
//					(data, response, error) in
//					print(data?.length)
//				}
				
				dataTask = task
				task.resume()
			}
		}
		pendingRequests.append(loadingRequest)
		//processPendingRequests()
		return true
	}
	
	func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		print("didCancelLoadingRequest")
		if let index = pendingRequests.indexOf(loadingRequest) {
			pendingRequests.removeAtIndex(index)
			//dataTask?.cancel()
		}
	}
}

extension CloudResourcesStructureController : NSURLSessionDataDelegate {
	func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
		print("didReceiveResponse")
		self.data = NSMutableData()
		//totalDataLengthReceived = 0
		self.response = response as? NSHTTPURLResponse
		
		processPendingRequests()
		
		completionHandler(.Allow)
	}
	
	func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		print("didReceiveData")
		//print("Received data len:\(data.length)")
		self.data?.appendData(data)
		print("Current data len: \(self.data?.length)")
		//totalDataLengthReceived += data.length
		
		processPendingRequests()
		
		//delegate?.resourceLoader(self, didReceiveData: data)
	}
	
	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		print("didCompleteWithError")
		print("error: \(error)")
		processPendingRequests()
		//delegate?.resourceLoader(self, didFinishLoadingWithError: error)
	
	}
}

extension CloudResourcesStructureController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let controller = storyboard?.instantiateViewControllerWithIdentifier("RootViewController") as? CloudResourcesStructureController,
		 resource = resources?[indexPath.row] where resources?[indexPath.row].type == "dir"	else {
			return
		}

		controller.parent = resource
		navigationController?.pushViewController(controller, animated: true)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resources?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("SimpleCell", forIndexPath: indexPath)
		cell.textLabel?.text = resources?[indexPath.row].name ?? "unresolved"
		return cell
	}
	
	//	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
	//		forRowAtIndexPath indexPath: NSIndexPath) {
	//			if(editingStyle == UITableViewCellEditingStyle.Delete) {
	//				places.removeAtIndex(indexPath.row)
	//				self.placesTable.reloadData()
	//			}
	//	}
	
	//	func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
	//		selectedPlace = places[indexPath.row]
	//		return indexPath
	//	}
}