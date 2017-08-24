//
//  RequestDeleteAcceptViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 16.01.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import "RequestDeleteAcceptViewController.h"
#import "SongsTableViewController.h"
#import "MessageCenter.h"
#import "CurlHelper.h"

@implementation RequestDeleteAcceptViewController
{
    NSNumber* requestId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(instancetype) initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                   andRequestId:(NSNumber*)reqId
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    requestId = reqId;
    return self;
}

- (IBAction)yesButtonClicked:(id)sender
{
    NSString* reqid = [NSString stringWithFormat:@"%@", requestId];
    if (gCurlHelper->deleteRequest([reqid UTF8String]))
    {
        RequestCollection *reqColl = [gCommCenter requestCollection];
        Request *req = [reqColl byId:requestId];
        [req delete];

        [self.view.window close];
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [gSongsTableViewController closeDetailWindow];
                       });
    }
    [self.view.window close];
}

- (IBAction)noButtonClicked:(id)sender
{
    [self.view.window close];
}

@end
