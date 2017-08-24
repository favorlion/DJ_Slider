//
//  DetailViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 01.11.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "DetailRequestViewController.h"
#import "SliderWindowController.h"
#import "RequestDeleteAcceptViewController.h"
#import "AppDelegate.h"
#import "CurlHelper.h"
#import "JSONItem.h"
#import "MessageCenter.h"
#import "Scheduler.h"

DetailRequestViewController* gDetailRequestViewController;

@implementation DetailRequestViewController
{
    Request* request;
    Customer* customer;
    NSTimer* dataUpdateTimer;
    NSUInteger highestSeqNo;
    
    NSPopover* popover;
    RequestDeleteAcceptViewController* deleteViewController;
    
    BOOL isDeleteButtonPressed;
}

@synthesize showed;
@synthesize artistField;
@synthesize titleField;
@synthesize filenameField;
@synthesize directoryField;
@synthesize requesterField;
@synthesize tipField;
@synthesize messageHistoryTextView;
@synthesize sendField;
@synthesize replayTextView;
@synthesize bpmComboBox;
@synthesize completeRequestButton;
@synthesize enableRequestCompletionCheckBox;

-(instancetype)initWithNibName:(NSString *)nibNameOrNil
                        bundle:(NSBundle *)nibBundleOrNil
                    andRequest:(Request*) req
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    gDetailRequestViewController = self;
    request = req;
    customer = [req customer];
    return self;
}

- (void)viewWillAppear
{
    [super viewDidLoad];

    showed = YES;
    artistField.stringValue = [request artist];
    titleField.stringValue = [request title];
    
    NSString* requesterName = [request custName];
    
    NSURL* filePath = [[NSURL alloc]  initFileURLWithPath:[request requested_file]];
    filenameField.stringValue = [filePath lastPathComponent];
    directoryField.stringValue = [filePath path];
    requesterField.stringValue = requesterName;
    
    tipField.stringValue = [NSString stringWithFormat:@"$%d", (int) [request tip_amount]];
    sendField.stringValue = [request relativeTimeString];

    if ([request bpm])
    {
        int bpm = [[request bpm] intValue];
        [bpmComboBox removeAllItems];
        [bpmComboBox addItemWithObjectValue:[NSNumber numberWithInt:bpm/2]];
        [bpmComboBox addItemWithObjectValue:[NSNumber numberWithInt:bpm]];
        [bpmComboBox addItemWithObjectValue:[NSNumber numberWithInt:bpm*2]];
        [bpmComboBox selectItemAtIndex:1];
    }
    else
    {
        bpmComboBox.enabled = NO;
    }

    highestSeqNo = 0;

    [completeRequestButton setEnabled:NO];
    [enableRequestCompletionCheckBox setState:NSOffState];

    // update the first one immediately
    [self updateData];

    // then schedule the subsequent ones
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
    [[replayTextView window] makeFirstResponder:replayTextView];
}

- (void)viewDidDisappear
{
    [dataUpdateTimer invalidate];
    [popover close];
}

-(void) updateData
{
    NSUInteger reqHighestSeqNo = [request highestSeqNo];
    if (highestSeqNo == reqHighestSeqNo)
        return;

    [request setSeenAllMessages];
    NSArray* allMessages = [request messages];

    [messageHistoryTextView setString:@""];

    for (Message* msg in allMessages)
    {
        NSAttributedString* attrString = [msg formattedText];
        [[messageHistoryTextView textStorage] appendAttributedString:attrString];
    }
    [messageHistoryTextView scrollRangeToVisible: NSMakeRange ([[messageHistoryTextView string] length], 0)];
    
    highestSeqNo = reqHighestSeqNo;
}


- (IBAction)closeButtonClicked:(id)sender
{
    showed = NO;
    [self.view.window close];
}

- (IBAction)secondCloseButtonClicked:(id)sender
{
    [self closeButtonClicked:self];
}

- (IBAction)sendReplyButtonClicked:(id)sender
{
    NSString* reply = [replayTextView string];
    
    if ([reply length] > 0)
    {
        const char* partyId = [[gAppDelegate currentPartyId] UTF8String];
        NSString* cid = [NSString stringWithFormat:@"%@", [request custId]];
        NSString* reqId = [NSString stringWithFormat:@"%@", [request reqId]];
        if (!gCurlHelper->sendMessageToGuest(partyId, [cid UTF8String], [reply UTF8String], [reqId UTF8String]))
        {
            NSLog(@"Error:Message not send!!!");
        }
        
        [replayTextView setString:@""];
    }
}

- (IBAction)deleteRequestButtonClicked:(id)sender
{
    

    [popover close];
    
        deleteViewController = [[RequestDeleteAcceptViewController alloc]
                                    initWithNibName:@"RequestDeleteAcceptViewController" bundle:nil andRequestId:[request reqId]];
        
        NSRect rect = [self.view bounds];

        const CGFloat width = [deleteViewController.view bounds].size.width ;
        const CGFloat height = [deleteViewController.view bounds].size.height;
        
        popover = [[NSPopover alloc] init];
        [popover setContentSize:NSMakeSize(width,height)];
        [popover setContentViewController:deleteViewController];
        [popover setAnimates:YES];
        [popover showRelativeToRect:rect ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)bpmComboBoxChanged:(id)sender
{
    NSNumber *bpm = [sender objectValueOfSelectedItem];
    NSString *bpmStr = [NSString stringWithFormat:@"%@m", bpm];
    [request setBpm:bpmStr];
}

-(BOOL) isMouseAreaForShowAndShowed:(NSInteger)side
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    NSRect windowFrame = self.view.window.frame;
    
    BOOL flag = NO;
    
    if (defLeftSide == side)
    {
        flag = (mouseLocation.x >= windowFrame.origin.x ) && (mouseLocation.x <= (windowFrame.size.width + [gSliderWindowController windowFrame].size.width));
    }
    else if(defRightSide == side)
    {
        NSScreen* screen = [NSScreen mainScreen];
        float screenWidth = screen.frame.size.width;
        flag = (mouseLocation.x >=(screenWidth - (windowFrame.size.width + [gSliderWindowController windowFrame].size.width)));
    }
    
    flag = flag && (mouseLocation.y >= windowFrame.origin.y) && (mouseLocation.y <= windowFrame.origin.y + windowFrame.size.height);
    flag = flag && showed;
    
    return flag;
}

-(void) hideDialog:(NSInteger)side
{
    showed = NO;
    NSRect windowFrame = self.view.window.frame;
    
    if (defLeftSide == side)
        windowFrame.origin.x = 1.0 - windowFrame.size.width;
    else if(defRightSide == side)
        windowFrame.origin.x = - windowFrame.size.width - 1.0;
    
    [self.view.window setFrame:windowFrame display:YES animate:NO];
    [self.view.window setAlphaValue:0.0];
}

- (IBAction)enableRequestCompletionButton:(id)sender {
    [completeRequestButton setEnabled:![completeRequestButton isEnabled]];
}

- (IBAction)markRequestManuallyCompleted:(id)sender {
    dispatch_queue_t queue = [gScheduler serialWebRequestQueue];
    unsigned long now = [[NSDate date] timeIntervalSince1970];

    dispatch_async(queue,
                   ^{
                       if (gCurlHelper->completeRequest([[[request reqId] stringValue] UTF8String],
                                                        [[gAppDelegate currentPartyId] UTF8String],
                                                        now,
                                                        now + 60,
                                                        [[request requested_file] UTF8String],
                                                        [[request artist] UTF8String],
                                                        [[request title] UTF8String])) {
                           
                           SongEntity *song = [[SongEntity alloc] initWithSongPath:[request requested_file]];
                           [request completeWithSong:song
                                             inParty:[gAppDelegate currentPartyId]
                                         withStarted:[NSDate date]];
                       }
                   });
}

@end
