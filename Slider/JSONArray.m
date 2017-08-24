//
//  JSONArray.m
//  Slider
//
//  Created by Dmitry Volkov on 18.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "JSONArray.h"

@implementation JSONArray

@synthesize jsonArray;

-(id) init
{
    self = [super init];
    
    if(self)
    {
        jsonArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+(id) jsonArrayFromFile:(NSString*) path;
{
    JSONArray* array = [[JSONArray alloc] init];
    
    NSError *error = nil;
    NSData* jsonData = [NSData dataWithContentsOfFile:path];
    
    if (!jsonData)
    {
        NSAlert *alert = [[NSAlert alloc] init];
       
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Incorrect path to the json file"];
       
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        return array;
    }
    
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if(error)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        NSString* infoMessage = [NSString stringWithFormat:@"%@ \n"
         @"Please check your json file:'http://jsonlint.com/'", [error description]];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Bad formed json file"];
        [alert setInformativeText:infoMessage];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    
    for (NSDictionary* dictionaryItem in jsonDictionary)
    {
        NSURL* url = [[NSURL alloc] initFileURLWithPath:dictionaryItem[@"filename"]];
        JSONItem* jsonItem = [[JSONItem alloc] initWithArtist:dictionaryItem[@"firstname"]
                                                      andFile: dictionaryItem[@"filename"]
                                                     andTitle: dictionaryItem[@"title"]
                                                   andFileUrl:url];
        
        [array.jsonArray addObject:jsonItem];
    }
    
    return array;
}

+(id) jsonArrayFromNSString:(NSString*) str
{
    return[JSONArray jsonArrayFromCString:[str UTF8String]];
}

+(id) jsonArrayFromCString:(const char*) str
{
    NSError *error = nil;
    NSData* requestJsonData = [NSData dataWithBytes:str length:strlen(str)];
    NSArray *requestJsonDictionary = [NSJSONSerialization JSONObjectWithData:requestJsonData options:0 error:&error];
    JSONArray* array = [[JSONArray alloc] init];
    
    for (id arrayItem in requestJsonDictionary)
    {
        NSURL* url = [[NSURL alloc] initFileURLWithPath:arrayItem[@"filename"]];
        JSONItem* jsonItem = [[JSONItem alloc] initWithArtist:arrayItem[@"artist"]
                                                      andFile: arrayItem[@"filename"]
                                                      andTitle: arrayItem[@"title"]
                                                      andFileUrl:url];
        
        [array.jsonArray addObject:jsonItem];
        
        
    }
    return array;
}

-(JSONItem*)itemAtIndex:(NSUInteger)index
{
    return [jsonArray objectAtIndex:index];
}

-(NSUInteger) count
{
    return [jsonArray count];
}

@end
