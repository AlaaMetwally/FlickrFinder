//
//  GCDBlackBox.swift
//  FlickrFinder
//
//  Created by Geek on 2/2/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping() -> Void){
    DispatchQueue.main.async {
        updates()
    }
}
