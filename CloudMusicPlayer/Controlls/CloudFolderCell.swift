//
//  CloudTrackCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class CloudFolderCell: UITableViewCell {
	internal var bag = DisposeBag()
	
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var folderNameLabel: UILabel!
}
