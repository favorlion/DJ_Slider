//
//  JSONArray.h
//  Slider
//
//  Created by Dmitry Volkov on 18.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONItem.h"

@interface JSONArray : NSObject

@property (strong) NSMutableArray* jsonArray;

+(id) jsonArrayFromFile:(NSString*) path;

+(id) jsonArrayFromNSString:(NSString*) str;

+(id) jsonArrayFromCString:(const char*) str;

-(JSONItem*) itemAtIndex:(NSUInteger)index;

-(NSUInteger) count;

@end
