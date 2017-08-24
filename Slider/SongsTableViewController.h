//
//  TableViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 15.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "JSONArray.h"

@interface SongsTableViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak)  IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *countOfSongsField;

@property (strong) JSONArray *jsonArray;


-(void) closeDetailWindow;



@end

extern SongsTableViewController* gSongsTableViewController;
