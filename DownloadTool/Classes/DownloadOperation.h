//
//  DownloadOperation.h
//  ThreadTest
//
//  Created by anne on 2017/6/29.
//  Copyright © 2017年 anne. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^DownloadFinish)(NSString *destination,BOOL  success);
typedef void(^Progress)(NSProgress *progress);
typedef void(^CancelOperation)(NSOperation* operation);

@class DownloadTool;
@interface DownloadOperation : NSOperation

@property(nonatomic,copy)NSString *url; //识别是哪个downOperation；
@property(nonatomic,assign)BOOL finish; //finish表示此下载暂停或者完成
@property(nonatomic,copy)DownloadFinish downloadFinish;
@property(nonatomic,copy)Progress progress;

-(instancetype)initWithUrl:(NSString*)remoteUrl progress:(Progress)progress downloadFinish:(DownloadFinish)downloadFinish;
-(void)addUrl:(NSString*)remoteUrl progress:(Progress)progress downloadFinish:(DownloadFinish)downloadFinish;

//控制下载的方法
- (void)pauseDownload;
- (void)cancelDownload;
- (void)continueDownload;


@end
