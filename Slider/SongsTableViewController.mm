//
//  TableViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 15.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SongsTableViewController.h"
#import "SliderWindowController.h"
#import "DetailRequestViewController.h"
#import "MessageTableViewController.h"
#import "AppDelegate.h"
#import "SongEntity.h"
#import "MessageCenter.h"
#import "BPMDetectorInterface.h"
#import "Scheduler.h"
#import "Configuration.h"
#import "MatcherRules.h"

#define NSColorFromRGB(rgbValue) [NSColor colorWithCalibratedRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

SongsTableViewController* gSongsTableViewController = NULL;

@implementation SongsTableViewController
{
    DetailRequestViewController* detailRequestViewController;
    NSPopover* popover;
    NSUInteger lastKnownRequest;
    NSUInteger selectedRow;
    NSTimer* dataUpdateTimer;
    NSArray* orderedReqIds;
    NSMutableDictionary* currentlyPlaying;
}

@synthesize tableView;

- (void)awakeFromNib
{
    gSongsTableViewController = self;
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    currentlyPlaying = [[NSMutableDictionary alloc] init];

    // update the first one immediately
    [self updateData];

    // then schedule the subsequent ones
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
    
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    [tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
}

-(void)scheduleBPMCalc:(Request*)req
{
    // I tried to add a completion block but with this it would add all BPM analysis jobs first and then as they finish it would add more and more task completion jobs. Of course the completion jobs would be quick, so in the end nothing would happen and then all of a sudden all BPM values show up...
    
    dispatch_queue_t queue = [gScheduler serialAudioAnalysisQueue];
    NSArray* bpmRange = [gConfiguration bpmRange];

    dispatch_async(queue, ^{
        // don't do the BPM detection on completed requests
        if ([req complete])
            return;
        
        if ([req requestedFileExists])
        {
            // add BPMs
            // first try to read it
            NSString* bpmStr = nil;
            SongEntity *song = [[SongEntity alloc] initWithSongPath:[req requested_file]];
            int tagBPM = [song getBPMFromTag];
            if (tagBPM)
            {
                bpmStr = [NSString stringWithFormat:@"%dt", tagBPM];
            }
            else
            {
                float calcBPM = BPMDetect([[req requested_file] UTF8String]);
                // make sure it's not 0.0, otherwise we'd infinitely often multiply 0 * 2 or so
                if (calcBPM > 1.0f) {
                    while (calcBPM < [bpmRange[0] floatValue])
                    {
                        // need to increase
                        calcBPM *= 2.0f;
                    }
                    while (calcBPM > [bpmRange[1] floatValue])
                    {
                        // need to decrease
                        calcBPM /= 2.0f;
                    }
                }
                bpmStr = [NSString stringWithFormat:@"%dc", (int) (calcBPM + 0.5f)];
            }
            
            if (bpmStr)
            {
                [req setBpm:bpmStr];
            }
        }
    });
}

-(void)updateData
{
    RequestCollection* reqColl = [gCommCenter requestCollection];
    orderedReqIds = [reqColl orderedByDate];

    // get a hash of the songs currently playing
    [currentlyPlaying removeAllObjects];
    std::vector< std::string > playing = gMatcherRules->getCurrentlyPlaying();
    for (auto x : playing) {
        NSString* y = [NSString stringWithUTF8String:x.c_str()];
        [currentlyPlaying setValue:@1 forKey:y];
    }

    for (NSNumber* reqId in orderedReqIds) {
        Request* req = [reqColl byId:reqId];
        // only schedule if bpm is nil, so set it to non-nil, then schedule so that it's not scheduled twice ever
        if (![req bpm] && [req requestedFileExists]) {
            [req setBpm:@""];
            [self scheduleBPMCalc:req];
        }
    }

    [tableView reloadData];
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)rowIndex
{
    RequestCollection* reqColl = [gCommCenter requestCollection];
    NSNumber* reqId = orderedReqIds[rowIndex];
    Request* req = [reqColl byId:reqId];
    
    SongEntity* songEntity = [[SongEntity alloc] initWithSongPath:[req requested_file]];
    
    return songEntity;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSUInteger count = [orderedReqIds count];
    [self.countOfSongsField setStringValue:[NSString stringWithFormat:@"%lu",
                                            (unsigned long)count]];
    return count;
}

- (NSMutableAttributedString*)colorizeString:(NSString*)string withColor:(NSColor*)color
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc]
                                             initWithString:string];
    NSMutableParagraphStyle *paragraph;
    paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraph.hyphenationFactor = 1.0;
    paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [attrString addAttribute:NSForegroundColorAttributeName
                       value:color range:NSMakeRange(0, [attrString length])];
    
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [attrString length])];

    return attrString;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    RequestCollection* reqColl = [gCommCenter requestCollection];
    if (rowIndex >= [orderedReqIds count])
        return nil;

    NSNumber* reqId = orderedReqIds[rowIndex];
    Request* req = [reqColl byId:reqId];

    NSColor *applyColor = nil;
    bool fileExists = ([req requestedFileExists] == YES);

    NSString* itemString = [req display];

    if (![req haveSeenAllMessages])
    {
        // add the incoming messages icon
        itemString = [NSString stringWithFormat:@"📩 %@", itemString];

        // if the file exists, color the request blue, if not, it will become red further down
        applyColor = [NSColor blueColor];
    }
    else if ([req initialMessage])
    {
        // we have a message in the request already, so put the messages icon
        itemString = [NSString stringWithFormat:@"✉️ %@", itemString];
    }
    else
    {
        // we have a message for this request in the messages, so put the messages icon
        NSArray* msgs = [req messages];
        if ([msgs count] > 0)
        {
            itemString = [NSString stringWithFormat:@"✉️ %@", itemString];
        }
    }

    if (!fileExists)
    {
        // return here, the rest is for existing files only
        return [self colorizeString:itemString withColor:[NSColor redColor]];
    }
    
    // here we know it's reachable on disk
    
    if ([req bpm]) {
        itemString = [NSString stringWithFormat:@"%@ - %@", [req bpm], itemString];
    }

    if ([currentlyPlaying objectForKey:[req requested_file]]) {
        itemString = [NSString stringWithFormat:@"🔊 %@", itemString];
    }
    
    if ([req complete])
    {
        // don't use applyColor, we also need to add the strikethrough attribute, so we'll colorize ourselves
        NSMutableAttributedString* attrStr = [self colorizeString:itemString withColor:NSColorFromRGB(0x009900)];
        [attrStr addAttributes:
         @{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}
                         range:NSMakeRange(0, [attrStr length])];
        return attrStr;
    }

    if (applyColor)
        return [self colorizeString:itemString withColor:applyColor];
    else
        return itemString;
}

- (IBAction)rowClicked:(id)sender
{
    selectedRow = [tableView selectedRow];
    
    if (selectedRow != -1)
    {
        [self closeDetailWindow];
        
        [gMessageTableViewController closeDetailWindow];

        RequestCollection* reqColl = [gCommCenter requestCollection];
        NSNumber* reqId = orderedReqIds[selectedRow];
        Request* req = [reqColl byId:reqId];
        
        detailRequestViewController =
        [[DetailRequestViewController alloc] initWithNibName:@"DetailRequestViewController"
                                                      bundle:nil
                                                  andRequest:req];
        
        CGFloat width = [detailRequestViewController.view bounds].size.width;
        CGFloat height = [detailRequestViewController.view bounds].size.height;

        popover = [[NSPopover alloc] init];
        [popover setContentSize:NSMakeSize(width,height)];
        [popover setContentViewController:detailRequestViewController];
        [popover setAnimates:YES];
    
        NSRect rect = [tableView frameOfCellAtColumn:0 row:[tableView selectedRow]];
    
        rect.size.width = [gSliderWindowController maxWidth];
        [popover showRelativeToRect:rect ofView:tableView preferredEdge:NSMaxXEdge];
    }
}

-(void) closeDetailWindow
{
    [popover close];
}


@end
