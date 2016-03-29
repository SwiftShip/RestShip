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
    
    RestShip.resource(MainRouter.Features)
      .method(.GET)
      .request({ result in
        switch result {
        case .Success(let object):
          print(object)
          break
        case .Error(let error):
          print(error)
          break
        }
      })
  }
  
}

