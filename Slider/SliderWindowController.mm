//
//  SliderWindowController.m
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SliderWindowController.h"
#import "DetailRequestViewController.h"
#import "DetailMessageViewController.h"
#import "SongsTableViewController.h"
#import "MessageTableViewController.h"
#import "SendBroadcastMessagesViewController.h"
#import "ArtistAndTitleTableViewController.h"
#import "CurlHelper.h"
#import "AppDelegate.h"


extern AppDelegate* gAppDelegate;
extern ArtistAndTitleTableViewController* gArtistAndTitleTableViewController;

SliderWindowController* gSliderWindowController;

@interface SliderWindowController ()
{
    float screenWidth;
    float screenHeight;
    float panelWidth;
    NSRect windowFrame;
    NSPoint mouseLocation;
    
    NSPopover* popover;
    SendBroadcastMessagesViewController* broadcastMessageViewController;
}

@property (readwrite) NSThread* wathThread;

@end

@implementation SliderWindowController

@synthesize isVisible;
@synthesize side;
@synthesize isFirstShow;
@synthesize maxWidth;
@synthesize sendBroadcastMessageButton;

@synthesize lockButton;
@synthesize isLocked;

@synthesize playOrPauseButton;
@synthesize isPaused;


- (void)windowDidResize:(NSNotification *)notification
{
    panelWidth = self.window.frame.size.width;
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    const CGFloat x = mouseLocation.x;
    
    if (defLeftSide == side)
    {
        if (x >= 0.0 && x <= 10.0)
        {
            return self.window.frame.size;
        }
    }
    else if (defRightSide == side)
    {
        if ((x >= screenWidth - 10.0) && (x <= screenWidth))
        {
            return self.window.frame.size;
        }
    }
    
    return frameSize;
}

-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    [self.window setDelegate:self];
    
    gSliderWindowController = self;
    
    const float divideCoeff = 6.0;
    
    NSScreen* screen = [NSScreen mainScreen];
    screenWidth = screen.frame.size.width;
    panelWidth = screenWidth/divideCoeff;
    
    screenHeight = screen.frame.size.height;
    
    windowFrame.size.height = screenHeight - screenHeight*0.1;
    windowFrame.size.width = panelWidth;
    windowFrame.origin.x = screenWidth/2.0;
    windowFrame.origin.y = screenHeight;
    
    [self.window setMaxSize:NSMakeSize(screenWidth/2.5, screenHeight - screenHeight*0.1)];
    [self.window setMinSize:NSMakeSize(screenWidth/10.0, screenHeight - screenHeight*0.1)];
    
    [self.window setMovable:NO];
    [self setIsVisible:NO];
    [self.window setAlphaValue:0.0];
    
    maxWidth = screenWidth/2.5;

    isLocked = NO;
    isPaused = NO;
    isVisible = NO;

    return self;
}

-(void) showWindowAndStick
{
    if (defLeftSide == [self side])
    {
        windowFrame.origin.x = 0.0;
    }
    else if (defRightSide == [self side])
    {
        windowFrame.origin.x = screenWidth - panelWidth;
    }
    
    if (isFirstShow)
    {
        [self.window setAlphaValue:0.0];
        [self setIsFirstShow:NO];
        [self setIsVisible:NO];
    }
    else
    {
        [self setIsVisible:YES];
        [self.window setAlphaValue:1.0];
    }
    [self.window setFrame:windowFrame display:YES animate:YES];
    [self.window makeKeyAndOrderFront:self];
    [self.window orderFrontRegardless];
    //[self.window makeFirstResponder:self.window];
}

-(void) moveWindowAndHide
{
    panelWidth = self.window.frame.size.width;
    windowFrame.size.width = panelWidth;
    
    if ([self side] == defLeftSide)
         windowFrame.origin.x = 1.0 - panelWidth;
    else if ([self side] == defRightSide)
        windowFrame.origin.x = screenWidth - 1.0;
    
   [self setIsVisible:NO];
   [self.window setFrame:windowFrame display:YES animate:YES];
   [self.window setAlphaValue:0.0];
    
   if ([gDetailRequestViewController isShowed])
   {
        [gDetailRequestViewController hideDialog:side];
        [gSongsTableViewController closeDetailWindow];
   }
    
   if ([gDetailMessageViewController isShowed])
   {
        [gDetailMessageViewController hideDialog:side];
        [gMessageTableViewController closeDetailWindow];
   }
    
   if ([gSendBroadcastMessagesViewController isHide])
   {
        [gSendBroadcastMessagesViewController hideDialog:side];
        [self closeDetailWindow];
   }
}

-(BOOL) isMouseInAreaForShow;
{
    // check if we're at the upper or lower corner
    if (mouseLocation.y <= screenHeight * 0.95 && mouseLocation.y >= screenHeight * 0.05)
        return NO;
    
    if (mouseLocation.x >= 0.0f && mouseLocation.x <= 1.0f && side == defLeftSide)
        return YES;
    
    if (mouseLocation.x >= screenWidth - 1.0f && side == defRightSide)
        return YES;
    
    return NO;
}

-(BOOL) isMouseInAreaForHide
{
    if (mouseLocation.x > panelWidth && defLeftSide == side)
    {
        return YES;
    }
    
    if (mouseLocation.x < screenWidth - panelWidth && defRightSide == side)
        return YES;
    
    return NO;
}

-(void) updateMouseLocation
{
    mouseLocation = [NSEvent mouseLocation];
}

-(void) updatePanelWidth
{
    float width = self.window.frame.size.width;
    
    if (width >= panelWidth)
        panelWidth = width;
}

-(void) startSliderThread
{
    if (_wathThread && [_wathThread isExecuting])
    {
        [_wathThread cancel];
        _wathThread = nil;
    }
    else
    {
        _wathThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMethod) object:nil];
        [_wathThread start];
    }
}

-(void) stopSliderThread
{
    [_wathThread cancel];
}

-(void) threadMethod
{
    const float sleepTimeOut = 0.25f;
    const short maxTicks = 1.0/sleepTimeOut;
    short currentTicks = maxTicks;
    
    [NSThread setThreadPriority:1.0];
    
    /***We call this method befor run loop to suppress bug when sliding window first show at display***/
    [self setIsFirstShow:YES];
    [self performSelectorOnMainThread:@selector(showWindowAndStick)
                                              withObject:nil
                                            waitUntilDone:YES];
    
    [self performSelectorOnMainThread:@selector(moveWindowAndHide)
                           withObject:nil
                        waitUntilDone:YES];
    //-----------------------------------------------------------------------------------------------//
    
    while (![_wathThread isCancelled])
    {
        
        // Disabling AppNap for prevent freeze sliding effect when app in background mode
        if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
        {
            self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"Disabling AppNap"];
        }
        
        if ([NSEvent pressedMouseButtons] == 1)
        {
            currentTicks = 0;
            [self updatePanelWidth];
            [NSThread sleepForTimeInterval:sleepTimeOut];
            continue;
        }
        
        [self updateMouseLocation];
        
        [NSThread sleepForTimeInterval:sleepTimeOut];
        
//        if ([self isVisible] && ![gDetailRequestViewController isShowed])
//        {
//           // [self.window makeFirstResponder:self.window];
//           // [gArtistAndTitleTableViewController makeFirstResponder];
//        }
        
        if ([self isMouseInAreaForShow] && ![self isVisible])
        {
            currentTicks = 0;
            [self setIsVisible:YES];
            [self performSelectorOnMainThread:@selector(showWindowAndStick)
                                                      withObject:nil
                                                   waitUntilDone:YES];
        }
        else if ([self isMouseInAreaForHide] && [self isVisible] &&
                 ![gDetailRequestViewController isMouseAreaForShowAndShowed:side] &&
                 ![gDetailMessageViewController isMouseInAreaForShowAndShowed:side] &&
                 ![gSendBroadcastMessagesViewController isMouseInAreaForShowAndShowed:side] &&
                 !isLocked)
        {
            if (currentTicks < maxTicks)
            {
                currentTicks++;
                continue;
            }
            
            [self setIsVisible:NO];
            [self performSelectorOnMainThread:@selector(moveWindowAndHide)
                                                      withObject:nil
                                                   waitUntilDone:YES];
            
        } else if ([self isVisible] && ![self isMouseInAreaForHide] )
        {
            // we accumulate ticks without this and eventually moving the mouse out of the panel just for a fraction of a second would be enough to make it hide
            currentTicks = 0;
        }
    }
}

-(NSRect)windowFrame
{
    return self.window.frame;
}

- (IBAction)backButtonPressed:(id)sender
{
    [self stopSliderThread];
    [self close];
    [self moveWindowAndHide];
    isLocked = NO;
    //[playOrPauseButton setImage:[NSImage imageNamed:@"pause"]];
    [lockButton setImage:[NSImage imageNamed:@"unlock"]];
    [gAppDelegate closeSlider];
    [gArtistAndTitleTableViewController clear];
}

- (IBAction)sendBroadcastMessageButtonPressed:(id)sender
{
    [popover close];
    
    broadcastMessageViewController = [[SendBroadcastMessagesViewController alloc] initWithNibName:@"SendBroadcastMessagesViewController" bundle:nil];
    
    CGFloat width = [broadcastMessageViewController.view bounds].size.width;
    CGFloat height = [broadcastMessageViewController.view bounds].size.height;
    
    popover = [[NSPopover alloc] init];
    [popover setContentSize:NSMakeSize(width,height)];
    [popover setContentViewController:broadcastMessageViewController];
    [popover setAnimates:YES];

    NSRect rect =  [sender bounds];
    
    rect.size.width = [self maxWidth];
    [popover showRelativeToRect:rect ofView:sender preferredEdge:NSMaxXEdge];
}

-(void)setImages:(NSString*)firstImage :(NSString*)secondImage forButton:(NSButton*) btn
{
    NSImage* image;
    
    if([btn state] == NSOnState)
    {
        image = [NSImage imageNamed:(firstImage)];
    }
    else if ([btn state] == NSOffState)
    {
        image = [NSImage imageNamed:(secondImage)];
    }
    
    [btn setImage:image];
}



- (IBAction)lockSliderButtonPressed:(id)sender
{
    [self setImages:@"lock" :@"unlock" forButton:sender];
    
    if (isLocked)
        isLocked = NO;
    else
        isLocked = YES;
}

- (IBAction)playOrPauseButtonPressed:(id)sender
{
    [self setImages:@"pause" :@"play" forButton:sender];

    if (isPaused)
    {
        isPaused = NO;
        [gArtistAndTitleTableViewController enableAutoBroadcast];
    }
    else
    {
        isPaused = YES;
        [gArtistAndTitleTableViewController disableAutoBroadcast];
    }
}

-(void)closeDetailWindow
{
    [popover close];
}

@end
