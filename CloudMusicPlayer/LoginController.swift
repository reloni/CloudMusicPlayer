//
//  LoginController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 23.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
	@IBOutlet weak var webView: UIWebView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
//		let url = "https://oauth.yandex.ru/authorize?response_type=token&client_id=6556b9ed6fb146ea824d2e1f0d98f09b"
//		if let nsUrl = NSURL(string: url) {
//			webView.loadRequest(NSURLRequest(URL: nsUrl))
//		}
		
		let url = "https://cloud-api.yandex.net:443/v1/disk"
		if let nsUrl = NSURL(string: url), yaResource = SharedSettings.Instance.getCloudResource("yandexDisk") {
			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let req = NSMutableURLRequest(URL: nsUrl)
			req.setValue(yaResource.token, forHTTPHeaderField: "Authorization")
			let task = session.dataTaskWithRequest(req, completionHandler: { (data, response, error) -> Void in
				if let content = data {
					do {
						let result = try NSJSONSerialization.JSONObjectWithData(content, options: .MutableContainers)
						let a = result["system_folders"]!!["applications"]!
						print(a)
					}
					catch {
						
					}
				}
			})
			task.resume()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
//	@IBAction func logIn(sender: AnyObject) {
//		let url = "https://oauth.yandex.ru/authorize?response_type=token&client_id=6556b9ed6fb146ea824d2e1f0d98f09b"
//		//let url = "https://www.google.com";
//		//UIApplication.sharedApplication().openURL(NSURL(fileURLWithPath: url))
//		webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
//	}
	
}