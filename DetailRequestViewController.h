//
//  DetailViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 01.11.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSONItem.h"
#import "MessageCenter.h"

@interface DetailRequestViewController : NSViewController

@property (weak) IBOutlet NSTextField *artistField;
@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSTextField *filenameField;
@property (weak) IBOutlet NSTextField *directoryField;
@property (weak) IBOutlet NSTextField *requesterField;
@property (weak) IBOutlet NSTextField *tipField;
@property (weak) IBOutlet NSTextField *sendField;
@property (weak) IBOutlet NSComboBox *bpmComboBox;
@property (weak) IBOutlet NSButton *enableRequestCompletionCheckBox;
@property (weak) IBOutlet NSButton *completeRequestButton;

@property (unsafe_unretained) IBOutlet NSTextView *messageHistoryTextView;
@property (unsafe_unretained) IBOutlet NSTextView *replayTextView;

@property (readwrite, getter=isShowed) BOOL showed;


-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andRequest:(Request*) req;


-(BOOL) isMouseAreaForShowAndShowed:(NSInteger)side;

-(void) hideDialog:(NSInteger)side;

@end

extern DetailRequestViewController* gDetailRequestViewController;
