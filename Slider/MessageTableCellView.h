//
//  MessageTableCellView.h
//  Slider
//
//  Created by Dmitry Volkov on 05.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MessageTableCellView : NSTableCellView

//@property (unsafe_unretained) IBOutlet NSButton *messageText;

@property (unsafe_unretained) IBOutlet NSTextField *guestText;

@property (unsafe_unretained) IBOutlet NSTextField *timeoutText;

@property (unsafe_unretained) IBOutlet NSTextField *messageText;

//@property (unsafe_unretained) IBOutlet NSWindow *view;


@end
