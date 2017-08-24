//
//  MatcherInterface.mm
//  Slider
//
//  Created by jwieland on 1/24/16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <iostream>
#import <functional>

#import "ArtistAndTitleTableViewController.h"
#import "MatcherInterface.h"
#import "Matcher.hpp"
#import "MatcherRules.h"

extern NSString *myPath;
static BOOL wantRestart;

void callbackOpened(NSString* filename)
{
    [gArtistAndTitleTableViewController fileOpened:filename];
}

void callbackPlaying(NSString* line)
{
    NSRange range = [line rangeOfString:@" "];
    NSString *filename = [line substringFromIndex:NSMaxRange(range)];
    NSString *score = [line substringToIndex:range.location];

    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *fscore = [f numberFromString:score];

    [gArtistAndTitleTableViewController filePlaying:filename withScore:[fscore floatValue]];
}

void callbackClosed(NSString* filename)
{
    [gArtistAndTitleTableViewController fileClosed:filename];
}

@implementation matcherStartupWrapper
{
    NSTask *task;
    NSThread* thread;
    NSString* deviceUid;
    NSPipe* cmds;
}

-(instancetype) initWithDevice:(NSString*)_deviceUid
{
    self = [super init];
    self->deviceUid = _deviceUid;
    return self;
}

-(void)stop
{
    wantRestart = NO;
    [task terminate];
}

-(void)pause
{
    NSFileHandle *writer = [cmds fileHandleForWriting];
    NSString * message = @"PAUSE\n";
    [writer writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)resume
{
    NSFileHandle *writer = [cmds fileHandleForWriting];
    NSString * message = @"RESUME\n";
    [writer writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)matcherStartThread
{
    while (wantRestart)
    {
        cmds = [[NSPipe alloc] init];
        NSPipe* results = [[NSPipe alloc] init];
        NSPipe* log = [[NSPipe alloc] init];
        
        self->task = [[NSTask alloc] init];
        
        // NSTask run ourselves passing in the device
        [task setLaunchPath:myPath];
        [task setArguments:[NSArray arrayWithObjects:@"-matcher", deviceUid, nil]];
        
        // stdin, stdout, stderr from the task's perspective
        [task setStandardInput:cmds];
        [task setStandardOutput:results];
        [task setStandardError:log];
        
        [[results fileHandleForReading] waitForDataInBackgroundAndNotify];
        [[log fileHandleForReading] waitForDataInBackgroundAndNotify];
        
        // Wait asynchronously for results
        id ob1 = [[NSNotificationCenter defaultCenter]
                  addObserverForName:NSFileHandleDataAvailableNotification
                  object:[results fileHandleForReading] queue:nil
                  usingBlock:^(NSNotification *note)
                  {
                      // Read in the results
                      NSData *resData = [[results fileHandleForReading] availableData];
                      NSString *resStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
                      NSLog(@"results: %@", resStr);
                      
                      // cut \n
                      resStr = [resStr stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                      NSArray *lines = [resStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                      
                      for (NSString* line in lines) {
                          if ([line hasPrefix:@"OPENED "])
                          {
                              callbackOpened([line substringFromIndex: [@"OPENED " length]]);
                          }
                          else if ([line hasPrefix:@"CLOSED "])
                          {
                              callbackClosed([line substringFromIndex: [@"CLOSED " length]]);
                          }
                          else if ([line hasPrefix:@"PLAYING "])
                          {
                              callbackPlaying([line substringFromIndex: [@"PLAYING " length]]);
                          }
                      }
                      
                      // Continue waiting for more results.
                      [[results fileHandleForReading] waitForDataInBackgroundAndNotify];
                  }];
        
        // Wait asynchronously for results
        id ob2 = [[NSNotificationCenter defaultCenter]
                  addObserverForName:NSFileHandleDataAvailableNotification
                  object:[log fileHandleForReading] queue:nil
                  usingBlock:^(NSNotification *note)
                  {
                      // Read in the results
                      NSData *logData = [[log fileHandleForReading] availableData];
                      NSString *logStr = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding];
                      NSLog(@"log: %@", logStr);
                      
                      // Continue waiting for more results.
                      [[log fileHandleForReading] waitForDataInBackgroundAndNotify];
                  }];
        
        [task launch];
        [task waitUntilExit];
        
        [[NSNotificationCenter defaultCenter] removeObserver:ob1];
        [[NSNotificationCenter defaultCenter] removeObserver:ob2];
        
        [[results fileHandleForReading] closeFile];
        [[log fileHandleForReading] closeFile];
        [[cmds fileHandleForWriting] closeFile];
        
        // so we're not in a tight loop restarting over and over. Ideally we'd back off exponentially
        if (wantRestart)
        {
            sleep(5);
            NSLog(@"Restarting the matcher...");
        }
        else
        {
            NSLog(@"Matcher terminating...");
        }
    }
}

-(void)startMatcherInThread
{
    self->thread = [[NSThread alloc] initWithTarget:self
                                           selector:@selector(matcherStartThread)
                                             object:nil];
    [self->thread start];  // Actually create the thread
}
@end

void MatcherInterface::start(NSString* deviceUid)
{
    using cbT = std::function<void(const std::string& file)>;

    wantRestart = YES;
    matcherStarter = [[matcherStartupWrapper alloc] initWithDevice:deviceUid];
    [matcherStarter startMatcherInThread];
}

void MatcherInterface::stop()
{
    if (matcherStarter)
    {
        [matcherStarter stop];
        matcherStarter = nil;
    }
}

void MatcherInterface::pause()
{
    [matcherStarter pause];
}

void MatcherInterface::resume()
{
    [matcherStarter resume];
}

std::vector< std::pair< CFStringRef, std::string > > MatcherInterface::getInterfaceList(void) {
    return matcher->getInterfaceList();
}
