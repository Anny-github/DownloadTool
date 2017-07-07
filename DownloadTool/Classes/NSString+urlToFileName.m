//
//  NSString+urlToFileName.m
//  ThreadTest
//
//  Created by anne on 2017/7/3.
//  Copyright © 2017年 anne. All rights reserved.
//

#import "NSString+urlToFileName.h"

@implementation NSString (urlToFileName)

-(NSString*)fileName{
    NSString *name;
    if ([self containsString:@"http://"]) {
        name = [self stringByReplacingOccurrencesOfString:@"http://" withString:@""];

    }
    if ([self containsString:@"https://"]) {
        name = [self stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    }
    name = [name stringByReplacingOccurrencesOfString:@":" withString:@""];
    name = [name stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    return name;
    
}

@end
