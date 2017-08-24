//
//  SliderWindowController.h
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>



#define defUnknownSide (0)
#define defLeftSide (1)
#define defRightSide (2)

@interface SliderWindowController : NSWindowController<NSWindowDelegate>
@property (weak) IBOutlet NSButton *sendBroadcastMessageButton;

@property(readwrite) BOOL isVisible;
@property(readwrite) BOOL isFirstShow;
@property(readwrite) int side;

@property(readwrite, getter=isLocked) BOOL isLocked;
@property(readwrite, getter=isPaused) BOOL isPaused;

@property(readonly) float maxWidth;

@property (weak) IBOutlet NSButton *playOrPauseButton;
@property (weak) IBOutlet NSButton *lockButton;


// Save activity for disabling AppNap http://osxdaily.com/2014/05/13/disable-app-nap-mac-os-x/
@property (strong) id activity;


-(void) showWindowAndStick;
-(void) moveWindowAndHide;

-(BOOL) isMouseInAreaForShow;
-(BOOL) isMouseInAreaForHide;

-(void) updatePanelWidth;
-(void) updateMouseLocation;

-(void) startSliderThread;
-(void) stopSliderThread;

-(NSRect)windowFrame;


@end

extern SliderWindowController* gSliderWindowController;

