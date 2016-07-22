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
  case Success(T)
  case Error(String)
  case RefreshTokenError
}

// MARK: - -

public struct RestShip {
  private static var params: [String: AnyObject]?
  private static var URLrequest: NSMutableURLRequest?
  private static var encoding = Alamofire.ParameterEncoding.URL
  private static var RequestOnURL: String?
  
  public struct Configuration {
    public init() { }
  }
}

// MARK: - -

public extension RestShip.Configuration {
  public static var BaseURL =  ""
  public static var Timeout: NSTimeInterval = 60
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
      let defaults = NSUserDefaults.standardUserDefaults()
      defaults.removeObjectForKey(RestShipAccessToken)
      defaults.removeObjectForKey(RestShipRefreshToken)
      defaults.removeObjectForKey(RestShipExpireToken)
      defaults.removeObjectForKey(RestShipTypeToken)
      defaults.removeObjectForKey(RestShipRefreshURL)
    }

  }
  
  private static func defaultsStringForKey(key: String) -> String {
    let defaults = NSUserDefaults.standardUserDefaults()
    guard let object = defaults.stringForKey(key)
      else { return "" }
    return object
  }
  
  private static func defaultsDoubleForKey(key: String) -> Double {
    let defaults = NSUserDefaults.standardUserDefaults()
    return defaults.doubleForKey(key)
  }
  
  private static func defaultsSetString(object: String, forkey key: String) {
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setValue(object, forKey: key)
  }
  
  private static func defaultsSetdouble(object: Double, forkey key: String) {
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setDouble(object, forKey: key)
  }
}

// MARK: - -

public extension RestShip {
  
  public static func request(callback: Result<AnyObject> -> Void) {
    
    func resumeRequest(request: NSMutableURLRequest) {
      let mutableURLRequest = encoding.encode(request, parameters: params).0
      Alamofire.request(mutableURLRequest)
        .validate()
        .responseJSON { response in
          switch response.result {
          case .Success(let result):
            callback(Result.Success(result))
            break
          case .Failure(let error):
            callback(Result.Error(error.description))
            break
          }
      }
      
      clearOldData()
    }
    
    func refreshTokenBeforeRequest(requestSuccess: () -> Void) {
      Alamofire.request(.POST,
        RestShip.Configuration.Token.RefreshURL,
        parameters: ["grant_type": "refresh_token", "refresh_token": RestShip.Configuration.Token.RefreshToken],
        encoding: .JSON)
        .responseJSON { response in
          switch response.result {
          case .Success(let JSONRefresh):
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
            break
          case .Failure(_):
            callback(Result.RefreshTokenError)
            break
          }
      }
    }
    
    assert(URLrequest != nil, "URLrequest cannot be nil")
    
    if let request = self.URLrequest {
      
      func addTokenRequest() {
        request.setValue("\(RestShip.Configuration.Token.TokenType) \(RestShip.Configuration.Token.AccessToken)", forHTTPHeaderField: "Authorization")
      }
      
      if !RestShip.Configuration.Token.AccessToken.isEmpty {
        assert(RestShip.Configuration.Token.ExpiresIn != 0, "expiresIn of token is 0")
        let dateExpires = NSDate(timeIntervalSince1970: RestShip.Configuration.Token.ExpiresIn)
        
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
  
  private static func isValidDate(fromDate: NSDate) -> Bool {
    switch NSDate().compare(fromDate) {
    case .OrderedDescending:
      return false
    default:
      return true
    }
  }
  
  private static func clearOldData() {
    RestShip.params = nil
    RestShip.URLrequest = nil
    RestShip.encoding = Alamofire.ParameterEncoding.URL
    RestShip.RequestOnURL = nil
  }
  
  private static func URL() -> NSURL {
    if RestShip.RequestOnURL != nil && !RestShip.RequestOnURL!.isEmpty {
      return NSURL(string: RestShip.RequestOnURL!)!
    } else if !RestShip.Configuration.BaseURL.isEmpty {
      return NSURL(string: RestShip.Configuration.BaseURL)!
    }
    assertionFailure("you need set baseURL or call withURL() method")
    return NSURL()
  }
}

// MARK: - -

public extension RestShip {
  
  public enum Encoding {
    case JSON
    case URL
  }
  
  public static func parameterEncoding(encoding: RestShip.Encoding) -> RestShip.Type {
    switch encoding {
    case .JSON:
      self.encoding = .JSON
    default:
      self.encoding = .URL
    }
    return self
  }
}

// MARK: - -

public extension RestShip {
  
  public enum Method: String {
    case GET, POST, PUT, PATCH, DELETE
  }

  public static func method(method: RestShip.Method) -> RestShip.Type {
    assert(URLrequest != nil, "You must call resource() before adding method")
    URLrequest?.HTTPMethod = method.rawValue
    return self
  }
}

// MARK: - -

public extension RestShip {
  public static func queryParams(params: [String: AnyObject]) -> RestShip.Type {
    self.params = params
    return self
  }
}

// MARK: - -

public extension RestShip {
  public static func resource(resource: RestShipResource) -> RestShip.Type {
    URLrequest = NSMutableURLRequest(URL: RestShip.URL().URLByAppendingPathComponent(resource.name))
    URLrequest?.timeoutInterval = RestShip.Configuration.Timeout
    return self
  }
}

public typealias EspecificURL = RestShip
public extension EspecificURL {
  public static func fromURL(path: String) -> RestShip.Type {
    RestShip.RequestOnURL = path
    return self
  }
}