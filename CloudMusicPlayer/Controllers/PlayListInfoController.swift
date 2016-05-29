//
//  PlayListInfoController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class PlayListInfoController: UIViewController {
	var model: PlayListInfoModel!
	@IBOutlet weak var playListNameLabel: UILabel!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var addBarButton: UIBarButtonItem!
	
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		playListNameLabel.text = model.playList.name
	}
	
	override func viewWillAppear(animated: Bool) {
		playButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			MainModel.sharedInstance.player.playPlayList(object.model.playList)
		}.addDisposableTo(bag)
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = DisposeBag()
	}
}

extension PlayListInfoController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.playList.items.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		cell.trackTitleLabel.text = model.playList.items[indexPath.row]?.title
		return cell
	}
}