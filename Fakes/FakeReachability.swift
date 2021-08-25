//
//  FakeReachability.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import Foundation


/// This class is used to provide hard-coded responses to help with testing when the web service is not available.
final class FakeReachability {
}

extension FakeReachability: ReachabilityCheckable {

    func isConnected() -> Bool {
        return true
    }
}
