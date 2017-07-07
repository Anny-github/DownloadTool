
//
//  DownloadTool.m
//  ThreadTest
//
//  Created by anne on 2017/6/29.
//  Copyright © 2017年 anne. All rights reserved.
//

#import "DownloadTool.h"
#import "NSString+urlToFileName.h"

@interface DownloadTool ()

@property(nonatomic,strong)NSOperationQueue *operationQueue;
@property(nonatomic,copy)CancelOperation cancelOperation;
@property(nonatomic,strong)NSMutableArray *waitOperations;
@property(nonatomic,strong)NSLock *lock;


@end

@implementation DownloadTool

static DownloadTool *downloadTool = nil;

-(void)setMaxConcurrentNum:(NSInteger)maxConcurrentNum{
    if (_maxConcurrentNum == maxConcurrentNum) {
        return;
    }
    _maxConcurrentNum = maxConcurrentNum;
    self.operationQueue.maxConcurrentOperationCount = maxConcurrentNum;
    
}

+ (instancetype)shared{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadTool = [[DownloadTool alloc]init];
        downloadTool.maxConcurrentNum = 2;
        downloadTool.operationQueue = [[NSOperationQueue alloc]init];
        downloadTool.operationQueue.maxConcurrentOperationCount = downloadTool.maxConcurrentNum;
        downloadTool.waitOperations = [NSMutableArray array];
        downloadTool.lock = [[NSLock alloc]init];
    });
    return downloadTool;
}

//走这个方法 必定是点击的下载   (暂停就直接cancel，再次继续下载也是重新分配线程 )
- (void)addDownloadUrl:(NSString*)url progress:(Progress)progress cancelDownload:(CancelOperation)cancelOperation downloadFinish:(DownloadFinish)downloadFinish{
    
    self.cancelOperation = cancelOperation;
    //已存在任务
    DownloadOperation *opera = [self operationWithUrl:url];
    if (opera) {
        [opera addUrl:url progress:progress downloadFinish:downloadFinish];
        [opera addObserver:self forKeyPath:@"finish" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(url)];
        return;
    }
    //新任务
    BOOL wating = YES;
    if (self.operationQueue.operations.count == self.maxConcurrentNum) { //队列中线程已达最多大并发数
        for (DownloadOperation *operation in self.operationQueue.operations) {
            if (operation.finish == YES) { //有空闲线程
                wating = NO;
                [operation addUrl:url progress:progress downloadFinish:downloadFinish];
                [operation addObserver:self forKeyPath:@"finish" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(url)];

                [self deleteWaitOperationOfUrl:url];
                break;
            }
        }
        if (wating) {  //无空闲线程，加入等待数组
            DownloadOperation *operation = [[DownloadOperation alloc]initWithUrl:url progress:progress downloadFinish:downloadFinish];
            [self.waitOperations addObject:operation];
        }
    }else{  //没达到最大并发数，直接添加
        DownloadOperation *operation = [[DownloadOperation alloc]initWithUrl:url progress:progress downloadFinish:downloadFinish];
        [self.operationQueue addOperation:operation];
        [operation addObserver:self forKeyPath:@"finish" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(url)];
    }
    
}
//将waitOperation从等待数组中删除
- (void)deleteWaitOperationOfUrl:(NSString*)url{
    for (DownloadOperation *operation in self.waitOperations) {
        if ([operation.url isEqualToString:url]) {
            [self.waitOperations removeObject:operation];
        }
    }

}

//观察者在主线程  安全
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{

    if ([keyPath isEqualToString:@"finish"]) {
        NSString *url = (__bridge NSString *)(context);
        
        if ([change[@"new"] integerValue] == 1) {

            NSLog(@"下载完毕========%@",url);

           //筛查如果等待队列有已下载的清除
            [self deleteWaitOperationOfUrl:url];
            
            if (self.waitOperations.count>0) {
                DownloadOperation *operation = [self operationWithUrl:url];
                
                DownloadOperation *waitOperation = self.waitOperations[0];
                [operation addUrl:waitOperation.url progress:waitOperation.progress downloadFinish:waitOperation.downloadFinish];
                operation.finish = NO;

                [operation addObserver:self forKeyPath:@"finish" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(waitOperation.url)];
                [self.waitOperations removeObjectAtIndex:0];
                NSLog(@"移除等待的operation=======%@",waitOperation);
            }
            
        }
    }

}

- (DownloadOperation*)operationWithUrl:(NSString*)url{
    for (DownloadOperation *operation in self.operationQueue.operations) {
        if ([operation.url isEqualToString:url]) {
            return operation;
        }
    }
    return nil;
}

- (void)pauseDownloadUrl:(NSString*)url{
    DownloadOperation *operation = [self operationWithUrl:url];
    [operation pauseDownload];
}

- (void)cancelDownloadUrl:(NSString*)url{
    DownloadOperation *operation = [self operationWithUrl:url];
    [operation cancelDownload];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cancelOperation(operation);

    });
}

-(void)continueDownloadUrl:(NSString*)url{
    DownloadOperation *operation = [self operationWithUrl:url];
    [operation continueDownload];
}

- (void)cancelAllDownload{
    
    for (DownloadOperation *operation in self.operationQueue.operations) {
        [operation removeObserver:self forKeyPath:@"finish"];
        [operation cancelDownload];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.cancelOperation(operation);
            
        });

    }
    
}
#pragma mark --缓存长度
- (void)cacheForUrl:(NSString*)url progress:(float)progress{
    
    [[NSUserDefaults standardUserDefaults]setValue:[NSString stringWithFormat:@"%f",progress] forKey:url];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (float)progressHaveDownloadForUrl:(NSString*)url{
    
    return [[[NSUserDefaults standardUserDefaults]valueForKey:url] floatValue];

}

- (void)deleteCacheUrl:(NSString*)url{
    NSString *destinationPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    destinationPath = [destinationPath stringByAppendingPathComponent:@"fileCache"];
    destinationPath =  [destinationPath stringByAppendingString:[url fileName]];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [[NSUserDefaults standardUserDefaults]setValue:@"0" forKey:url];
    [[NSUserDefaults standardUserDefaults]synchronize];

    if ([fileMgr fileExistsAtPath:destinationPath]) {
        [fileMgr removeItemAtPath:destinationPath error:nil];
    }
}

@end
