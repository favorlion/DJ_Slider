//
//  DetailMessageViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 05.12.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageCenter.h"

@interface DetailMessageViewController : NSViewController

@property (readonly, getter=isShowed) BOOL showed;
@property (unsafe_unretained) IBOutlet NSTextView *messageTextView;
@property (unsafe_unretained) IBOutlet NSTextView *replyTextView;
@property (weak) IBOutlet NSTextField *conversationHistoryTextField;



- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                    andCustomer:(Customer*)cust;

-(BOOL)isMouseInAreaForShowAndShowed:(NSInteger)side;



-(void) hideDialog:(NSInteger)side;

@end

extern DetailMessageViewController* gDetailMessageViewController;
