//
//  WebServiceTokenManager.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/26/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation

final class WebServiceTokenManager {}

extension WebServiceTokenManager: WebServiceTokenManageable {
    
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch tokenType {
        case .none:
            completion((token: nil, error: nil))
            
        case .basicAuth:
            guard let apiToken = BasicAuthManager.shared.apiToken else {
                let errorMessage = "Attempted to call protected service but no token was found."
                let errorUserInfo = [NSLocalizedDescriptionKey : errorMessage]
                let error = NSError(domain: thisAppErrorDomain, code: -1, userInfo: errorUserInfo)
                
                    completion((token: nil, error: WebServiceError.token(error: error)))
                    return
            }
            
            if BasicAuthManager.shared.isSessionExpired {
                renewToken(apiToken) { (error) in
                    if error == nil {
                        completion((token: apiToken, error: nil))
                    }
                    else {
                        completion((token: nil, error: error))
                    }
                }
            }
            else {
                completion((token: apiToken, error: nil))
            }
        }
    }
}


// MARK: - Private helpers

private extension WebServiceTokenManager {
    
    /// Renew the given api token.
    /// - parameter apiToken:   The toke to be renewed.
    /// - parameter completion: Closure called upon completion. `error` is nil if successful.
    func renewToken(_ apiToken: String, completion: @escaping (_ error: WebServiceError?) -> Void) {
        
        let requestData =  RequestDataForRenewToken()
        JsonWebService.shared.sendRequest(requestData) { [weak self] (serviceResult: WebServiceResult<AuthenticationInfo>) in
            
            switch serviceResult {
            case .success(let model):
                guard let authenticationInfo = model else {
                    // TODO: log this
                    assertionFailure("AuthenticationViewController.authenticateUser(): data model is nil.")
                    return
                }
                
                self?.updateSession(with: authenticationInfo)
                completion(nil)
                
            case .failure(let requestError):
                // TODO: log this
                var errorMessage = "Authorization token renewal failed. Please sign-out/sign-in if this error continues."
                if let requestError = requestError {
                    errorMessage = requestError.friendlyDescription
                }
                
                let errorUserInfo = [NSLocalizedDescriptionKey : errorMessage]
                let error = NSError(domain: thisAppErrorDomain, code: -1, userInfo: errorUserInfo)

                completion(WebServiceError.token(error: error))
            }
        }
    }
    
    func updateSession(with authenticationInfo: AuthenticationInfo) {
        
        BasicAuthManager.shared.update(apiToken: authenticationInfo.apiToken,
                                       secondsRemaining: authenticationInfo.secondsRemaining)
        
        print("Renew token with updated expirationTime: \(BasicAuthManager.shared.expirationTime)")
    }
}
