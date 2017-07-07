//
//  NSString+urlToFileName.h
//  ThreadTest
//
//  Created by anne on 2017/7/3.
//  Copyright © 2017年 anne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (urlToFileName)

/**
  根据url 截取文件名
  规则：去掉http://  ： /
 */
-(NSString*)fileName;

@end
