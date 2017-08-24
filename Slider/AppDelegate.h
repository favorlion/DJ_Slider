//
//  AppDelegate.h
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//


#import "SliderWindowController.h"
#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (readwrite) NSString* currentPartyId;

-(void) closeSlider;
-(void) showNotification:(NSString*)title withMessage:(NSString*)msg;

@end

extern AppDelegate* gAppDelegate;




