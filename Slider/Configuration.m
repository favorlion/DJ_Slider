//
//  Configuration.m
//  Slider
//
//  Created by Joachim Wieland on 6/10/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"

Configuration* gConfiguration;

@implementation Configuration
-(instancetype)init
{
    self = [super init];
    gConfiguration = self;
    return self;
}
@end