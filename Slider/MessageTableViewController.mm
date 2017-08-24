//
//  MessageTablveViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 28.06.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "MessageTableViewController.h"
#import "MessageTableCellView.h"
#import "DetailMessageViewController.h"
#import "DetailRequestViewController.h"
#import "SongsTableViewController.h"
#import "MessageCenter.h"
#import "AppDelegate.h"

MessageTablveViewController* gMessageTableViewController = 0;

@implementation MessageTablveViewController
{
    NSTimer* dataUpdateTimer;
    DetailMessageViewController* detailMessageViewController;
    NSPopover* popover;
    NSInteger selectedRow;
    NSArray* orderedCustomers;
}

@synthesize tableView;

-(id) init
{
    self = [super self];
    gMessageTableViewController = self;
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [orderedCustomers count];
}

- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Customer* cust = orderedCustomers[row];
    MessageCollection* msgColl = [gCommCenter messageCollection];
    Message* newestMessage = [msgColl newestFromCustomer:cust];

    NSAssert(newestMessage, @"newestMessage NULL for customer %@", cust);

    MessageTableCellView *cellView = [aTableView makeViewWithIdentifier:@"MessageCell" owner:self];
    cellView.backgroundStyle = NSBackgroundStyleDark;

    cellView.guestText.stringValue = [cust name];
    cellView.timeoutText.stringValue = [newestMessage relativeTimeString];
    cellView.messageText.identifier = [NSString stringWithFormat:@"%ld", (long)row];

    if ([msgColl haveSeenAllFromCustomer:cust])
    {
        [cellView.guestText setTextColor:[[NSColor blackColor] colorWithAlphaComponent:0.25]];
        [cellView.messageText setTextColor:[[NSColor blackColor] colorWithAlphaComponent:0.25]];
        [cellView.timeoutText setTextColor:[[NSColor blackColor] colorWithAlphaComponent:0.25]];
    }
    else
    {
        NSColor* backgroundColor =
        [NSColor colorWithCalibratedRed:0.191f green:0.515f blue:0.984f alpha:1.0f];
        
        [cellView.guestText setTextColor:backgroundColor];
        [cellView.messageText setTextColor:backgroundColor];
        [cellView.timeoutText setTextColor:backgroundColor];
    }
    
    return cellView;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    selectedRow = [notification.object selectedRow];
    Customer* cust = orderedCustomers[selectedRow];
    MessageCollection* msgColl = [gCommCenter messageCollection];

    id subviews = [[notification.object viewAtColumn:0 row:selectedRow makeIfNecessary:YES]subviews];
    
    for (id view in subviews)
    {
        if ([view isKindOfClass:[NSTextField class]] && [msgColl haveSeenAllFromCustomer:cust])
        {
            [view setTextColor:[[NSColor blackColor] colorWithAlphaComponent:0.25]];
        }
    }
    
    if (-1 != selectedRow)
    {
        [gSongsTableViewController closeDetailWindow];
        [popover close];
        detailMessageViewController = [[DetailMessageViewController alloc]
                                       initWithNibName:@"DetailMessageViewController"
                                       bundle:nil
                                       andCustomer:cust];
    
        const CGFloat width = [detailMessageViewController.view bounds].size.width ;
        const CGFloat height = [detailMessageViewController.view bounds].size.height;
        
        popover = [[NSPopover alloc] init];
        [popover setContentSize:NSMakeSize(width,height)];
        [popover setContentViewController:detailMessageViewController];
        [popover setAnimates:YES];
        
        NSRect rect = [tableView frameOfCellAtColumn:0 row:[tableView selectedRow]];
        rect.size.width = [gSliderWindowController maxWidth];
        
        [popover showRelativeToRect:rect ofView:tableView preferredEdge:NSMaxXEdge];
    }
}

-(void) updateData
{
    MessageCollection* msgColl = [gCommCenter messageCollection];
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       // this defines the order at the beginning of the update, everything else then follows along and accesses the data via the customerId from this array
                       orderedCustomers = [msgColl orderedCustomers];
                       [tableView reloadData];
                   });
    
    _countOfMessagesField.stringValue = [NSString stringWithFormat:@"%lu",
                                         (unsigned long)[msgColl countCustomers]];
}

-(void) closeDetailWindow
{
    [popover close];
}

@end
