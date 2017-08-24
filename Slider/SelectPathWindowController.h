//
//  SelectPathWindowController.h
//  Slider
//
//  Created by Dmitry Volkov on 28.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SelectPathWindowController : NSWindowController<NSTableViewDataSource, NSTableViewDelegate>

//directoriesTableView
//songsTableView
@property (weak)  IBOutlet NSTableView *filesForAddToCollectionTableView;
@property (weak)  IBOutlet NSTableView *existingFilesTableView;
@property (weak) IBOutlet NSTextField *searchSongField;
@property (weak) IBOutlet NSTextField *songsCountNew;
@property (weak) IBOutlet NSTextField *songsCountExisting;

-(void) updateExistingSongsCounter;
-(void) updateNewSongsCounter;

@end
