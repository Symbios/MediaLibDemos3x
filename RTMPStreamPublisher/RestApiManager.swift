//
//  RestAPI.swift
//  MediaLibDemos
//
//  Created by Symbios on 21/07/2015.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

import Foundation

class RestApiManager: NSObject {
    
    var apiURL : String
    var jsonData = JSON(string: "")
    
    init(baseURL:String) {
        self.apiURL = baseURL
    }
    
    func setApiUrl(baseURL:String) -> Void {
        self.apiURL = baseURL
    }
    
    func makeHTTPGetRequest(path: String) {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {
            data, response, error -> Void in
            let json:JSON = JSON(data: data)
//            onCompletion(json, error)
            if(error == nil)
            {
                self.jsonData = json
            }else
            {
                NSLog("Error: \(error.localizedDescription)")
            }
        })
        task.resume()
    }
    
    func sendRequest() -> JSON {
        var request = NSURLRequest(URL: NSURL(string: apiURL)!)
        var response: NSURLResponse?
        var error: NSErrorPointer = nil
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error)
        
        if(error != nil)
        {
            return JSON(string: "{\"valid\": false, \"error\": \"\(error)\"")
        }
        return JSON(data: data!)
    }
}

class Request : NSObject {
}