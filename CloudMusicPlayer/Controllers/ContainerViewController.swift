//
//  ContainerViewController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {
	@IBOutlet weak var upperContainer: UIView!
	
	@IBOutlet weak var bottomContainer: UIView!
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		
		//let vc = ViewControllers.universalTableVeiw.getController()
		//addChildViewController(vc)
		//vc.didMoveToParentViewController(self)
		//vc.view.frame = upperContainer.frame
		//upperContainer.addSubview(vc.view)
		
		//let vc2 = ViewControllers.universalTableVeiw.getController()
		//addChildViewController(vc2)
		//vc2.didMoveToParentViewController(self)
		//vc2.view.frame = bottomContainer.frame
		//bottomContainer.addSubview(vc2.view)
		
		//let s = UIStoryboardSegue(identifier: "test", source: self, destination: vc2)
		//s.perform()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
