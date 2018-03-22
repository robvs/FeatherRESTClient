//
//  Reachability.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/23/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import SystemConfiguration


/// Helper that checks for a viable internet connection.
public class Reachability {
    
    /// Singleton
    static let shared = Reachability()
    
    /// Private default init to enfore singleton pattern
    private init() {}
}


// MARK: - ReachabilityCheckable conformance

extension Reachability: ReachabilityCheckable {
    
    /// Return `true` if we are currently connected to the internet/network.
    /// This code came from https://stackoverflow.com/questions/30743408/check-for-internet-connection-with-swift
    func isConnected() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
    }
}



// MARK: - FakeReachability

/// This class is used to provide hard-coded responses to help with testing
/// when the web servie is not available.
final class FakeReachability {
}

extension FakeReachability: ReachabilityCheckable {
    
    func isConnected() -> Bool {
        return true
    }
}
