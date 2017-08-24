//
//  SelectFilesTableViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 11.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface SelectFilesTableViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak)  IBOutlet NSTableView *tableView;



@end

extern SelectFilesTableViewController* gSelectFilesTableViewController;
