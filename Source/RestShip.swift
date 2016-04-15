//
//  RestShip.swift
//  Source
//
//  Created by Diogo Jayme on 3/26/16.
//  Modified by iTSangarDEV on 3/29/16.
//

import Foundation
import Alamofire

// MARK: -  -

public protocol RestShipResource {
  var name: String { get }
}

// MARK: -  -

public enum Result<T> {
  case Success(T)
  case Error(String)
}

// MARK: - RestShipConfiguration -

public struct RestShip {
  private static var params: [String: AnyObject]?
  private static var URLrequest: NSMutableURLRequest?
  private static var encoding = Alamofire.ParameterEncoding.URL
  
  public struct Configuration {
    public static var baseURL =  ""
    public static var timeOut: NSTimeInterval = 60
  }
}

// MARK: - -

public extension RestShip {
  public static func request(callback: Result<AnyObject> -> Void) {
    assert(URLrequest != nil, "URLrequest cannot be nil")
    assert(!RestShip.Configuration.baseURL.isEmpty, "baseURL cannot be empty")
    
    if let req = self.URLrequest {
      let mutableURLRequest = encoding.encode(req, parameters: params).0
      Alamofire.request(mutableURLRequest)
        .validate()
        .responseJSON { response in
          switch response.result{
          case .Success(let result):
            callback(Result.Success(result))
            break
          case .Failure(let error):
            callback(Result.Error(error.description))
            break
          }
      }
    } else {
      return
    }
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
    assert(URLrequest != nil, "You must call path() before adding method")
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
    let URL = NSURL(string: RestShip.Configuration.baseURL)!
    URLrequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(resource.name))
    URLrequest?.timeoutInterval = RestShip.Configuration.timeOut
    return self
  }
}
