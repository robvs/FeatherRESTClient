//
//  DetailViewController.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 3/13/18.
//  Copyright © 2018 Random Visual, LLC.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import UIKit

class DetailViewController: UIViewController {

	@IBOutlet weak var detailDescriptionLabel: UILabel!


	func configureView() {
		// Update the user interface for the detail item.
		if let detail = detailItem {
		    if let label = detailDescriptionLabel {
		        label.text = detail
		    }
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		configureView()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	var detailItem: String? {
		didSet {
		    // Update the view.
		    configureView()
		}
	}


}

