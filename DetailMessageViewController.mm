//
//  DetailMessageViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 05.12.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "DetailMessageViewController.h"
#import "SliderWindowController.h"
#import "AppDelegate.h"
#import "CurlHelper.h"
#import "MessageCenter.h"

DetailMessageViewController* gDetailMessageViewController;

@implementation DetailMessageViewController
{
    NSArray* customerMessages;
    Customer* customer;
    NSTimer* messagesTimer;
    NSUInteger lastSequence;
    NSTimer* dataUpdateTimer;
    // for auto-updates
    Message* mostRecentMessageSeen;
}

@synthesize showed;
@synthesize messageTextView;
@synthesize replyTextView;
@synthesize conversationHistoryTextField;


- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                    andCustomer:(Customer*)cust
{
    gDetailMessageViewController = self;
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        customer = cust;
        mostRecentMessageSeen = nil;
    }
    return self;
}

-(void) viewWillAppear
{
    MessageCollection* msgColl = [gCommCenter messageCollection];
    [msgColl setSeenAllFromCustomer:customer];

    // update the first one immediately
    [self updateData];

    // then schedule the subsequent ones
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
    [[replyTextView window] makeFirstResponder:replyTextView];
}

- (void)viewDidDisappear
{
    [dataUpdateTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    showed = YES;
    conversationHistoryTextField.stringValue = [NSString stringWithFormat:@"Conversation history with %@:", [customer name]];
}

-(void)updateData
{
    // we only show messages so we can
    MessageCollection* msgColl = [gCommCenter messageCollection];
    Message* mostRecentMessage = [msgColl newestFromOrToCustomer:customer];
    
    if ([[mostRecentMessageSeen msgId] isEqual:[mostRecentMessage msgId]])
    {
        // we have seen the most recent message
        return;
    }

    // else, need to update
    mostRecentMessageSeen = mostRecentMessage;
    customerMessages = [msgColl byCustomer:customer];

    [messageTextView setString:@""];
    for (Message* msg in customerMessages)
    {
        NSAssert(![msg isRequestRelated], @"Got a request related message unexpectedly");
        NSAttributedString* attrString = [msg formattedText];
        [[messageTextView textStorage] appendAttributedString:attrString];
    }
    [messageTextView scrollRangeToVisible: NSMakeRange ([[messageTextView string] length], 0)];
}


- (IBAction)closeButtonClicked:(id)sender
{
    showed = NO;
    [self.view.window close];
    [dataUpdateTimer invalidate];
}

- (IBAction)bottomCloseButtonClicked:(id)sender
{
    showed = NO;
    [self.view.window close];
    [dataUpdateTimer invalidate];
}


- (IBAction)sendMessageToGuestButtonClicked:(id)sender
{
    NSString* reply = [[replyTextView string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if ([reply length] == 0)
        return;

    NSString *cid = [NSString stringWithFormat:@"%@", [customer custId]];

    // requestId is always empty from here
    if (gCurlHelper->sendMessageToGuest([[gAppDelegate currentPartyId]UTF8String],
                                        [cid UTF8String], [reply UTF8String], ""))
    {
        NSLog(@"Message sent !");
    }
    else
    {
        NSLog(@"Message not sent !");
    }
    
    [replyTextView setString:@""];
}

-(BOOL) isMouseInAreaForShowAndShowed:(NSInteger)side
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
        windowFrame.origin.x = 1.0f - windowFrame.size.width;
    else if(defRightSide == side)
        windowFrame.origin.x = - windowFrame.size.width - 1.0f;
    
    [self.view.window setFrame:windowFrame display:YES animate:NO];
    [self.view.window setAlphaValue:0.0];
}


@end
