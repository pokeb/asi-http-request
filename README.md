ASI-SCS
=======

本SDK为ASIHTTPRequest的一个分支，熟悉ASI的同学可以轻松上手，不熟悉的也没关系，相信看完文档您一定能够运用自如，并且能够对ASI有一个初步的了解。

> * SCS API 的详细内容请查阅：http://open.sinastorage.com/?c=doc&a=api
> * ASIHTTPRequest的详细内容请查阅：http://allseeing-i.com/ASIHTTPRequest/How-to-use

### SDK环境要求 
####系统版本：
> * iOS: 6.0及以上。
> * OSX: 10.8及以上。

####相关配置：
> * 1、下载ASIKit.Framework（你可以手动下载，链接如下；也可以执行步骤(1)—(4)，写脚本由程序自动下载）
>> * Mac OS X：http://sdk.sinastorage.com/ASIKit.framework.zip
>> * iOS：http://sdk.sinastorage.com/ASIKit-iOS.framework.zip
>> * (1)、打开工程，单击XCode侧边栏中的project行，并选择右侧的Build Phase；
>> * (2)、选择项目的Target，在顶部菜单栏选择Editor > Add Build Phase > Add Run Script Build Phase；
>> * (3)、设置Run Script（Mac OS X 与 iOS不同）如下；
>> * (4)、Commond+B编译工程，会自动下载所需的ASIKit.Framework包到工程目录。

> * 2、添加下载的framework到工程
>> * 选择Link Binary With Libraries；
>> * 点击“+”；
>> * 点击“Add Other...”，到工程目录下选择添加ASIKit.Framework。
>> * （或者将下载好的ASIKit.Framework直接拖到xcode工程里的Frameworks分组下；）
>> * （在Add to targets里选中你所要关联的target。）

> * 3、（对于iOS工程）添加其他依赖库
>> * 选择Link Binary With Libraries，点击“+”，添加库：
>> * libxml2.dylib
>> * libz.dylib
>> * SystemConfiguration.framework
>> * MobileCoreServices.framework
>> * CFNetwork.framework
>> * CoreGraphics.framework
>> * Foundation.framework
>> * UIKit.framework
>> * CoreFoundation.framework

> * 4、在所需文件中添加头：ASIKit/ASIKit.h

```shell
# Run Script For Mac OS X

# If not present, download ASIKit archive, extract it and cleanup.
if [ ! -e $SRCROOT/ASIKit.framework ]; then
	rm -rf $SRCROOT/ASIKit
	mkdir $SRCROOT/ASIKit
	cd $SRCROOT/ASIKit
	echo "Downloading ASIKit framework"
	curl -s -O http://sdk.sinastorage.com/ASIKit.framework.zip
	echo "Unzipping ASIKit"
	unzip ASIKit.framework.zip
	mv ASIKit.framework $SRCROOT
	rm -rf $SRCROOT/ASIKit
	echo "ASIKit installed for build"
fi
```

```shell
# Run Script For iOS

# If not present, download ASIKit archive, extract it and cleanup.
    if [ ! -e $SRCROOT/ASIKit.framework ]; then
    rm -rf $SRCROOT/ASIKit
    mkdir $SRCROOT/ASIKit
    cd $SRCROOT/ASIKit
    echo "Downloading ASIKit-iOS framework"
    curl -s -O http://sdk.sinastorage.com/ASIKit-iOS.framework.zip
    echo "Unzipping ASIKit-iOS"
    unzip ASIKit-iOS.framework.zip
    mv ASIKit.framework $SRCROOT
    rm -rf $SRCROOT/ASIKit
    echo "ASIKit installed for build"
fi
```

###快速上手
> * 以下示例为简单明确的介绍SDK使用方法，均采用同步请求方式。
关于请求队列以及异步请求的详细介绍，请参考：【使用异步请求及队列】

####Bucket操作
#####列取bucket
```objective-c
ASIS3ServiceRequest *request = [ASIS3ServiceRequest serviceRequest];
[request setSecretAccessKey:@"YourSecretAccessKey"];
[request setAccessKey:@"YourAccessKey"];
[request startSynchronous];

if (![request error]) {
   NSArray *buckets = [request buckets]; // An array of ASIS3Bucket objects
}
```

#####创建bucket

> * 为每个请求设置相应的accessKey和secretAccessKey是很繁琐的，因此我们可以设置基类（ASIS3Request）的sharedAccessKey和sharedSecretAccessKey。这样下次再发送某一请求时，无需再次设置相应的key，SDK会调用我们设置好的这两个sharedKey。

```objective-c
[ASIS3Request setSharedSecretAccessKey:@"YourSecretAccessKey"];
[ASIS3Request setSharedAccessKey:@"YourAccessKey"];

ASIS3BucketRequest *request = [ASIS3BucketRequest PUTRequestWithBucket:@"my-bucket"];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

#####删除bucket

> * 这里我们无需再次设置相应的accesskey，前面我们已经设置好了两个sharedKey。

```objective-c
ASIS3BucketRequest *request = [ASIS3BucketRequest DELETERequestWithBucket:@"my-bucket"];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

####Object操作
#####列取object
```objective-c
/*示例为列取http://my-bucket.sinastorage.com/images/jpegs中最多50个object*/

ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:@"my-bucket"];
[listRequest setPrefix:@"images/jpegs"];
[listRequest setMaxResultCount:50]; // Max number of results
[listRequest startSynchronous];

if (![listRequest error]) {
   NSLog(@"%@",[listRequest objects]);
}
```

#####获取object信息
```objective-c
/*示例为获取http://my-bucket.sinastorage.com/path/to/the/object的object信息*/

NSString *bucket = @"my-bucket";
NSString *path = @"path/to/the/object";
 
ASIS3ObjectRequest *request = [ASIS3ObjectRequest requestWithBucket:bucket key:path];
[request startSynchronous];

if (![request error]) {
	NSData *data = [request responseData];
} else {
	NSLog(@"%@",[[request error] localizedDescription]);
}
```

#####上传object
```objective-c
NSString *filePath = @"/somewhere/on/disk.txt";
 
ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:@"my-bucket" key:@"path/to/the/object"];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

#####删除object
```objective-c
ASIS3ObjectRequest *request = [ASIS3ObjectRequest DELETERequestWithBucket:@"my-bucket" key:@"path/to/the/object"];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

#####拷贝object
```objective-c
ASIS3ObjectRequest *request = [ASIS3ObjectRequest COPYRequestFromBucket:@"my-bucket" key:@"/path/to/the/object" toBucket:@"my-bucket" key:@"/new/path/to/the/object"];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

#####下载object
```objective-c
ASIS3ObjectRequest *request = [object GETRequest];
NSString *downloadPath = @"path/to/save/yourFile";
[request setDownloadDestinationPath:downloadPath];
[request startSynchronous];

if ([request error]) {
   NSLog(@"%@",[[request error] localizedDescription]);
}
```

####使用HTTPS连接
```objective-c
ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:@"my-bucket" key:@"path/to/the/object"];
[request requestScheme:ASIS3RequestSchemeHTTPS];
```

####使用异步请求及队列
#####异步请求的使用
```objective-c
- (void)listRequest {
   ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:@"my-bucket"];
   [listRequest setDelegate:self];//delegate:ASIHTTPRequestDelegate
   [listRequest startAsynchronous];
}
 
- (void)requestFinished:(ASIHTTPRequest *)request {
   NSString *responseString = [request responseString];
   NSData *responseData = [request responseData];
}
 
- (void)requestFailed:(ASIHTTPRequest *)request {
   NSError *error = [request error];
}
```

#####创建队列
```objective-c
//ASINetworkQueue *queue;
[[self queue] cancelAllOperations];
[self setQueue:[ASINetworkQueue queue]];
```

#####设置队列回调

> * 其中selector可自定义。

```objective-c
 //请求成功
 [[self queue] setRequestDidFinishSelector:@selector(requestDone:)];
 
 //请求失败
 [[self queue] setRequestDidFailSelector:@selector(requestFailed:)];
 
 //请求收到响应
 [[self queue] setRequestDidReceiveResponseHeadersSelector:@selector(requestDidReceiveResponseHeaders:)];
 
 //请求开始
 [[self queue] setRequestDidStartSelector:@selector(requestDidStart:)];
 
 //即将跳转
 [[self queue] setRequestWillRedirectSelector:@selector(requestWillRedirect:)];
 
 //队列结束
 [[self queue] setQueueDidFinishSelector:@selector(queueDidFinish:)];
 
 /*默认的，若队列中某一请求失败，整个队列会停止，并取消其他请求。若如下设置为NO，则其他请求仍会继续发送*/
 [queue setShouldCancelAllRequestsOnFailure:NO];
```

#####启动队列
```objective-c
 /*队列只需启动一次，此后加入队列的请求会按顺序执行*/
 [[self queue] go];
```

#####添加异步请求
```objective-c
 ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:@"my-bucket"];
 ...
 [[self queue] addOperation:request];
```

#####取消异步请求
```objective-c
 /*取消某一请求后，队列会执行请求失败的回调*/
 /*同时，若shouldCancelAllRequestsOnFailure == YES，队列中的其他请求也将被取消*/
 [request cancel];
 [request clearDelegatesAndCancel];
```

#####example

> * 本示例较为完整的展示了如何使用队列及异步请求获取object列表并下载。

```objective-c
- (void)download25ImagesToDisk {
   
   //创建队列
   [[self queue] cancelAllOperations];
   [self setQueue:[ASINetworkQueue queue]];
 
   //获取图片列表
   ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:@"my-bucket"];
   [listRequest setPrefix:@"images/jpegs"];
   [listRequest setMaxResultCount:25];
   [listRequest setDelegate:self];

   //设置回调
   [listRequest setDidFinishSelector:@selector(finishedDownloadingImageList:)];
   [listRequest setDidFailSelector:@selector(failedDownloadingImageList:)];

   //加入队列
   [[self queue] addOperation:listRequest];
}
 
- (void)failedDownloadingImageList:(ASIHTTPRequest *)listRequest {
   
   NSLog(@"Failed downloading a list of images because '%@'", [[listRequest error] localizedDescription]);
}
 
- (void)finishedDownloadingImageList:(ASIHTTPRequest *)listRequest {
   
   //获取列表成功后，开始下载
   [[self queue] reset];
   [[self queue] setRequestDidFinishSelector:@selector(requestDone:)];
   [[self queue] setRequestDidFailSelector:@selector(requestFailed:)];
   [[self queue] setDelegate:self];
 
   int i=0;
   for (ASIS3BucketObject *object in [listRequest objects]) {
      ASIS3ObjectRequest *request = [object GETRequest];
      NSString *downloadPath = [NSString stringWithFormat:@"/Users/ben/Desktop/images/%hi.jpg",i];
      [request setDownloadDestinationPath:downloadPath];
      [[self queue] addOperation:request];
      i++;
   }
 
   //启动队列
   [[self queue] go];
}
 
- (void)requestDone:(ASIS3Request *)request {
   NSLog(@"Finished downloading an image");
}
 
- (void)requestFailed:(ASIS3Request *)request {
   NSLog(@"Download error: %@",[[request error] localizedDescription]);
}
```

####进度跟踪

> * 对于单个请求，可通过设置delegate获取进度信息；
> * 对于请求队列，可通过设置队列的delegate获取全部请求的进度信息；
> * 两者可同时获得；
> * 可通过设置showAccurateProgress == YES来获取精确进度；
> * 详情请参考：http://allseeing-i.com/ASIHTTPRequest/How-to-use#tracking_progress

#####上传进度（单个请求）
```objective-c
//myProgressIndicator is a UIProgressView for iOS
//myProgressIndicator is a NSProgressIndicator for OS X

ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
[request setUploadProgressDelegate:myProgressIndicator];
[request startSynchronous];
NSLog(@"Max: %f, Value: %f", [myProgressIndicator maxValue],[myProgressIndicator doubleValue]);
```

#####上传进度（队列）
```objective-c
- (void)uploadSomethingFiveTimes:(NSURL *)url
{
   [myQueue cancelAllOperations];
   [myQueue setUploadProgressDelegate:myProgressIndicator];
   [myQueue setDelegate:self];
   [myQueue setRequestDidFinishSelector:@selector(queueComplete:)];
   int i;
   for (i=0; i<5; i++) {
      ASIHTTPRequest *request = [ASIFormDataRequest requestWithURL:url];
      [request setPostBody:[@"Some data" dataUsingEncoding:NSUTF8StringEncoding]];
      [myQueue addOperation:request];
   }
   [myQueue go];
}
 
- (void)queueComplete:(ASINetworkQueue *)queue
{
   NSLog(@"Max: %f, Value: %f", [myProgressIndicator maxValue],[myProgressIndicator doubleValue]);
}
```

#####下载进度（单个请求）
```objective-c
 ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
[request setDownloadProgressDelegate:myProgressIndicator];
[request startSynchronous];
NSLog(@"Max: %f, Value: %f", [myProgressIndicator maxValue],[myProgressIndicator doubleValue]);
```

#####下载进度（队列）
```objective-c
- (void)fetchThisURLFiveTimes:(NSURL *)url
{
   [myQueue cancelAllOperations];
   [myQueue setDownloadProgressDelegate:myProgressIndicator];
   [myQueue setDelegate:self];
   [myQueue setRequestDidFinishSelector:@selector(queueComplete:)];
   int i;
   for (i=0; i<5; i++) {
      ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
      [myQueue addOperation:request];
   }
   [myQueue go];
}
 
- (void)queueComplete:(ASINetworkQueue *)queue
{
   NSLog(@"Value: %f", [myProgressIndicator progress]);
}
```