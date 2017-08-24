//
//  MessageTablveViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 28.06.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface MessageTablveViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTextField *countOfMessagesField;

@property (weak) IBOutlet NSTableView *tableView;



-(void) closeDetailWindow;

@end

extern MessageTablveViewController* gMessageTableViewController;
