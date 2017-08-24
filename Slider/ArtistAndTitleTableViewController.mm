//
//  ArtistAndTitleTableViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 29.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "ArtistAndTitleTableViewController.h"
#import <tag/fileref.h>
#import <tag/tstring.h>
#import <tag/popularimeterframe.h>
#import <tag/id3v2frame.h>
#import <tag/id3v2header.h>
#import <tag/id3v1tag.h>
#import <tag/mp4file.h>
#import <tag/tag.h>
#import <tag/tmap.h>
#import <tag/tstringlist.h>
#import <tag/textidentificationframe.h>
#include <tag/id3v2tag.h>
#import "CurlHelper.h"
#import "FPInterface.h"
#import "AppDelegate.h"
#import "MessageCenter.h"
#import "SongEntity.h"
#import "Scheduler.h"
#include "MatcherRules.h"

ArtistAndTitleTableViewController *gArtistAndTitleTableViewController;

@implementation ArtistAndTitleTableViewController
{
    // songArray is an NSMutableArray of NSMutableDictionaries:

    // @"open": @1 or @0
    // @"song": (SongEntity*) for tags to display
    // @"up": number of upvotes
    // @"down": number of downvotes

    // we always add to the bottom, so the oldest is first, but we display in reverse

    NSMutableArray* songArray;
    NSMutableSet* currentlyPlaying;
    NSTimer* dataUpdateTimer;
    NSTimer* timeForWebRequest;
    NSUInteger lastSelectedRow;
    BOOL isAutoBroadcastEnabled;
    NSMutableDictionary* fingerprints;
    NSString* lastBroadcastFile;
    NSString* lastNotifiedFile;
}

@synthesize tableView;
@synthesize lastPostedSongName;

- (void)awakeFromNib
{
    gArtistAndTitleTableViewController = self;
    
    songArray = [[NSMutableArray alloc] init];
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
    fingerprints = [[NSMutableDictionary alloc] init];

    isAutoBroadcastEnabled = YES;
    lastBroadcastFile = @"";

    currentlyPlaying = [[NSMutableSet alloc] init];

    // update the first one immediately
    [self updateData];
    
    // then schedule the subsequent ones
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
}

-(void) clear
{
    [dataUpdateTimer invalidate];
    [songArray removeAllObjects];
    gMatcherRules->clear();
    [tableView reloadData];
}

-(void)updateData
{
    // get an NSMutableSet of the songs currently playing
    // Don't touch currentlyPlaying because we want to compare
    NSMutableSet* allCurrentlyPlaying = [[NSMutableSet alloc] init];
    std::vector< std::string > playing = gMatcherRules->getCurrentlyPlaying();
    for (auto x : playing) {
        NSString* y = [NSString stringWithUTF8String:x.c_str()];
        [allCurrentlyPlaying addObject:y];
    }

    // find the new songs that are playing now that haven't been played before
    NSMutableSet *modCurrentlyPlaying = [allCurrentlyPlaying mutableCopy];
    [modCurrentlyPlaying minusSet:currentlyPlaying];
    
    NSLog(@"New songs playing:");
    for (id i in [modCurrentlyPlaying allObjects]) {
        NSLog(@"  %@", i);
    }
    
    // what remains in modCurrentlyPlaying is new songs
    for (NSString* filename in modCurrentlyPlaying) {
        // Yes
        SongEntity* s = [[SongEntity alloc] initWithSongPath:filename];
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           if (!lastNotifiedFile || ![[s path] isEqualToString:lastNotifiedFile]) {
                               // show a notification if we have a new song playing
                               [gAppDelegate
                                showNotification:@"New song playing"
                                withMessage:[s display]];

                               lastNotifiedFile = [s path];
                           }
                       });
        
        if (isAutoBroadcastEnabled) {
            dispatch_queue_t queue = [gScheduler serialWebRequestQueue];
            dispatch_async(queue,
                           ^{
                               [self broadcastSong:s];
                           });
        }
        
        // XXX We need something to not throw out multiple notifications and broadcasts for the same song. Thinking something like we always only throw out the oldest index of the songArray being played currently. The hypothesis is that if we have multiple songs playing, they're just different copies of the same song. We choose the oldest index to have something stable.
    }
    
    // XXX What if the DJ has some mp3 of silence or white noise open that for some reason just matches anything now? Could this happen?

    currentlyPlaying = allCurrentlyPlaying;

    RequestCollection* reqColl = [gCommCenter requestCollection];
    
    std::vector< std::pair< time_t, std::string > > completedFiles = gMatcherRules->getCompleted();
    for (auto p : completedFiles) {
        time_t startTime = p.first;
        const std::string& x = p.second;
        NSString* s = [NSString stringWithUTF8String:x.c_str()];
        NSArray* arr = [reqColl byFile:s];
        for (Request* req in arr)
        {
            // we know that the request is both playing and completed. If it hasn't been marked completed OR the last recorded end-time is over 3s old, re-update. Every update goes out to the server also, which is why we have this 3s delay
            if (![req complete] || [[[req time_played_end] dateByAddingTimeInterval:3] isLessThan:[NSDate date]])
            {
                SongEntity* song = [[SongEntity alloc] initWithSongPath:s];
                [req completeWithSong:song
                              inParty:[gAppDelegate currentPartyId]
                          withStarted:[NSDate dateWithTimeIntervalSince1970:startTime]];
                
                NSString *reqId = [NSString stringWithFormat:@"%@", [req reqId]];
                NSString *partyId = [NSString stringWithFormat:@"%@", [gAppDelegate currentPartyId]];
                NSUInteger played_begin = [[req time_played_begin] timeIntervalSince1970];
                NSUInteger played_end = [[req time_played_end] timeIntervalSince1970];
                
                dispatch_queue_t queue = [gScheduler serialWebRequestQueue];
                dispatch_async(queue,
                               ^{
                                   gCurlHelper->completeRequest([reqId UTF8String],
                                                                [partyId UTF8String],
                                                                played_begin, played_end,
                                                                [[req played_file] UTF8String],
                                                                [[req artist] UTF8String],
                                                                [[req title] UTF8String]);
                               });
            }
        }
    }

    [tableView reloadData];
}

-(void) addNewSong:(NSString*)filename withOpen:(NSNumber*)withOpen
{
    // add to the songArray with no further checks. Special case is that it had been added manuallly before via drag&drop, it could even be the active song now (set manually as well), which is why I don't want to try and delete it if it's there already
    
    BOOL found = NO;
    for (NSUInteger i = 0; i < [songArray count]; i++) {
        SongEntity* song = songArray[i][@"song"];
        NSMutableDictionary *dict = songArray[i];
        if ([[song path] isEqualToString:filename]) {
            found = YES;
            dict[@"open"] = withOpen;
            break;
        }
    }
    
    if (!found) {
        SongEntity* s = [[SongEntity alloc] initWithSongPath:filename];
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        d[@"open"] = withOpen;
        d[@"song"] = s;
        [songArray addObject:d];
    }
    
    // schedule a refresh
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [tableView reloadData];
                   });
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = info.draggingPasteboard;
    NSArray* acceptedTypes = [NSArray arrayWithObject:(NSString*)kUTTypeAudio];
    
    NSArray* urls = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                                                           options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithBool:YES],NSPasteboardURLReadingFileURLsOnlyKey,
                                                                    acceptedTypes, NSPasteboardURLReadingContentsConformToTypesKey,
                                                                    nil]];
    if(urls.count != 1)
        return NSDragOperationNone;
    
    NSString* path = [[urls objectAtIndex:0] path];

    // Add a new song to songArray but not to the MatcherRules. Don't add it as open because we haven't seen it open
    [self addNewSong:path withOpen:@0];

    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationEvery;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [songArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // display the songArray reverse to show the most recently added files on top
    NSAssert([songArray count] > rowIndex, @"Invalid index for songArray");
    NSInteger songArrayIdx = [songArray count] - rowIndex - 1;
    NSDictionary* dict = [songArray objectAtIndex:songArrayIdx];
    SongEntity* song = dict[@"song"];
    NSString* display = [song display];
    int up = [[dict valueForKey:@"up"] intValue];
    int down = [[dict valueForKey:@"down"] intValue];
    if (up > 0 || down > 0)
    {
        // Prefix with the votes
        display = [NSString stringWithFormat:@"(+%d -%d) %@", up, down, display];
    }

    // check if the song is playing
    if ([currentlyPlaying containsObject:[song path]]) {
        display = [NSString stringWithFormat:@"🔊 %@", display];
    }

    if (![dict[@"active"] intValue])
    {
        NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc]
                                                 initWithString:display];
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:[NSColor grayColor] range:NSMakeRange(0, [attrString length])];

        NSMutableParagraphStyle *paragraph;
        paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraph.hyphenationFactor = 1.0;
        paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [attrString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [attrString length])];

        return attrString;
    }
    else
        return display;
}

-(void) disableAutoBroadcast
{
    NSLog(@"Disable autoBroadcast");
    isAutoBroadcastEnabled = NO;
}

-(void) enableAutoBroadcast
{
    NSLog(@"Enable autoBroadcast");
    isAutoBroadcastEnabled = YES;
}

-(void) broadcastSong:(SongEntity*)song
{
    NSString* artist = [song artist];
    NSString* title = [song title];
    NSString* path = [song path];

    // don't broadcast a song twice
    if ([path isEqual:lastBroadcastFile]) {
        return;
    }
    
    lastBroadcastFile = [path copy];

#ifdef _DEBUG
    NSLog(@"Song info for web request-> Artist:%@, Title:%@, Path:%@",artist, title, path);
#endif

    NSString* partyId = [gAppDelegate currentPartyId];
    NSTimeInterval timeInSeconds = [[NSDate date] timeIntervalSince1970];
    NSString* timeStr = [NSString stringWithFormat:@"%d", (int) timeInSeconds];

    dispatch_queue_t queue = [gScheduler serialWebRequestQueue];
    dispatch_async(queue,
                   ^{
                       NSDictionary* fp = fingerprints[path];
                       NSString* fpString;
                       int fpDuration;
                       if (!fp) {
                           fpString = @"";
                           fpDuration = 0;
                       } else {
                           fpString = fp[@"fp"];
                           fpDuration = [fp[@"duration"] intValue];
                       }

                       gCurlHelper->postSelectedSong([partyId UTF8String],
                                                     [artist UTF8String],
                                                     [title UTF8String],
                                                     [path UTF8String],
                                                     [timeStr UTF8String],
                                                     [fpString UTF8String],
                                                     fpDuration);
                   });
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [lastPostedSongName setStringValue:[NSString stringWithFormat:@"📡: %@",
                                                           [song display]]];
                   });
}

- (IBAction)tableViewWasClicked:(id)sender
{
    [timeForWebRequest invalidate];
    timeForWebRequest = nil;
    
    lastSelectedRow = [tableView selectedRow];
  
    if (-1 == lastSelectedRow) return;
    
    timeForWebRequest = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                        target:self
                                                        selector:@selector(timerForWebRequestMethod)
                                                        userInfo:nil
                                                        repeats:NO];
}

-(void) makeFirstResponder
{
    [[tableView window] makeFirstResponder:tableView];
}

-(void) timerForWebRequestMethod
{
    if ([tableView selectedRow] >= [songArray count]) return;
    
    if ([tableView selectedRow] == lastSelectedRow)
    {
        NSLog(@"Try make send web request %ld", (long)[tableView selectedRow]);
        
        NSInteger songArrayIdx = [songArray count] - [tableView selectedRow] - 1;
        NSDictionary* dict = [songArray objectAtIndex:songArrayIdx];
        SongEntity* song = dict[@"song"];

        // tags would be nil if it didn't exist
        if ([song fileExists])
            [self broadcastSong:song];
    }
}

-(void) fileOpened:(NSString*)filename
{
    gMatcherRules->fileOpened([filename UTF8String]);
    [self addNewSong:filename withOpen:@1];

    dispatch_queue_t queue = [gScheduler serialAudioAnalysisQueue];
    dispatch_async(queue, ^{
        NSURL *url = [NSURL fileURLWithPath:filename isDirectory:NO];
        NSError* err;
        if ([url checkResourceIsReachableAndReturnError:&err] == YES)
        {
            int duration;
            std::string fpc;
            if (getChromaprintFP([filename UTF8String], fpc, duration) == 0)
            {
                NSDictionary* fp = @{
                                     @"duration": [NSNumber numberWithInt:duration],
                                     @"fp": [NSString stringWithUTF8String:fpc.c_str()]
                                     };
                [fingerprints setObject:fp forKey:filename];
            }
        }
    });
}

-(void) fileClosed:(NSString*)filename
{
    gMatcherRules->fileClosed([filename UTF8String]);

    // Assumes we have each song at most once, come from the end, which is where the most recently opened files are
    for (NSUInteger i = [songArray count]; i > 0; i--) {
        NSMutableDictionary* dict = songArray[i-1];
        if ([[dict[@"song"] path] isEqualToString:filename] && [dict[@"open"] intValue]) {
            dict[@"open"] = @0;
            // should have each only once open, so we can exit once we've found it
            break;
        }
    }
    [fingerprints removeObjectForKey:filename];

    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [tableView reloadData];
                   });
}

-(void) filePlaying:(NSString*)filename withScore:(float)score
{
    gMatcherRules->addDP([filename UTF8String], score);
}

-(NSUInteger) addNewVotes:(NSArray*)messages
{
    NSUInteger maxSequence = 0;
    // this scans the messages and then iterates through every array element to find the same file
    // this is quite inefficient but we expect to run this only on new playlist entries that have been created since we last checked and second we're only gonna have a few elements in the current song list anyway
    NSDictionary* pe;
    for (pe in messages)
    {
        NSString* up = pe[@"up"];
        NSString* down = pe[@"down"];
        NSString* path = pe[@"filename"];
        NSUInteger seq = [pe[@"party_seq"] intValue];

        if (seq > maxSequence)
        {
            maxSequence = seq;
        }

        for (NSUInteger i = 0; i < [songArray count]; i++) {
            NSMutableDictionary *dict = songArray[i];
            if ([[[dict valueForKey:@"song"] path] isEqualToString:path]) {
                [dict setValue:up forKey:@"up"];
                [dict setValue:down forKey:@"down"];
                break;
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [tableView reloadData];
                   });
    return maxSequence;
}

@end
