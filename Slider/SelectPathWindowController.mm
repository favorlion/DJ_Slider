//
//  SelectPathWindowController.m
//  Slider
//
//  Created by Dmitry Volkov on 28.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SelectPathWindowController.h"
#import "CurlHelper.h"
#import "AppDelegate.h"
#import "SongEntity.h"
#import "BZipCompression.h"
#import <AVFoundation/AVFoundation.h>

#define NSColorFromRGB(rgbValue) [NSColor colorWithCalibratedRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation SelectPathWindowController
{
    NSMutableArray* jsonDictionaryArray;
    NSInvocationOperation* searchingSongsOperation;
    NSOperationQueue* queue;
    NSMutableArray* filesForAddToCollectionArray;
    NSMutableArray* existingFilesInCollectionArray;
    
    AVAudioPlayer* audioPlayer;
}

@synthesize filesForAddToCollectionTableView;
@synthesize existingFilesTableView;
@synthesize searchSongField;


-(void) updateExistingSongsCounter
{
    [self.songsCountExisting setIntValue:(int)[existingFilesInCollectionArray count]];
}

-(void) updateNewSongsCounter
{
    [self.songsCountNew setIntValue:(int)[filesForAddToCollectionArray count]];
}

-(id) initWithWindowNibName:(NSString*) windowNibName
{
    self = [super initWithWindowNibName:windowNibName owner:self];
    
    jsonDictionaryArray = [[NSMutableArray alloc] init];
    filesForAddToCollectionArray = [[NSMutableArray alloc] init];
    queue = [NSOperationQueue new];
    
    gCurlHelper->reset();
    
    NSData* jsonData = gCurlHelper->inventoryJSON([[gAppDelegate currentPartyId] UTF8String]);

    if (!jsonData)
    {
        jsonData = [@"[]" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSError *error = nil;
    
    existingFilesInCollectionArray = [NSJSONSerialization
                                      JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
//
//    [filesForAddToCollectionTableView
//     registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
//    
//    [filesForAddToCollectionTableView
//     setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    
    
    
    
    // Construct URL to sound file
//    NSString *path = @"/Volumes/Macintosh Media/ Sunrise Avenue - Hollywood Hills";
//    NSURL *soundUrl = [NSURL fileURLWithPath:path];
//    
//    // Create audio player object and initialize with URL to sound
//    
//   audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
//    
    return self;
}

-(void)awakeFromNib
{
    [filesForAddToCollectionTableView registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
    [filesForAddToCollectionTableView  setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    [self updateExistingSongsCounter];
    [self updateNewSongsCounter];
    
    if ([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        return  [filesForAddToCollectionArray count];
    }
    
    if ([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        return [existingFilesInCollectionArray count];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSDictionary* dictionary;
    
    if([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        if (rowIndex >= filesForAddToCollectionArray.count)
            return nil;
        
        dictionary = [filesForAddToCollectionArray objectAtIndex:rowIndex];
        
        if([[aTableColumn identifier] isEqualToString:@"Title"])
        {
            if (![dictionary[@"valid"] integerValue] && [dictionary[@"title"] length] == 0)
                return @"err: No title set in metadata";

            return [dictionary valueForKey:@"title"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Artist"])
        {
            if (![dictionary[@"valid"] integerValue] && [dictionary[@"artist"] length] == 0)
                return @"err: No artist set in metadata";

            return [dictionary valueForKey:@"artist"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Filepath"])
        {
            
            return [dictionary valueForKey:@"filename"];
        }
    }

    if([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        // For prevent case when don't receive valid json from server and 'existingFilesInCollectionArray' is empty
        if (0 == existingFilesInCollectionArray.count)
            return nil;
        
        dictionary = [existingFilesInCollectionArray objectAtIndex:rowIndex];
        
        if([[aTableColumn identifier] isEqualToString:@"Title"])
        {
            return [dictionary valueForKey:@"title"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Artist"])
        {
            return [dictionary valueForKey:@"artist"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Filepath"])
        {
            return [dictionary valueForKey:@"filename"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Comment"])
        {
            return [dictionary valueForKey:@"comment"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Fav"])
        {
            id ss = [dictionary valueForKey:@"isfav"];
            // return true if "isfav" exists AND is set to true
            return [NSNumber numberWithInteger:(ss != [NSNull null] && [ss boolValue] ? NSOnState : NSOffState)];
        }

    }
    
    return nil;
}

- (void)tableView:(NSTableView *)aTableView
  willDisplayCell:(id)inCell
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    if([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        NSDictionary* dictionary = [filesForAddToCollectionArray objectAtIndex:rowIndex];
        if ([dictionary[@"valid"] integerValue])
        {
            [inCell setDrawsBackground:NO];
        }
        else
        {
            // invalid
            [inCell setBackgroundColor: NSColorFromRGB(0xffcccc)];
            [inCell setDrawsBackground:YES];
        }
    }
}

-(void) addNewSongToPreCollectionArray:(NSURL*) url
{
    SongEntity *song = [[SongEntity alloc] initWithSongPath:[url path]];
    NSMutableDictionary* dictionary = [[song getTags] mutableCopy];
    
    id valid = @YES;
    if (![song artist] || [[song artist] length] == 0)
    {
        valid = @NO;
    }
    if (![song title] || [[song title] length] == 0)
    {
        valid = @NO;
    }

    dictionary[@"valid"] = valid;

    // the object needs to stay mutable, because we might want to add the favorites flag
    [filesForAddToCollectionArray addObject:dictionary];

    dispatch_async(dispatch_get_main_queue(), ^{
        [filesForAddToCollectionTableView reloadData];
        [filesForAddToCollectionTableView.window update];
        [self updateNewSongsCounter];
    });
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = info.draggingPasteboard;
    NSArray* acceptedTypes = [NSArray arrayWithObjects:
                              (NSString*)kUTTypeAudio,
                              (NSString*)kUTTypeFolder,
                              nil];
    
    NSArray* urlArray = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                                      options:[NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithBool:YES],NSPasteboardURLReadingFileURLsOnlyKey,
                                               acceptedTypes, NSPasteboardURLReadingContentsConformToTypesKey,
                                               nil]];
    
    for (id url in urlArray)
    {
        
        NSNumber* isDir;
        
        BOOL bOk = [url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
        
        if (bOk && [isDir boolValue])
        {
            NSArray* directoryArray = [NSArray arrayWithObject:url];
            
            searchingSongsOperation = [[NSInvocationOperation alloc]
                                       initWithTarget:self selector:@selector(operationMethodForSearchingFiles:) object:directoryArray];
            
            [queue addOperation:searchingSongsOperation];
        }
        else
        {
            [self addNewSongToPreCollectionArray:url];
        }
    }
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationEvery;
}


-(void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    
    if([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        NSArray *newDescriptors = [filesForAddToCollectionTableView sortDescriptors];
        [filesForAddToCollectionArray sortUsingDescriptors:newDescriptors];
        [filesForAddToCollectionTableView reloadData];
    }
    
    if([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        NSArray *newDescriptors = [existingFilesTableView sortDescriptors];
        [existingFilesInCollectionArray sortUsingDescriptors:newDescriptors];
        [existingFilesTableView reloadData];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
   if (row < [existingFilesInCollectionArray count])
   {
       NSMutableDictionary* dict = existingFilesInCollectionArray[row];
       [dict setValue:value forKey:@"isfav"];
       [existingFilesInCollectionArray replaceObjectAtIndex:row withObject:dict];
       [existingFilesTableView reloadData];
   }
}

-(void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    
}

- (IBAction)addPathButtonClicked:(id)sender
{
    NSOpenPanel* selectPanel = [NSOpenPanel openPanel];
    
    selectPanel.title = @"Select directory for searching mp3 files";
    selectPanel.showsResizeIndicator = YES;
    selectPanel.showsHiddenFiles = NO;
    selectPanel.canChooseDirectories = YES;
    selectPanel.canChooseFiles = NO;
    selectPanel.allowsMultipleSelection = YES;
    
    [selectPanel setPrompt:@"Select"];
    [selectPanel runModal];
    
    NSArray* directoryArray = [selectPanel URLs];
    
    searchingSongsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(operationMethodForSearchingFiles:) object:directoryArray];
    
    [queue addOperation:searchingSongsOperation];
}

- (IBAction)selectAllFilesForAddToCollection:(id)sender
{
    [filesForAddToCollectionTableView selectAll:self];
}
- (IBAction)unselectAllFilesForAddToCollection:(id)sender
{
    [filesForAddToCollectionTableView deselectAll:self];
}

- (IBAction)selectAllFileInCollection:(id)sender
{
    [existingFilesTableView selectAll:self];
}

- (IBAction)unselectAllFilesInCollection:(id)sender
{
    [existingFilesTableView deselectAll:self];
}

- (IBAction)removeSelectedetFilesFromAddToCollection:(id)sender
{
    NSIndexSet* selectedRowIndexes = [filesForAddToCollectionTableView selectedRowIndexes];
    [filesForAddToCollectionArray removeObjectsAtIndexes:selectedRowIndexes];
    [filesForAddToCollectionTableView reloadData];
    [self updateNewSongsCounter];
}

- (IBAction)removeSelectedFilesFromCollection:(id)sender
{
    NSIndexSet* selectedRowIndexes = [existingFilesTableView selectedRowIndexes];
    [existingFilesInCollectionArray removeObjectsAtIndexes:selectedRowIndexes];
    [existingFilesTableView reloadData];
    [self updateExistingSongsCounter];
}

- (IBAction)addToCollectionSelectedFiles:(id)sender
{
    NSMutableIndexSet* selectedRowIndexes = [[filesForAddToCollectionTableView selectedRowIndexes] mutableCopy];

    if ([selectedRowIndexes count] == 0)
    {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText: @"No songs selected. Please select the songs you want to add to the collection"];
        [alert setAlertStyle: NSWarningAlertStyle];
        [alert runModal];
    }
    else
    {
        // walk over the selected rows and automatically un-select all invalid songs
        NSUInteger index = [selectedRowIndexes firstIndex];

        while(index != NSNotFound) {
            id valid = [filesForAddToCollectionArray objectAtIndex:index][@"valid"];
            if (![valid integerValue])
            {
                [selectedRowIndexes removeIndex:index];
            }
            index = [selectedRowIndexes indexGreaterThanIndex:index];
        }

        NSArray* selectedSongs = [filesForAddToCollectionArray objectsAtIndexes:selectedRowIndexes];
        [existingFilesInCollectionArray addObjectsFromArray:selectedSongs];
        [existingFilesTableView reloadData];
        [self updateNewSongsCounter];

        [filesForAddToCollectionArray removeObjectsAtIndexes:selectedRowIndexes];
        [filesForAddToCollectionTableView deselectAll:self];
        [filesForAddToCollectionTableView reloadData];
        [self updateExistingSongsCounter];
    }
}


- (IBAction)searchSongFieldEditing:(id)sender
{
    
}

- (IBAction)uploadButtonClicked:(id)sender
{
    NSIndexSet* selectedRowIndexes = [existingFilesTableView selectedRowIndexes];
    
    if ([selectedRowIndexes count] > 0)
    {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Continue"];
        [alert setMessageText: @"You have selected songs, but this operation will upload the metadata of your entire collection to the server, not only the selected songs. Continue ?"];
        [alert setAlertStyle: NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            return;
        }
    }
    
    NSMutableArray* selectedFiles = [[NSMutableArray alloc] init];
    
    selectedFiles = existingFilesInCollectionArray;

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:selectedFiles
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSData *compressedData = [BZipCompression compressedDataWithData:jsonData
                                                           blockSize:BZipDefaultBlockSize
                                                          workFactor:BZipDefaultWorkFactor
                                                               error:&error];

    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"inventory.json.bz2"];

    [compressedData writeToFile:filePath atomically:YES];

    if (error)
    {
        NSLog(@"Genereate json file error file: %s, line: %d", __FILE__, __LINE__);
    }
   
    gCurlHelper->uploadSongs([[gAppDelegate currentPartyId] UTF8String], [filePath UTF8String]);
    
    [self cancelButtonClicked:self];
    
}


- (IBAction)cancelButtonClicked:(id)sender
{
    [self.window close];
    [NSApp stopModal];
    [gAppDelegate.window orderFrontRegardless];
}


-(void)playSelectedSong:(NSString*)filePath
{
    NSError *error;
    
    NSURL* fileUrl = [NSURL fileURLWithPath:filePath];
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    
    [audioPlayer prepareToPlay];
    
    if ([audioPlayer isPlaying])
    {
        [audioPlayer pause];
    }
    else
    {
        [audioPlayer play];
    }
}

-(void)stopPlaySelectedSong
{
    [audioPlayer stop];
    audioPlayer = nil;
}


- (IBAction)filesForAddToCollectionTableViewRowClicked:(id)sender
{
    NSUInteger selectedRow = [filesForAddToCollectionTableView selectedRow];
    
    if (-1 != selectedRow)
    {
        id songItem = filesForAddToCollectionArray[selectedRow];
        
        if ([NSNull null] != songItem[@"filename"])
            [self playSelectedSong:songItem[@"filename"]];
    }
}



- (IBAction)stopPlaySelectedSong:(id)sender
{
    [self stopPlaySelectedSong];
}


-(BOOL) isSongFileExtension:(NSString*)pathExtension
{
    // Add here other files extensions for allow songs window(middle window) accept relate songs format

    if ([pathExtension isEqualToString:[@"mp3" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"m4a" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"aif" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"wav" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"wma" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"flac" lowercaseString]])
        return YES;
    
    if ([pathExtension isEqualToString:[@"ogg" lowercaseString]])
        return YES;

    return NO;
}

-(void) operationMethodForSearchingFiles:(NSArray*) directoryArray
{
    for (NSURL *directoryURL in directoryArray)
    {
         NSFileManager *fileManager = [[NSFileManager alloc] init];
         NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
         NSDirectoryEnumerator *enumerator = [fileManager
         enumeratorAtURL:directoryURL
         includingPropertiesForKeys:keys
         options:0
         errorHandler:^(NSURL *url, NSError *error){
         // Handle the error.
         // Return YES if the enumeration should continue after the error.
             return YES;
         }];
    
         for (NSURL *url in enumerator)
         {
             NSError *error;
             NSNumber *isDirectory = nil;
             if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error])
             {
                 // handle error
             }
             else if ((![isDirectory boolValue]) &&  [self isSongFileExtension:[url pathExtension]])
             {
                 [self addNewSongToPreCollectionArray:url];
             }
         }
    }
}

@end
