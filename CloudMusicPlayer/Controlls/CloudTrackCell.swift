//
//  CloudTrackCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit

class CloudTrackCell: UITableViewCell {
	var track: CloudAudioResource? {
		didSet {
			trackTitleLabel.text = track?.title
			albumNameLabel.text = track?.album
			artistNameLabel.text = track?.artist
			trackLengthLabel.text = String(track?.trackLength)
			albumYearLabel.text = String(track?.albumYear)
		}
	}
	@IBOutlet weak var trackTitleLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var albumNameLabel: UILabel!
	@IBOutlet weak var albumYearLabel: UILabel!
	@IBOutlet weak var trackLengthLabel: UILabel!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var pauseButton: UIButton!
	@IBOutlet weak var stopButton: UIButton!
}
