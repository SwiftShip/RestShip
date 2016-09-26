//
//  Routers.swift
//  RestFire
//
//  Created by Diogo Jayme on 3/24/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import RestShip

enum MainRouter: RestShipResource{
  case features
  case singles
  
  var name: String {
    switch self {
    case .features: return "/features/"
    case .singles: return "/singles/"
    }
  }
}

enum AlbumRouter: RestShipResource {
  case unique(Int)
  case tracks(Int)
  case track(album: Int, track: Int)
  
  var name: String {
    switch self {
    case .unique(let id): return "/albums/\(id)"
    case .tracks(let id): return "/albums/\(id)/tracks"
    case .track(let album_id, let track_id): return "/albums/\(album_id)/tracks/\(track_id)"
    }
  }
}


