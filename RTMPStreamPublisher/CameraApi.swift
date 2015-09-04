//
//  CameraApi.swift
//  MediaLibDemos
//
//  Created by Symbios on 21/07/2015.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

import Foundation

class CameraApi: RestApiManager {
    static let sharedInstance = CameraApi()
    
    let baseURL = "http://camapi.slb/"
    
    var apiResult: JSON?;
    
    var errors: NSArray?;
    var result: Dictionary<String,String> = [String: String]();
    var status: Bool = false;
    
    init() {
        super.init(baseURL: baseURL)
    }
    
    override init(baseURL:String) {
        super.init(baseURL: baseURL)
    }
    
    func setEndpoint(endpoint:String) -> Void {
        setApiUrl(baseURL+endpoint)
    }
    
    func asyncResult() {
        makeHTTPGetRequest(apiURL)
    }
    func callAPI() {
        apiResult = JSON(url: apiURL)
        let json = apiResult!
        status = json["status"].asBool!
        if(status == true)
        {
            result["token"]             = json["result"]["token"].asString
            result["site_id"]           = json["result"]["site_id"].asString
            result["camera_id"]         = json["result"]["camera_id"].asString
            result["stream_id"]         = json["result"]["stream_id"].asString
            result["stream_server"]     = json["result"]["stream_server"].asString
            result["stream_port"]       = json["result"]["stream_port"].asString
            result["stream_app"]        = json["result"]["stream_app"].asString
            result["room"]              = json["result"]["room"].asString
            result["cookie_session"]    = json["result"]["cookie_session"].asString
            result["active"]            = json["result"]["active"].asString
        }else
        {
            print("ERROR API")
            errors = json["errors"].asArray
        }
    }
    
    func getResult() -> NSDictionary {
        return result
    }
    
    func getErrors() -> NSArray {
        return errors!
    }
    
    func getStatus() -> Bool {
        return status
    }
    
    
    
//    func getResult() -> NSData {
//        let url = NSURL(string: apiURL)
////        let data:JSON = JSON(url: apiURL)
//        let data = NSData( contentsOfURL: url!, options: NSDataReadingOptions.allZeros, error: nil)
//        return data!
////        if((data) != nil)
////        {
////            return JSON2NSDictionary(data!)
////        }
////        return NSDictionary()
////        if(data["status"] === true)
////        {
////            return JSON2NSData( data["result"] )
////        }
////        else
////        {
////            return JSON2NSData( data["errors"] )
////        }
//    }
//    
//    func JSON2NSDictionary(json: NSData) -> NSDictionary {
//        print(json)
//        var error: NSError?
//        let data: AnyObject?
//        let dataDic: NSDictionary
//        if(NSJSONSerialization.isValidJSONObject(json))
//        {
//            data = NSJSONSerialization.JSONObjectWithData(json, options:nil, error: &error)
//            if let dataDic = data as? NSDictionary
//            {
//                return dataDic
//            }
//            dataDic = NSDictionary();
//        } else {
//            print("ERROR")
//            dataDic = NSDictionary();
//        }
//        return dataDic
//    }
}

