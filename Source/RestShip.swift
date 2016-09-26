//
//  RestShip.swift
//  Source
//
//  Created by Diogo Jayme on 3/26/16.
//  Modified by iTSangarDEV on 3/29/16.
//

import Foundation
import Alamofire

private let RestShipAccessToken   = "RestShipAccessToken"
private let RestShipRefreshToken  = "RestShipRefreshToken"
private let RestShipExpireToken   = "RestShipExpireToken"
private let RestShipTypeToken     = "RestShipTypeToken"
private let RestShipRefreshURL    = "RestShipRefreshURL"

// MARK: -  -

public protocol RestShipResource {
    var name: String { get }
}

// MARK: -  -

public enum Result<T> {
    case success(T)
    case error(String)
    case refreshTokenError
}

// MARK: - -

public struct RestShip {
    fileprivate static var params: [String: AnyObject]?
    fileprivate static var URLrequest: URLRequest?
    fileprivate static var encoding: ParameterEncoding = URLEncoding.default
    fileprivate static var RequestOnURL: String?
    
    public struct Configuration {
        public init() { }
    }
}

// MARK: - -

public extension RestShip.Configuration {
    public static var BaseURL =  ""
    public static var Timeout: TimeInterval = 60
}

// MARK: - -

public extension RestShip.Configuration {
    
    public struct Token {
        public static var AccessToken: String {
            get {
                return RestShip.Configuration.defaultsStringForKey(RestShipAccessToken)
            }
            set {
                RestShip.Configuration.defaultsSetString(newValue, forkey: RestShipAccessToken)
            }
        }
        
        public static var RefreshToken: String {
            get {
                return RestShip.Configuration.defaultsStringForKey(RestShipRefreshToken)
            }
            set {
                RestShip.Configuration.defaultsSetString(newValue, forkey: RestShipRefreshToken)
            }
        }
        
        public static var ExpiresIn: Double {
            get {
                return RestShip.Configuration.defaultsDoubleForKey(RestShipExpireToken)
            }
            set {
                RestShip.Configuration.defaultsSetdouble(newValue, forkey: RestShipExpireToken)
            }
        }
        
        public static var TokenType: String {
            get {
                return RestShip.Configuration.defaultsStringForKey(RestShipTypeToken)
            }
            set {
                RestShip.Configuration.defaultsSetString(newValue, forkey: RestShipTypeToken)
            }
        }
        
        public static var RefreshURL: String {
            get {
                return RestShip.Configuration.defaultsStringForKey(RestShipRefreshURL)
            }
            set {
                RestShip.Configuration.defaultsSetString(newValue, forkey: RestShipRefreshURL)
            }
        }
        
        public static func clearTokens() {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: RestShipAccessToken)
            defaults.removeObject(forKey: RestShipRefreshToken)
            defaults.removeObject(forKey: RestShipExpireToken)
            defaults.removeObject(forKey: RestShipTypeToken)
            defaults.removeObject(forKey: RestShipRefreshURL)
        }
        
    }
    
    fileprivate static func defaultsStringForKey(_ key: String) -> String {
        let defaults = UserDefaults.standard
        guard let object = defaults.string(forKey: key)
            else { return "" }
        return object
    }
    
    fileprivate static func defaultsDoubleForKey(_ key: String) -> Double {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: key)
    }
    
    fileprivate static func defaultsSetString(_ object: String, forkey key: String) {
        let defaults = UserDefaults.standard
        defaults.setValue(object, forKey: key)
    }
    
    fileprivate static func defaultsSetdouble(_ object: Double, forkey key: String) {
        let defaults = UserDefaults.standard
        defaults.set(object, forKey: key)
    }
}

// MARK: - -

public extension RestShip {
    
    public static func request(_ callback: @escaping (Result<AnyObject>) -> Void) {
        
        func resumeRequest(_ request: URLRequest) {
            let mutableURLRequest = try! encoding.encode(request, with: params)
            Alamofire.request(mutableURLRequest)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let result):
                        callback(Result.success(result as AnyObject))
                        break
                    case .failure(let error):
                        callback(Result.error(error.localizedDescription))
                        break
                    }
            }
            
            clearOldData()
        }
        
        func refreshTokenBeforeRequest(_ requestSuccess: @escaping () -> Void) {
            Alamofire.request(RestShip.Configuration.Token.RefreshURL,
                              method: .post,
                              parameters: ["grant_type": "refresh_token", "refresh_token": RestShip.Configuration.Token.RefreshToken],
                              encoding: JSONEncoding.default)
                .responseJSON { response in
                    switch response.result {
                    case .success(_):
                        if let JSONRefresh = response.result.value as? [String: Any] {
                            if let access = JSONRefresh["access_token"] as? String,
                                let refresh = JSONRefresh["refresh_token"] as? String,
                                let expires = JSONRefresh["expires_in"] as? Double,
                                let type = JSONRefresh["token_type"] as? String {
                                
                                RestShip.Configuration.Token.AccessToken = access
                                RestShip.Configuration.Token.RefreshToken = refresh
                                RestShip.Configuration.Token.ExpiresIn = expires
                                RestShip.Configuration.Token.TokenType = type
                                
                                requestSuccess()
                            }
                        }
                        break
                    case .failure(_):
                        callback(Result.refreshTokenError)
                        break
                    }
            }
        }
        
        assert(URLrequest != nil, "URLrequest cannot be nil")
        
        if var request = self.URLrequest {
            
            func addTokenRequest() {
                request.setValue("\(RestShip.Configuration.Token.TokenType) \(RestShip.Configuration.Token.AccessToken)", forHTTPHeaderField: "Authorization")
            }
            
            if !RestShip.Configuration.Token.AccessToken.isEmpty {
                assert(RestShip.Configuration.Token.ExpiresIn != 0, "expiresIn of token is 0")
                let dateExpires = Date(timeIntervalSince1970: RestShip.Configuration.Token.ExpiresIn)
                
                if isValidDate(dateExpires) {
                    addTokenRequest()
                    resumeRequest(request)
                } else {
                    //refresh token
                    refreshTokenBeforeRequest { _ in
                        addTokenRequest()
                        resumeRequest(request)
                    }
                }
            } else {
                //token is not set
                resumeRequest(request)
            }
        }
    }
    
    fileprivate static func isValidDate(_ fromDate: Date) -> Bool {
        switch Date().compare(fromDate) {
        case .orderedDescending:
            return false
        default:
            return true
        }
    }
    
    fileprivate static func clearOldData() {
        RestShip.params = nil
        RestShip.URLrequest = nil
        RestShip.encoding = URLEncoding.default
        RestShip.RequestOnURL = nil
    }
    
    fileprivate static func URL() -> Foundation.URL? {
        if RestShip.RequestOnURL != nil && !RestShip.RequestOnURL!.isEmpty {
            return Foundation.URL(string: RestShip.RequestOnURL!)!
        } else if !RestShip.Configuration.BaseURL.isEmpty {
            return Foundation.URL(string: RestShip.Configuration.BaseURL)!
        }
        assertionFailure("you need set baseURL or call withURL() method")
        return nil
    }
}

// MARK: - -

public extension RestShip {
    
    public enum Encoding {
        case json
        case url
    }
    
    public static func parameterEncoding(_ encoding: RestShip.Encoding) -> RestShip.Type {
        switch encoding {
        case .json:
            self.encoding = JSONEncoding.default
        default:
            self.encoding = URLEncoding.default
        }
        return self
    }
}

// MARK: - -

public extension RestShip {
    
    public enum Method: String {
        case GET, POST, PUT, PATCH, DELETE
    }
    
    public static func method(_ method: RestShip.Method) -> RestShip.Type {
        assert(URLrequest != nil, "You must call resource() before adding method")
        URLrequest?.httpMethod = method.rawValue
        return self
    }
}

// MARK: - -

public extension RestShip {
    public static func queryParams(_ params: [String: AnyObject]) -> RestShip.Type {
        self.params = params
        return self
    }
}

// MARK: - -

public extension RestShip {
    public static func resource(_ resource: RestShipResource) -> RestShip.Type {
        URLrequest = URLRequest(url: RestShip.URL()!.appendingPathComponent(resource.name))
        URLrequest?.timeoutInterval = RestShip.Configuration.Timeout
        return self
    }
}

public typealias EspecificURL = RestShip
public extension EspecificURL {
    public static func fromURL(_ path: String) -> RestShip.Type {
        RestShip.RequestOnURL = path
        return self
    }
}
