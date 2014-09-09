//
//  SCSwift.swift
//  SCSwift
//
//  Created by Littlebox222 on 14-9-5.
//  Copyright (c) 2014年 Littlebox222. All rights reserved.
//

import Foundation


public enum AccessPolicy:String {
    case access_private = "private",
    access_public_read = "public-read",
    access_public_read_write = "public-read-write",
    access_authenticated_read = "authenticated-read"
}

public class SCSServiceRequest:ASIS3ServiceRequest {}
public class SCSBucketRequest:ASIS3BucketRequest {}
public class SCSObjectRquest:ASIS3ObjectRequest {}

public class SCS {
    
    var config:Dictionary<String,Any!>!
    var globleConfig:Dictionary<String,Any!>! = [:]
    
    public class var sharedInstance: SCS {
        
    struct Static {
        static var instance: SCS?
        static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = SCS()
        }
        
        return Static.instance!
    }
    
    public class func GlobalConfig(accessKey:String!=nil, secretKey:String!=nil, useSSL:Bool!=false, maxConcurrentOperationCount:Int! = 3) {
        
        SCS.sharedInstance.globleConfig["accessKey"] = accessKey
        SCS.sharedInstance.globleConfig["secretKey"] = secretKey
        SCS.sharedInstance.globleConfig["useSSL"] = useSSL
        SCS.sharedInstance.globleConfig["maxConcurrentOperationCount"] = maxConcurrentOperationCount
    }
    
    internal func configureRequest(request:ASIS3Request) {
        
        var cfg:Dictionary<String,Any!>!
        
        if (self.config == nil) {
            cfg = SCS.sharedInstance.globleConfig
        }else {
            cfg = self.config
        }
        
        if (cfg["accessKey"] != nil) {
            request.accessKey = cfg["accessKey"] as String
        }
        
        if (cfg["secretKey"] != nil) {
            request.secretAccessKey = cfg["secretKey"] as String
        }
        
        if (cfg["useSSL"] != nil && cfg["useSSL"] as Bool) {
            request.requestScheme = ASIS3RequestSchemeHTTPS
        }else {
            request.requestScheme = ASIS3RequestSchemeHTTP
        }
        
        if (cfg["maxConcurrentOperationCount"] != nil) {
            ASIHTTPRequest.sharedQueue().maxConcurrentOperationCount = cfg["maxConcurrentOperationCount"] as Int
        }
    }
    
    //初始化
    public init (accessKey:String! = nil, secretKey:String! = nil, useSSL:Bool! = false, maxConcurrentOperationCount:Int! = 3) {
        
        if (accessKey != nil || secretKey != nil) {
            self.config = [:]
            self.config["accessKey"] = accessKey
            self.config["secretKey"] = secretKey
            self.config["useSSL"] = useSSL
            self.config["maxConcurrentOperationCount"] = maxConcurrentOperationCount
        }
    }
    
    
    //Service
    public func listBuckets(started:((SCSServiceRequest)->Void)! = nil,
        finished:((SCSServiceRequest)->Void)! = nil,
        failed:((SCSServiceRequest)->Void)! = nil,
        headerReceived:((SCSServiceRequest)->Void)! = nil,
        redirected:((SCSServiceRequest)->Void)! = nil)
    {
        
        let request = SCSServiceRequest.serviceRequest() as SCSServiceRequest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    
    //Bucket
    public func createBucket(#bucket:String, started:((SCSBucketRequest)->Void)! = nil,
        finished:((SCSBucketRequest)->Void)! = nil,
        failed:((SCSBucketRequest)->Void)! = nil,
        headerReceived:((SCSBucketRequest)->Void)! = nil,
        redirected:((SCSBucketRequest)->Void)! = nil)
    {
        
        let request = SCSBucketRequest.PUTRequestWithBucket(bucket as NSString) as SCSBucketRequest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    public func deleteBucket(#bucket:String, started:((SCSBucketRequest)->Void)! = nil,
        finished:((SCSBucketRequest)->Void)! = nil,
        failed:((SCSBucketRequest)->Void)! = nil,
        headerReceived:((SCSBucketRequest)->Void)! = nil,
        redirected:((SCSBucketRequest)->Void)! = nil)
    {
        
        let request = SCSBucketRequest.DELETERequestWithBucket(bucket as NSString) as SCSBucketRequest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    //Object
    public func listObjects(#param:Dictionary<String, Any!>, started:((SCSBucketRequest)->Void)! = nil,
        finished:((SCSBucketRequest)->Void)! = nil,
        failed:((SCSBucketRequest)->Void)! = nil,
        headerReceived:((SCSBucketRequest)->Void)! = nil,
        redirected:((SCSBucketRequest)->Void)! = nil)
    {
        
        let request = SCSBucketRequest.requestWithBucket(param["bucket"] as String) as SCSBucketRequest
        request.maxResultCount = param["maxKeys"] as Int32
        request.prefix = param["prefix"]! as String
        request.delimiter = param["delimiter"]! as String
        request.marker = param["marker"]! as String
        
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    public func uploadObject(#param:Dictionary<String, String>, started:((SCSObjectRquest)->Void)! = nil,
        finished:((SCSObjectRquest)->Void)! = nil,
        failed:((SCSObjectRquest)->Void)! = nil,
        headerReceived:((SCSObjectRquest)->Void)! = nil,
        redirected:((SCSObjectRquest)->Void)! = nil,
        progress:((SCSObjectRquest, UInt64, UInt64)->Void)! = nil)
    {
        
        let request = SCSObjectRquest.PUTRequestForFile(param["filePath"], withBucket:param["bucket"], key:param["key"]) as SCSObjectRquest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        if (progress != nil) {
            request.setBytesSentBlock({sentSize,total in
                progress(request, sentSize, total)
            })
        }
        
        request.timeOutSeconds = 60
        request.accessPolicy = param["accessPolicy"]
        request.addRequestHeader("Expect", value:"100-continue")
        request.showAccurateProgress = true
        
        request.startAsynchronous()
    }
    
    public func downloadObject(#param:Dictionary<String, String>, started:((SCSObjectRquest)->Void)! = nil,
        finished:((SCSObjectRquest)->Void)! = nil,
        failed:((SCSObjectRquest)->Void)! = nil,
        headerReceived:((SCSObjectRquest)->Void)! = nil,
        redirected:((SCSObjectRquest)->Void)! = nil,
        progress:((SCSObjectRquest, UInt64, UInt64)->Void)! = nil)
    {
        
        let request = SCSObjectRquest.requestWithBucket(param["bucket"], key: param["key"]) as SCSObjectRquest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        if (progress != nil) {
            request.setBytesReceivedBlock({sentSize,total in
                progress(request, sentSize, total)
            })
        }
        
        request.downloadDestinationPath = param["downloadDestinationPath"]
        request.showAccurateProgress = true
        request.startAsynchronous()
    }
    
    public func copyObject(#param:Dictionary<String, String>, started:((SCSObjectRquest)->Void)! = nil,
        finished:((SCSObjectRquest)->Void)! = nil,
        failed:((SCSObjectRquest)->Void)! = nil,
        headerReceived:((SCSObjectRquest)->Void)! = nil,
        redirected:((SCSObjectRquest)->Void)! = nil)
    {
        
        let request = SCSObjectRquest.COPYRequestFromBucket(param["srcBucket"], key: param["srcKey"], toBucket: param["desBucket"], key: param["desKey"]) as SCSObjectRquest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    public func deleteObject(#param:Dictionary<String, String>, started:((SCSObjectRquest)->Void)! = nil,
        finished:((SCSObjectRquest)->Void)! = nil,
        failed:((SCSObjectRquest)->Void)! = nil,
        headerReceived:((SCSObjectRquest)->Void)! = nil,
        redirected:((SCSObjectRquest)->Void)! = nil)
    {
        
        let request = SCSObjectRquest.DELETERequestWithBucket(param["bucket"], key: param["key"]) as SCSObjectRquest
        self.configureRequest(request)
        
        if (started != nil) {
            request.setStartedBlock({started(request)})
        }
        if (finished != nil) {
            request.setCompletionBlock({finished(request)})
        }
        if (failed != nil) {
            request.setFailedBlock({failed(request)})
        }
        if (headerReceived != nil) {
            request.setHeadersReceivedBlock({header in headerReceived(request)})
        }
        if (redirected != nil) {
            request.setRequestRedirectedBlock({redirected(request)})
        }
        
        request.startAsynchronous()
    }
    
    //ACL
}