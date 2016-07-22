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
  case Features
  case Singles
  
  var name: String {
    switch self {
    case .Features: return "/features/"
    case .Singles: return "/singles/"
    }
  }
}

enum AlbumRouter: RestShipResource {
  case Unique(Int)
  case Tracks(Int)
  case Track(album: Int, track: Int)
  
  var name: String {
    switch self {
    case .Unique(let id): return "/albums/\(id)"
    case .Tracks(let id): return "/albums/\(id)/tracks"
    case .Track(let album_id, let track_id): return "/albums/\(album_id)/tracks/\(track_id)"
    }
  }
}


