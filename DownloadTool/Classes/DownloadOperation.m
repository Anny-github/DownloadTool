//
//  DownloadOperation.m
//  ThreadTest
//
//  Created by anne on 2017/6/29.
//  Copyright © 2017年 anne. All rights reserved.
//

#import "DownloadOperation.h"
#import "NSString+urlToFileName.h"
#import "DownloadTool.h"

@interface DownloadOperation ()<NSURLSessionDelegate,NSURLSessionDataDelegate>
{
 
    NSURLSessionDownloadTask *_downTask;
    NSURLSession *_session;
    NSURLSessionDataTask *_dataTask;
    
    /** 当前已经下载的文件的长度 */
    long long  currentFileSize;
    /** 输出流 */
    NSOutputStream *outputStream;
    
     /** 不变的文件总长度 */
    long long  fileTotalSize; //如果是resumeData断点下载，代理方法中的response的fileTotalSize就是此次需要下载的总长度，所以文件总长度 就要是已下载长度+fileTotalSize，看下面代理方法
    
}
@end

@implementation DownloadOperation
-(long long)fileSize:(NSString*)path{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
   long long fileSize =  [[fileMgr attributesOfItemAtPath:path error:nil] fileSize];
    return fileSize;
}

-(NSString*)cachePath:(NSString*)remoteUrl{
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cachePath = [cachePath stringByAppendingPathComponent:@"fileCache"];
    
    return [cachePath stringByAppendingString:[remoteUrl fileName]];
    
}

-(NSString*)destinationPath:(NSString*)remoteUrl{
    NSString *destinationPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    destinationPath = [destinationPath stringByAppendingPathComponent:@"fileCache"];
    return [destinationPath stringByAppendingString:[remoteUrl fileName]];
    
}
-(instancetype)initWithUrl:(NSString*)remoteUrl progress:(Progress)progress downloadFinish:(DownloadFinish)downloadFinish{
    if (self = [super init]) {
        
        self.finish = NO;

        self.url = remoteUrl;
        self.progress = progress;
        
        self.downloadFinish = downloadFinish;

        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        currentFileSize = [self fileSize:[self cachePath:remoteUrl]];
        fileTotalSize = 0;
        
    }
    return self;
}

-(void)addUrl:(NSString*)remoteUrl progress:(Progress)progress downloadFinish:(DownloadFinish)downloadFinish{
    if (_downTask) {
        [_downTask cancel];
    }
    self.finish = NO;
    self.url = remoteUrl;
    self.progress = progress;
    self.downloadFinish = downloadFinish;
    currentFileSize = [self fileSize:[self cachePath:remoteUrl]];
    fileTotalSize = 0;

    [self main];

}

- (void)start {
    
    //第一步就要检测是否被取消了，如果取消了，要实现相应的KVO
    if ([self isCancelled]) {
        
        [self willChangeValueForKey:@"isFinished"];
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    //如果没被取消，开始执行任务
    [self willChangeValueForKey:@"isExecuting"];
    //开启新的线程
    [self main];

    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main { //具体的下载任务
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath:[self destinationPath:self.url]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadFinish([self destinationPath:self.url],YES);
            self.finish = YES;
        });
        return;
    }
    NSData *resumeData;
    if ([filemgr fileExistsAtPath:[self cachePath:self.url]]) {
        resumeData = [NSData dataWithContentsOfFile:[self cachePath:self.url]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-",currentFileSize];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        _dataTask = [_session dataTaskWithRequest:request];
//        _downTask = [_session  downloadTaskWithResumeData:resumeData];

    }else{
        _dataTask = [_session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
//        _downTask = [_session  downloadTaskWithURL:[NSURL URLWithString:self.url]];

    }

    //开始下载
//    [_downTask resume];
    [_dataTask resume];
    
}

#pragma mark --控制下载的方法--
- (void)pauseDownload{

    [_dataTask cancel];
    self.finish = YES;
//    [_downTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
//        //将下载的内容移入缓存文件夹
////        [resumeData writeToFile:[self cachePath:self.url] atomically:YES];
//        self.finish = YES;
//
//    }];
}

- (void)cancelDownload{
    [_dataTask cancel];
    self.finish = YES;
    [outputStream close];
    
}

- (void)continueDownload{
    [self main];
//    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    self.finish = NO;
    [outputStream close];

}


#pragma mark  --NSURLSessionDataDelegate---
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if ((task.state == NSURLSessionTaskStateCompleted) && (error == nil)) {
        [[DownloadTool shared]cacheForUrl:self.url progress:1];
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        [fileMgr moveItemAtPath:[self cachePath:self.url] toPath:[self destinationPath:self.url] error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadFinish([self destinationPath:self.url],YES);
            NSLog(@"finish========%@",self.url);
            self.finish = YES;

        });
    }
}

-(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler{
        outputStream = [[NSOutputStream alloc] initToFileAtPath:[self cachePath:self.url] append:YES];
        [outputStream open];
        if (fileTotalSize == 0) {
            long  long  totalSize = response.expectedContentLength;
           // 别忘了设置总长度
            fileTotalSize = totalSize + currentFileSize;
        }
       // 允许收到响应
       completionHandler(NSURLSessionResponseAllow);}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{

}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
   [outputStream write:data.bytes maxLength:data.length];
     // 将写入的数据的长度计算加进当前的已经下载的数据长度
    currentFileSize += data.length;
   // 设置进度值
//    NSLog(@"当前文件长度：%lf，总长度：%lf",currentFileSize * 1.0,fileTotalSize * 1.0);
//    NSLog(@"进度值: %lf",currentFileSize * 1.0 / fileTotalSize);

    NSProgress *progress = [NSProgress progressWithTotalUnitCount:fileTotalSize];
    progress.completedUnitCount = currentFileSize;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progress(progress);
        
    });
    [[DownloadTool shared]cacheForUrl:self.url progress:(float)progress.completedUnitCount/(float)progress.totalUnitCount];
}


@end
