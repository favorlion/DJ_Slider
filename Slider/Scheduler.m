//
//  Scheduler.m
//  Slider
//
//  Created by Joachim Wieland on 6/10/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scheduler.h"

Scheduler* gScheduler;

@implementation Scheduler
-(instancetype)init
{
    self = [super init];
    gScheduler = self;
    _serialAudioAnalysisQueue = dispatch_queue_create("com.morequests.serialAudioAnalysisQueue", DISPATCH_QUEUE_SERIAL);
    _serialWebRequestQueue = dispatch_queue_create("com.morequests.serialWebrequestQueue", DISPATCH_QUEUE_SERIAL);
    return self;
}
@end