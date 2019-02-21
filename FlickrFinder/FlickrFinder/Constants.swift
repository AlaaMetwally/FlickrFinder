//
//  Constants.swift
//  FlickrFinder
//
//  Created by Geek on 2/2/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import UIKit

struct Constants{

    struct  Flickr {
        static let Scheme = "https"
        static let HostName = "api.flickr.com"
        static let Path = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0,90.0)
        static let SearchLonRange = (-180.0,180.0)
    }
    
    struct FlickrParameterKeys {
        static let APIKey = "api_key"
        static let Method = "method"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NOJSONCallBack = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    struct FlickrParameterValues {
        static let APIKey = "08b4104b06917923c90be54ef77969fa"
        static let SearchMethod = "flickr.photos.search"
        static let Method = "flickr.galleries.getPhotos"
        static let GalleryID = "72157688996270423"
        static let Medium = "url_m"
        static let Format = "json"
        static let NOJSONCallBack = "1"
        static let SafeSearch = "1"
    }
    
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Pages = "pages"
        static let Total = "total"
        static let MediumURL = "url_m"
        static let Title = "title"
    }
    
    struct FlickrResponseValues{
        static let OkStatus = "ok"
    }
}
