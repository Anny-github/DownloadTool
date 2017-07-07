//
//  DownloadTool.h
//  ThreadTest
//
//  Created by anne on 2017/6/29.
//  Copyright © 2017年 anne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadOperation.h"


@interface DownloadTool : NSObject

@property(nonatomic,assign)NSInteger maxConcurrentNum;

+ (instancetype)shared;

- (void)addDownloadUrl:(NSString*)url progress:(Progress)progress cancelDownload:(CancelOperation)cancelOperation downloadFinish:(DownloadFinish)downloadFinish;

- (void)pauseDownloadUrl:(NSString*)url;
- (void)cancelDownloadUrl:(NSString*)url;
- (void)continueDownloadUrl:(NSString*)url;
- (void)cancelAllDownload;


//缓存数据
- (void)cacheForUrl:(NSString*)url progress:(float)progress;
- (float)progressHaveDownloadForUrl:(NSString*)url;
- (void)deleteCacheUrl:(NSString*)url;



@end
