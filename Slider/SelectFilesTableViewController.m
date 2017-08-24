//
//  SelectFilesTableViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 11.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SelectFilesTableViewController.h"
#import "JSONArray.h"

SelectFilesTableViewController* gSelectFilesTableViewController;

@implementation SelectFilesTableViewController
{
    JSONArray* jsonArray;
}


@synthesize tableView;

-(id) init
{
    self = [super init];
    
    gSelectFilesTableViewController = self;
    
    NSLog(@"TWO");
    
    
    NSString* s = [NSString stringWithContentsOfFile:@"inventory.json" encoding:NSUTF8StringEncoding error:NULL];
    
    jsonArray = [JSONArray jsonArrayFromCString:[s UTF8String]];
    
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [jsonArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    
    JSONItem* item = [jsonArray itemAtIndex:rowIndex];
    
    if([[aTableColumn identifier] isEqualToString:@"Title"])
    {
        return [item title];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Artist"])
    {
        //NSLog(@"AAAAA %@", [item artist]);
        return [item artist];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Filepath"])
    {
        return [item file];
    }
    else if([[aTableColumn identifier] isEqualToString:@"IsCopy"])
    {
        return [NSNumber numberWithInt:NSMixedState];
    }
    
    return @"Fail";
}


@end
