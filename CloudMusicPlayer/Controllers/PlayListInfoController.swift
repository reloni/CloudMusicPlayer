//
//  PlayListInfoController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit

class PlayListInfoController: UIViewController {
	var model: PlayListInfoModel!
	@IBOutlet weak var playListNameLabel: UILabel!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var addBarButton: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		playListNameLabel.text = model.playList.name
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