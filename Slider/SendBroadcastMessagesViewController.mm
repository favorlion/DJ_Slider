//
//  SendBroadcastMessagesViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 18.12.15.
//  Copyright © 2015 Automatic System Metering. All rights reserved.
//

#import "SendBroadcastMessagesViewController.h"
#import "SliderWindowController.h"
#import "AppDelegate.h"
#import "CurlHelper.h"



SendBroadcastMessagesViewController* gSendBroadcastMessagesViewController;

@implementation SendBroadcastMessagesViewController

@synthesize showed;
@synthesize hide;
@synthesize hideWithSliderButton;
@synthesize messageText;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    showed = YES;
    hide = YES;
    
    gSendBroadcastMessagesViewController = self;
}

- (IBAction)hideCHeckBoxPressed:(id)sender
{
    if ([sender state] == NSOnState)
    {
        hide = YES;
    }
    else
    {
        hide = NO;
    }
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
        const float screenWidth = screen.frame.size.width;
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

- (IBAction)sendMessage:(id)sender
{
    NSString* msg = [[messageText string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if ([msg isEqualToString:@""])
        return;
    
    if (gCurlHelper->sendBroadcastMessage([[gAppDelegate currentPartyId] UTF8String], [msg UTF8String]))
    {
        NSLog(@"Broadcast message is sent");
    }
    else
    {
        NSLog(@"Broadcast message not sent");
    }
    
    [self secondCloseButtonPressed:self];
}

- (IBAction)closeWindowButtonPressed:(id)sender
{
    [self.view.window close];
    showed = NO;
}

- (IBAction)secondCloseButtonPressed:(id)sender
{
    [self.view.window close];
    showed = NO;
}

@end
