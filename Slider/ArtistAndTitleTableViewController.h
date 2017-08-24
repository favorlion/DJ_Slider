//
//  ArtistAndTitleTableViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 29.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ArtistAndTitleTableViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *lastPostedSongName;

-(void) fileOpened:(NSString*)filename;
-(void) fileClosed:(NSString*)filename;
-(void) filePlaying:(NSString*)filename withScore:(float)score;

-(NSUInteger) addNewVotes:(NSArray*)messages;

-(void) disableAutoBroadcast;
-(void) enableAutoBroadcast;

-(void) clear;

-(void) makeFirstResponder;

@end

extern ArtistAndTitleTableViewController* gArtistAndTitleTableViewController;
