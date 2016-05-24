//
//  ArtistCell.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class ArtistCell: UITableViewCell {
	var bag: DisposeBag = DisposeBag()
	
	@IBOutlet weak var albumCountLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var showMenuButton: UIButton!
	
	override func prepareForReuse() {
		bag = DisposeBag()
	}
}
