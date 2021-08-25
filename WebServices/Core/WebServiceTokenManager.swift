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


// MARK: - Class definition

final class WebServiceTokenManager {
    
    private let tokenStorage: TokenPersisting
    
    init(tokenStorage: TokenPersisting) {
        
        self.tokenStorage = tokenStorage
    }
}


// MARK: - WebServiceTokenManageable conformance

extension WebServiceTokenManager: WebServiceTokenManageable {
    
    var authTokenInfo: WebServiceAuthTokenInfo? {
        return decodeAuthToken(tokenStorage.getAuthToken())
    }
    
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch tokenType {
        case .none:
            completion((token: nil, error: nil))
            
        case .authToken:
            if tokenStorage.isCloseToExpiration() {
                logger.debug("authToken is close to expiration. Renewing...")
                renewToken() { (updatedSessionInfo, error) in
                    
                    if let updatedSessionInfo = updatedSessionInfo {
                        completion((token: updatedSessionInfo.authToken, error: nil))
                    }
                    else {
                        completion((token: nil, error: error))
                    }
                }
            }
            else {
                guard let authToken = tokenStorage.getAuthToken() else {
                    let error = AppString.error(for: .webServiceMissingToken)
                    completion((token: nil, error: WebServiceError.token(error: error)))
                    return
                }
                
                completion((token: authToken, error: nil))
            }
        }
    }
    
    func clearAuthToken() {
        
        tokenStorage.clearAuthToken()
    }
}


// MARK: - Private helpers

private extension WebServiceTokenManager {
    
    /// Renew the given api token.
    /// - parameter apiToken:   The toke to be renewed.
    /// - parameter completion: Closure called upon completion. `error` is nil if successful.
    func renewToken(completion: @escaping (_ updatedSessionInfo: WebServiceSessionModel?, _ error: WebServiceError?) -> Void) {
        
        guard let sessionInfo = tokenStorage.getSessionModel() else {
            let error = AppString.error(for: .webServiceMissingToken)
            completion(nil, WebServiceError.token(error: error))
            return
        }
        
        let requestData = RequestDataForRefreshToken(sessionInfo: sessionInfo)
        JsonWebService.shared.sendRequest(requestData) {
            [weak self] (serviceResult: WebServiceResult<AuthenticationInfo>) in
            
            switch serviceResult {
            case .success(let authInfo):
                guard let authInfo = authInfo else {
                    logger.error("Refresh token request succeeded but the received data model was nil.")
                    let error = AppString.error(for: .webServiceRenewTokenFailed)
                    completion(nil, WebServiceError.token(error: error))
                    break
                }
                
                let expirationDate = Date().addingTimeInterval(Double(authInfo.secondsRemaining))
                let sessionModel = WebServiceSessionModel(authToken: authInfo.accessToken,
                                                          refreshToken: authInfo.refreshToken,
                                                          expirationTime: expirationDate)
                self?.tokenStorage.saveSessionModel(sessionModel)
                completion(sessionModel, nil)
                
            case .failure(let requestError):
                let error = AppString.error(for: .webServiceRenewTokenFailed)
                var logMessage = AppString.errorText(for: .webServiceRenewTokenFailed)
                if let requestError = requestError {
                    logMessage = "\(logMessage) \(requestError.friendlyDescription)"
                }
                
                logger.warn(logMessage)

                completion(nil, WebServiceError.token(error: error))
            }
        }
    }
    
    func decodeAuthToken(_ authToken: String?) -> WebServiceAuthTokenInfo? {
        
        guard let authToken = authToken else { return nil }
        
        let segments = authToken.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }
        
        var base64String = segments[1]
        
        // add padding to the base64 string if necessary.
        if base64String.count % 4 != 0 {
            let padlen = 4 - base64String.count % 4
            base64String.append(contentsOf: repeatElement("=", count: padlen))
        }
        
        guard let tokenData = Data(base64Encoded: base64String) else { return nil }
        
        return JsonUtil.toModel(jsonData: tokenData)
    }
}
