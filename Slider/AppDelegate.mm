//
//  AppDelegate.m
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//



#import "AppDelegate.h"
#import "SongsTableViewController.h"
#import "MessageTableViewController.h"
#import "SelectFilesTableViewController.h"
#import "SelectPathWindowController.h"
#import "ArtistAndTitleTableViewController.h"
#import "CurlHelper.h"
#import "MatcherInterface.h"
#import "MessageCenter.h"
#import "HTMLParser.h"
#import "Configuration.h"
#import "Scheduler.h"
#import "MatcherRules.h"
#import "CoreFoundation/CoreFoundation.h"

AppDelegate* gAppDelegate;
CurlHelper* gCurlHelper;

void showMessageBox(const char* title, const char* message)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:[NSString stringWithFormat:@"%s", title]];
    [alert setInformativeText:[NSString stringWithFormat:@"%s", message]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

@interface AppDelegate ()
{
    NSMutableDictionary* partyDictionary;
    NSMutableArray* devicesArray;
    NSArray* bpmArray;
    CommunicationCenter* commCenter;
    Configuration* configuration;
    Scheduler* scheduler;
    MatcherRules* matcherRules;
    CurlHelper curlHelper;
    MatcherInterface* matcherInterface;
    NSStatusBar* statusBar;
    NSStatusItem* statusItem;
    NSMutableDictionary* fingerprints;
}

@property (weak) IBOutlet NSButton *signInButton;
@property (weak) IBOutlet NSButton *signOutButton;
@property (weak) IBOutlet NSButton *selectDirButton;
@property (weak) IBOutlet NSButton *stickToLeftButton;
@property (weak) IBOutlet NSButton *stickToRightButton;
@property (weak) IBOutlet NSComboBox *partiesComboBox;
@property (weak) IBOutlet NSComboBox *devicesComboBox;
@property (weak) IBOutlet NSComboBox *bpmComboBox;
@property (weak) IBOutlet NSButton *resetPartyButton;
@property (weak) IBOutlet NSButton *enableResetPartyButton;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *loginTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;


@property (strong) SliderWindowController *sliderWindowController;

@property (strong) SelectPathWindowController* selectPathWindowController;

@property (readwrite) NSThread* messagesThread;
@property (readwrite) MatcherInterface* matcherInterface;

@end


@implementation AppDelegate

@synthesize signInButton;
@synthesize signOutButton;
@synthesize selectDirButton;
@synthesize stickToLeftButton;
@synthesize stickToRightButton;
@synthesize selectPathWindowController;
@synthesize partiesComboBox;
@synthesize devicesComboBox;
@synthesize bpmComboBox;
@synthesize currentPartyId;
@synthesize messagesThread;
@synthesize matcherInterface;
@synthesize loginTextField;
@synthesize passwordTextField;
@synthesize progressIndicator;


-(void) threadMethod
{
    curlHelper.reset();
    
    while (![messagesThread isCancelled])
    {
        [commCenter updateMessages:currentPartyId];
        [NSThread sleepForTimeInterval:1.0f];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    gAppDelegate = self;
    gCurlHelper = &curlHelper;

    configuration = [[Configuration alloc] init];
    scheduler = [[Scheduler alloc] init];
    matcherRules = new MatcherRules();
    commCenter = [[CommunicationCenter alloc] init];

    [progressIndicator setHidden:YES];
    partiesComboBox.editable = NO;
    partyDictionary = [[NSMutableDictionary alloc] init];
    
    [_enableResetPartyButton setState:NSOffState];
    [_enableResetPartyButton setEnabled:NO];
    [_resetPartyButton setEnabled:NO];

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [self enableUi:NO];

    devicesComboBox.editable = NO;
    devicesArray = [[NSMutableArray alloc] init];
    matcherInterface = new MatcherInterface();
    std::vector< std::pair< CFStringRef, std::string > > audioDevices = matcherInterface->getInterfaceList();
    for (NSUInteger i = 0; i < audioDevices.size(); i++)
    {
        auto& p = audioDevices[i];
        NSLog(@"Device: %@ (%s)", p.first, p.second.c_str());

        NSString* strItem = [NSString stringWithUTF8String:p.second.c_str()];
        const NSString* deviceUid = (__bridge const NSString*) p.first;

        [devicesComboBox addItemWithObjectValue:strItem];
        [devicesArray addObject:deviceUid];
    }

    [devicesComboBox selectItemAtIndex:0];
    
    bpmComboBox.editable = NO;
    bpmArray = @[ @[@58, @115],
                  @[@68, @135],
                  @[@78, @155],
                  @[@88, @175],
                  @[@98, @195] ];
    [bpmComboBox removeAllItems];
    [bpmComboBox addItemWithObjectValue:@"58 - 115"];
    [bpmComboBox addItemWithObjectValue:@"68 - 135"];
    [bpmComboBox addItemWithObjectValue:@"78 - 155"];
    [bpmComboBox addItemWithObjectValue:@"88 - 175"];
    [bpmComboBox addItemWithObjectValue:@"98 - 195"];
    
    // choose the middle range by default
    [bpmComboBox selectItemAtIndex:2];
    [gConfiguration setBpmRange:bpmArray[[bpmComboBox indexOfSelectedItem]]];
    //[gMessageCenter setBPMRange:bpmRange];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [_sliderWindowController stopSliderThread];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (selectPathWindowController)
        [selectPathWindowController.window makeKeyAndOrderFront:self];
    return NO;
}

- (IBAction)selectDirButtonClicked:(id)sender
{
    selectPathWindowController = [[SelectPathWindowController alloc]
                                  initWithWindowNibName:@"SelectPathWindowController"];
    
    [selectPathWindowController.window makeKeyAndOrderFront:self];
    [self.window orderOut:selectPathWindowController];
    
   // [selectPathWindowController updateExistingSongsCounter];
    //[self.window orderOut:self];
    //[NSApp runModalForWindow: selectPathWindowController.window];
   // [selectPathWindowController.window makeKeyAndOrderFront:self];
    
}

- (IBAction)connectButtonClicked:(id)sender
{
    [progressIndicator setHidden:NO];
    [progressIndicator startAnimation:self];
    
    const char* login = [[loginTextField stringValue] UTF8String];
    const char* pass = [[passwordTextField stringValue] UTF8String];
    
    if (!curlHelper.signIn(login, pass))
    {
        showMessageBox("Unable to login", "Please check your login/password");
        [progressIndicator setHidden:YES];
        [progressIndicator stopAnimation:self];
        return;
    }
    
    [self enableUi:YES];
    
    //--------------------------------------------- Init parties combobox ---------------------------------------------------//
    
    std::string jsonString = curlHelper.partiesJSON();
    NSData* jsonData = [NSData dataWithBytes:jsonString.c_str() length:jsonString.length()];
    NSError *error = nil;
    
    if (!jsonData)
    {
        showMessageBox("JSON parsing error", "Description:Invalid JSON data");
    }
    
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error)
    {
        const char* err = [[error description] UTF8String];
        char msg[1024];
        sprintf(msg, "Description %s", err);
        showMessageBox("JSON parsing error", msg);
    }
    
    for (NSDictionary* dictionaryItem in jsonDictionary)
    {
        NSString* strItem = [NSString stringWithFormat:@"%@ - %@ (at %@)",
                             dictionaryItem[@"code"], dictionaryItem[@"name"], dictionaryItem[@"location"]];
    
        [partiesComboBox addItemWithObjectValue:strItem];
        [partyDictionary setObject:dictionaryItem[@"id"] forKey:strItem];
    }
    
    [partiesComboBox selectItemAtIndex:0];
    currentPartyId = [[ partyDictionary objectForKey:[partiesComboBox objectValueOfSelectedItem] ] stringValue];
    
    //==================================================================================================================//
    
    [progressIndicator setHidden:YES];
    [progressIndicator stopAnimation:self];
}

- (IBAction)signOut:(id)sender
{
    [messagesThread cancel];
    [self enableUi:NO];
    [partyDictionary removeAllObjects];
    curlHelper.signOut();
}

- (IBAction)sticktoLeftSideButtonPressed:(id)sender
{
    if (!_sliderWindowController)
         _sliderWindowController = [[SliderWindowController alloc] initWithWindowNibName:@"SliderWindow"];
    
    [self stopEventWatchingThread];
    [ _sliderWindowController setSide:defLeftSide];
    [_sliderWindowController startSliderThread];
    [self startEventWatchingThread];
    
    NSString* deviceUid = devicesArray[[devicesComboBox indexOfSelectedItem]];
    matcherInterface->start(deviceUid);

    [_window orderOut:NULL];
    
    NSLog(@"End!");
}

- (IBAction)stickToRightSideButtonPressed:(id)sender
{
    if (!_sliderWindowController)
        _sliderWindowController = [[SliderWindowController alloc] initWithWindowNibName:@"SliderWindow"];
    
    [self stopEventWatchingThread];
    [_sliderWindowController setSide:defRightSide];
    [_sliderWindowController startSliderThread];
    [self startEventWatchingThread];

    NSString* deviceUid = devicesArray[[devicesComboBox indexOfSelectedItem]];
    matcherInterface->start(deviceUid);

    [_window orderOut:NULL];
}

- (IBAction)partyComboxChanged:(id)sender
{
    currentPartyId = [[ partyDictionary objectForKey:[sender objectValueOfSelectedItem] ] stringValue];
}

- (IBAction)devicesComboboxChanged:(id)sender {
    NSString* deviceUid = devicesArray[[sender indexOfSelectedItem]];
    NSLog(@"Device: %@", deviceUid);
}

- (IBAction)bpmComboboxChanged:(id)sender {
    NSArray* bpmRange = bpmArray[[sender indexOfSelectedItem]];
    [gConfiguration setBpmRange:bpmRange];
    NSLog(@"BPM high: %@, BPM low: %@", bpmRange[0], bpmRange[1]);
}

- (IBAction)exitButtonPressed:(id)sender
{
    [[NSApplication sharedApplication] terminate:nil];
    //exit(0);
}

-(void) closeSlider
{
    [self stopEventWatchingThread];
    matcherInterface->stop();
    [self.window orderFrontRegardless];
    _sliderWindowController = nil;
}

-(void) showNotification:(NSString*)title withMessage:(NSString*)msg
{
    NSUserNotification *notification;
    notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = msg;
    notification.hasActionButton = NO;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (IBAction)enableResetPartyButton:(id)sender {
    [_resetPartyButton setEnabled:![_resetPartyButton isEnabled]];
}

- (IBAction)resetParty:(id)sender {
    curlHelper.resetParty([currentPartyId UTF8String]);
    [commCenter reset];
    showMessageBox("Party reset", "Party has been reset");
}

-(void) enableUi:(BOOL)flag
{
    if (flag)
    {
        selectDirButton.enabled = YES;
        stickToLeftButton.enabled = YES;
        stickToRightButton.enabled = YES;
        partiesComboBox.enabled = YES;
        signInButton.enabled = NO;
        signOutButton.enabled = YES;
        [_enableResetPartyButton setEnabled:YES];
    }
    else
    {
        [partiesComboBox removeAllItems ];
        selectDirButton.enabled = NO;
        stickToLeftButton.enabled = NO;
        stickToRightButton.enabled = NO;
        partiesComboBox.enabled = NO;
        signOutButton.enabled = NO;
        signInButton.enabled = YES;
        [_enableResetPartyButton setEnabled:NO];
        [_enableResetPartyButton setState:NSOffState];
        [_resetPartyButton setEnabled:NO];
    }
}

-(void) startEventWatchingThread
{
    messagesThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMethod) object:nil];
    [messagesThread start];
}

-(void) stopEventWatchingThread
{
    [messagesThread cancel];
}

@end
