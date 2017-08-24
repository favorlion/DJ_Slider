//
//  SendBroadcastMessagesViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 18.12.15.
//  Copyright © 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SendBroadcastMessagesViewController : NSViewController

@property (weak) IBOutlet NSButton *hideWithSliderButton;
@property (unsafe_unretained) IBOutlet NSTextView *messageText;

@property (readonly, getter=isShowed) BOOL showed;
@property (readonly, getter=isHide) BOOL hide;

-(BOOL) isMouseInAreaForShowAndShowed:(NSInteger)side;

-(void) hideDialog:(NSInteger)side;

@end

extern SendBroadcastMessagesViewController* gSendBroadcastMessagesViewController;
