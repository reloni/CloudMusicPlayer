//
//  AlbumCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class AlbumCell: UITableViewCell {
	var bag = DisposeBag()
	
	@IBOutlet weak var albumNameLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var albumArtworkImage: UIImageView!
	@IBOutlet weak var showMenuButton: UIButton!
	@IBOutlet weak var tracksCountLabel: UILabel!
	
	override func prepareForReuse() {
		albumNameLabel.text = ""
		artistNameLabel.text = ""
		tracksCountLabel.text = ""
		albumArtworkImage.image = MainModel.sharedInstance.albumPlaceHolderImage
		bag = DisposeBag()
	}
}
