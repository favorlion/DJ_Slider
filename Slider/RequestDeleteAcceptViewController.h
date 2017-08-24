//
//  RequestDeleteAcceptViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 16.01.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RequestDeleteAcceptViewController : NSViewController



-(instancetype) initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                   andRequestId:(NSNumber*)requestId;

@end
