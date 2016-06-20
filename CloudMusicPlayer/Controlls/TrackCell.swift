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
	@IBOutlet weak var trackCurrentTimeProgressView: UIProgressView?
	@IBOutlet weak var trackCurrentTimeProgressStackViewHeightConstraint: NSLayoutConstraint?
	@IBOutlet weak var storageStatusImage: UIImageView?
	@IBOutlet weak var cloudServiceImage: UIImageView?
	
	override func prepareForReuse() {
		bag = DisposeBag()
		albumAndArtistLabel?.text = ""
		trackTitleLabel.text = ""
		durationLabel.text = "--:--"
		albumArtworkImage?.image = MainModel.sharedInstance.albumPlaceHolderImage
		trackCurrentTimeProgressView?.setProgress(0, animated: false)
		trackCurrentTimeProgressStackViewHeightConstraint?.constant = CGFloat(integerLiteral: 0)
	}
	
	override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
		/*id hitView = [super hitTest:point withEvent:event];
		
		if (hitView == self) {
			return nil;
		} else {
			return hitView;
		}*/
		let hitView = super.hitTest(point, withEvent: event)
		if (hitView == self) {
			return nil
		} else {
			return hitView
		}
	}
}
