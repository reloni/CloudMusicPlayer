//
//  PlayListCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class PlayListCell: UITableViewCell {
	var bag = DisposeBag()
	
	@IBOutlet weak var itemsCountLabel: UILabel?
	@IBOutlet weak var playListImage: UIImageView?
	@IBOutlet weak var playListNameLabel: UILabel!
	@IBOutlet weak var playButton: UIButton?
	@IBOutlet weak var shuffleButton: UIButton?
	@IBOutlet weak var repeatButton: UIButton?
	@IBOutlet weak var itemDownloadStatusButton: UIButton?
	@IBOutlet weak var menuButton: UIButton!

	override func prepareForReuse() {
		bag = DisposeBag()
		itemsCountLabel?.text = nil
		playListImage?.image = MainModel.sharedInstance.albumPlaceHolderImage
	}
}
