//
//  ViewController.swift
//  RestShip
//
//  Created by iTSangar on 03/29/2016.
//  Copyright (c) 2016 iTSangar. All rights reserved.
//

import UIKit
import RestShip

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let bodyParams = ["username": "teste123", "passsword": "teste123"]
    
    RestShip.resource(MainRouter.features)
      .method(.POST)
      .parameterEncoding(.json)
      .queryParams(bodyParams as [String : AnyObject])
      .request({ callback in
        
        print(callback)
        
      })
    
  
    
    RestShip.resource(MainRouter.features)
      .method(.GET)
      .request({ result in
        switch result {
        case .success(let object):
          print(object)
          break
        case .error(let error):
          print(error)
          break
        case .refreshTokenError:
          print("Could not refresh oauth token")
          break
        }
      })
  }
  
}

