//
//  TrackCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class TrackCell: UITableViewCell {
	var bag = DisposeBag()
	
	@IBOutlet weak var albumArtworkImage: UIImageView?
	@IBOutlet weak var albumAndArtistLabel: UILabel?
	@IBOutlet weak var trackTitleLabel: UILabel!
	@IBOutlet weak var showMenuButton: UIButton!
	@IBOutlet weak var durationLabel: UILabel!
	
	override func prepareForReuse() {
		bag = DisposeBag()
		albumAndArtistLabel?.text = ""
		trackTitleLabel.text = ""
		durationLabel.text = "--:--"
		albumArtworkImage?.image = MainModel.sharedInstance.albumPlaceHolderImage
	}
}
