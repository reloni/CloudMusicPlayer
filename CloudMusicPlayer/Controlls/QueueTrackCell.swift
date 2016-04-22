//
//  QueueTrackCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class QueueTrackCell: UITableViewCell {
	internal var bag = DisposeBag()
	
	@IBOutlet weak var albumArtImage: UIImageView!
	@IBOutlet weak var trackTitleLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var trackTimeLabel: UILabel!

	deinit {
		print("track cell deinit")
	}
}
