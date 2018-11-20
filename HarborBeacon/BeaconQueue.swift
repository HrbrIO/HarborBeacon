//
//  BeaconQueue.swift
//  BeaconQueue
//
//  Created by Scott Matheson on 11/15/18.
//  Copyright © 2018 HarborIO, Inc. All rights reserved.
//
//

import Foundation

public class BeaconQueue {
    
    // MARK: - Properties
    private static let BEACON_URL = URL(string:"https://harbor-services.herokuapp.com/beacon")

    private static func swiftVersionId() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version).\(build)"
    }
    
    private static var sharedBeaconQueue: BeaconQueue = {
        let beaconQueue = BeaconQueue(baseURL: BeaconQueue.BEACON_URL!)
        
        // Configuration
        // ...
        
        return beaconQueue
    }()
    
    // MARK: -
    
    let baseURL: URL
    let session: URLSession
    let apiKey: String?
    let deviceID: String
    let bundleID: String
    let nativeAppID: String
    
    // Initialization
    
    private init(baseURL: URL) {
        self.baseURL  = baseURL
        self.session  = URLSession.shared
        self.bundleID = Bundle.main.bundleIdentifier!
        self.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "????????-????-????-????-????????????"
        
        if let hrbr = Bundle.main.object(forInfoDictionaryKey: "Harbor") as? [String:Any] {
            self.apiKey = hrbr["APIKey"] as? String
        } else {
            self.apiKey = ""
        }
        self.nativeAppID = self.bundleID + ":" + BeaconQueue.swiftVersionId()
    }
    
    // MARK: - Accessors
    
    public class func shared() -> BeaconQueue {
        return sharedBeaconQueue
    }
    
    private func buildRequest(_ msgType : String, appVer : String, beaconVer : String, time : TimeInterval? ) -> URLRequest {

        let msec = time ?? Date().timeIntervalSince1970 * 1000

        var request = URLRequest(url: self.baseURL)
        request.httpMethod = "POST"
        request.setValue("\(Int(msec))",        forHTTPHeaderField:"datatimestamp")
        
        request.setValue(msgType,               forHTTPHeaderField:"beaconmessagetype")

        request.setValue(appVer,                forHTTPHeaderField:"appversionid")
        request.setValue(beaconVer,             forHTTPHeaderField:"beaconversionid")

        request.setValue(self.apiKey,           forHTTPHeaderField:"apikey")
        request.setValue(self.nativeAppID,      forHTTPHeaderField:"appversionidx")
        request.setValue(self.deviceID,         forHTTPHeaderField:"beaconinstanceid")
        
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue("application/json",    forHTTPHeaderField: "Accept")
        
        return request
    }
    
    public func transmit(_ messageType : String, data : [String:Any], appVer : String, beaconVer : String) {
        
        var jsonData : Data?
        
        if JSONSerialization.isValidJSONObject(data) {
            jsonData = try? JSONSerialization.data(withJSONObject: data,
                                                   options: [])
        }

        let req = self.buildRequest(messageType,
                                    appVer: appVer,
                                    beaconVer: beaconVer,
                                    time: Date().timeIntervalSince1970 * 1000)
        
        let task = self.session.uploadTask(with: req,
                                           from: jsonData)
        { data, response, error in
         
            if let error = error {
                //print ("error: \(error)")
                print("Error: \(String(describing: error))")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...201).contains(httpResponse.statusCode) else {
                    print("Bad response: \(String(describing: response))") // http url response
                    return
            }

            if let hR = response as? HTTPURLResponse {
                let s = HTTPURLResponse.localizedString(forStatusCode:hR.statusCode)
                print("Status is \(hR.statusCode) \(s)")
            }

            //if httpResponse.statusCode == 201 {
            //    print("OK")
            //}
            
        }
        task.resume()
    }
    
}
