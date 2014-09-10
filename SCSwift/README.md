SCSwift
=======

新浪云存储（SCS）for Swift。

### SDK环境要求 
####系统版本：
> * iOS: 8.0及以上。

####相关配置：
> * 1、下载SCSwift.framework（你可以手动下载，链接如下；也可以执行步骤(1)—(4)，写脚本由程序自动下载）
>> * http://sdk.sinastorage.cn/SCSwift.framework.zip
>> * (1)、打开工程，单击XCode侧边栏中的project行，并选择右侧的Build Phase；
>> * (2)、选择项目的Target，在顶部菜单栏选择Editor > Add Build Phase > Add Run Script Build Phase；
>> * (3)、设置Run Script如下；
>> * (4)、Commond+B编译工程，会自动下载所需的SCSwift.framework包到工程目录。

> * 2、添加下载的framework到工程
>> * 选择Link Binary With Libraries；
>> * 点击“+”；
>> * 点击“Add Other...”，到工程目录下选择添加SCSwift.Framework；
>> * （或者将下载好的SCSwift.Framework直接拖到xcode工程里的Frameworks分组下；）
>> * （在Add to targets里选中你所要关联的target。）
>> * 选择Copy Files，设置Destination为Frameworks；
>> * 点击“+”，选择SCSwift.framework。

> * 3、在所需文件中添加：import SCSwift

```shell
# If not present, download SCSwift archive, extract it and cleanup.
    if [ ! -e $SRCROOT/SCSwift.framework ]; then
    rm -rf $SRCROOT/SCSwift
    mkdir $SRCROOT/SCSwift
    cd $SRCROOT/SCSwift
    echo "Downloading SCSwift framework"
    curl -s -O http://sdk.sinastorage.cn/SCSwift.framework.zip
    echo "Unzipping SCSwift"
    unzip SCSwift.framework.zip
    mv SCSwift.framework $SRCROOT
    rm -rf $SRCROOT/SCSwift
    echo "SCSwift installed for build"
fi
```


###快速上手
####初始化
#####方法1：
```Swift
//全局生效
SCS.GlobalConfig(accessKey:"YOUR ACCESS KEY", secretKey:"YOU SECRET KEY", useSSL:false, maxConcurrentOperationCount:5)

//useSSL缺省为false，最大并发数maxConcurrentOperationCount缺省为3
```

#####方法2：
```Swift
//当前实例生效
var scs = SCS(accessKey:"YOUR ACCESS KEY", secretKey:"YOU SECRET KEY", useSSL:true)
```

#####方法3：
```Swift
//方法3 全局设置，并使实例生效
SCS.GlobalConfig(accessKey:"YOUR ACCESS KEY", secretKey:"YOU SECRET KEY", useSSL:true)
var scs = SCS()
```

####Bucket操作
#####列取bucket
```Swift
SCS.sharedInstance.listBuckets(
	finished: { request in
		let list = NSString(format:"%@", request.buckets) as String
		println(list)
	},
	failed: { request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	}
)
```

#####创建bucket
```Swift
SCS.sharedInstance.createBucket(
	bucket:"BucketName",
	finished:{request in
		let list = NSString(format:"%@ created", request.bucket) as String
		println(list)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	}
)
```

#####删除bucket
```Swift
SCS.sharedInstance.deleteBucket(
	bucket:"BucketName",
	finished:{request in
		let bucket = NSString(format:"%@ deleted", request.bucket) as String
		println(bucket)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
        println(error)
	}
)
```

####Object操作
#####列取object
```Swift
SCS.sharedInstance.listObjects(
	param: ["bucket":"BucketName" as String,
			"maxKeys":3 as Int32,
			"prefix":"YourPrefix/" as String,
			"delimiter":"/" as String,
			"marker":"" as String],
	finished:{request in
		let objects = NSString(format:"%@", request.objects) as String
		println(objects)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	}
)
```

#####上传object
```Swift
let filePath:String = "YourFilePath"

SCS.sharedInstance.uploadObject(
	param: ["filePath":filePath,
			"bucket":"BucketName",
			"key":"FileKey",
			"accessPolicy":AccessPolicy.access_private.toRaw()],
	finished:{request in
		let object = NSString(format:"%@ uploaded", request.key) as String
		println(object)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	},
	progress:{request, sentSize, totalSize in
		println("uploaded bytes: \(sentSize) in total: \(totalSize)")
	}
)
```

#####下载object
```Swift
let downloadPath = "YourDownloadPath"
            
SCS.sharedInstance.downloadObject(
	param: ["bucket":"BucketName",
			"key":"FileKey",
			"downloadDestinationPath":downloadPath],
	finished:{request in
		let object = NSString(format:"%@ downloaded", request.downloadDestinationPath) as String
		println(object)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	},
	progress:{request, sentSize, totalSize in
		println("downloaded bytes: \(sentSize) in total: \(totalSize)")
	}
)
```

#####删除object
```Swift
SCS.sharedInstance.deleteObject(
	param: ["bucket":"BucketName",
			"key":"FileKey"],
	finished:{request in
		let object = NSString(format:"%@ deleted", request.key) as String
		println(object)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	}
)
```

#####拷贝object
```Swift
SCS.sharedInstance.copyObject(
	param: ["srcBucket":"SourceBucketName",
			"srcKey":"SourceFileKey",
			"desBucket":"DestinationBucketName",
			"desKey":"DestinationFileKey"],
	finished:{request in
		let object = NSString(format:"Object %@ has been copied to %@", request.sourceKey, request.key) as String
		println(object)
	},
	failed:{request in
		let error = NSString(format:"%@", request.error) as String
		println(error)
	}
)
```
