//
//  MasterViewController.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 3/13/18.
//  Copyright © 2018 Random Visual, LLC.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import UIKit

class MasterViewController: UITableViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var detailViewController: DetailViewController? = nil
	var jokes = [Joke]()


	override func viewDidLoad() {
		super.viewDidLoad()
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetList))
		navigationItem.rightBarButtonItem = resetButton
		if let split = splitViewController {
		    let controllers = split.viewControllers
		    detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
		}
        
        signIn() { (didSucceed) in
            if didSucceed {
                requestRandomJokes()
            }
        }
	}

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
		        let joke = jokes[indexPath.row]
		        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
		        controller.detailItem = joke.joke
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return jokes.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let joke = jokes[indexPath.row]
        let category = joke.categories.first != nil ? " (\(joke.categories.first!))" : ""
        cell.textLabel!.text = "Joke id: \(joke.id)" + category
		return cell
	}
}


// MARK: - Public methods

extension MasterViewController {
    
    @objc func resetList() {
        requestRandomJokes()
    }
}


// MARK: - Private helpers

private extension MasterViewController {
    
    func signIn(completion: (_ didSucceed: Bool) -> Void) {
        
        spinner.startAnimating()
        
        let requestData = RequestDataForAuthenticate(userId: "user-id", password: "passme")
        JsonWebService.shared.sendRequest(requestData) { [weak self] (authResponse: WebServiceResult<AuthenticationInfo>) in
            
            self?.spinner.stopAnimating()
            
            switch authResponse {
            case .success(let authInfo):
                if let authInfo = authInfo {
                    BasicAuthManager.shared.update(apiToken: authInfo.apiToken, secondsRemaining: authInfo.secondsRemaining)
                    DispatchQueue.main.async {
                        self?.requestRandomJokes()
                    }
                }
            case .failure(let webServiceError):
                print("\(#file)-\(#function) request error: ", webServiceError?.friendlyDescription ?? "unknown")
            }
        }
    }
    
    func requestRandomJokes() {
        
        spinner.startAnimating()
        
        let requestData = RequestDataForRandomJokes(numberOfJokes: 10) // Note that FakeUrlSessionManager is hard-coded to a specific number of jokes
        JsonWebService.shared.sendRequest(requestData) { [weak self] (jokesResponse: WebServiceResult<JokeListResponse>) in
            
            self?.spinner.stopAnimating()
            
            switch jokesResponse {
            case .success(let jokeList):
                if let jokeList = jokeList {
                    self?.jokes = jokeList.value
                    self?.tableView.reloadData()
                }
                
            case .failure(let webServiceError):
                print("\(#file)-\(#function) request error: ", webServiceError?.friendlyDescription ?? "unknown")
                self?.jokes.removeAll()
                self?.tableView.reloadData()
            }
        }
    }
}

