//
//  SongEntity.m
//  Slider
//
//  Created by Dmitry Volkov on 07.02.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import "SongEntity.h"
#import <tag/fileref.h>
#import <tag/tstring.h>
#import <tag/popularimeterframe.h>
#import <tag/mpegfile.h>
#import <tag/id3v2frame.h>
#import <tag/id3v2tag.h>

@implementation SongEntity

@synthesize fileURL;
@synthesize title;
@synthesize artist;
@synthesize album;
@synthesize display;

-(id)initWithSongPath:(NSString*)filePath
{
    self = [super init];
    
    if (self)
    {
        self.title = @"";
        self.artist = @"";
        self.album = @"";

        fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        if ([self fileExists])
        {
            [self parseTags];
        }
        else
        {
            self.display = [fileURL lastPathComponent];
        }
    }
    
    return self;
}

-(void) parseTags
{
    TagLib::FileRef fileRef([[fileURL path] UTF8String]);
    
    if (fileRef.tag()) {
        artist = [NSString stringWithUTF8String:fileRef.tag()->artist().toCString()];
    }
    
    if (fileRef.tag()) {
        title = [NSString stringWithUTF8String:fileRef.tag()->title().toCString()];
    }
    
    if (fileRef.tag()) {
        album = [NSString stringWithUTF8String:fileRef.tag()->album().toCString()];
    }
    
    // what should we display? Usually do "Artist - Title".
    // If either one is not set, fall back to the actual file name.
    if ([artist length] == 0 || [title length] == 0) {
        display = [[fileURL path] lastPathComponent];
    } else {
        display = [NSString stringWithFormat:@"%@ - %@", artist, title];
    }
    
    // if either is nil, set to empty
    if (!artist) artist = @"";
    if (!title) title = @"";
    if (!album) album = @"";

    NSAssert(display, @"display is nil");
    NSAssert([fileURL path], @"path is nil");
}

-(NSDictionary*)getTags
{
    NSDictionary* tags = @{
                  @"artist": artist,
                  @"title": title,
                  @"album": album,
                  @"display": display,
                  @"filename": [fileURL path]};
    
    return tags;
}

-(NSString*)path
{
    return [fileURL path];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return [fileURL writingOptionsForType:type pasteboard:pasteboard];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [fileURL writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    return [fileURL pasteboardPropertyListForType:type];
}

-(int)getBPMFromTag
{
    NSString* filename = [fileURL path];
    int bpm = 0;
    
    if ([[[filename pathExtension] lowercaseString] isEqual: @"mp3"])
    {
        TagLib::MPEG::File f([filename UTF8String]);
        if (f.ID3v2Tag())
        {
            TagLib::ID3v2::FrameList l = f.ID3v2Tag()->frameListMap()["TBPM"];
            if (!l.isEmpty())
            {
                NSString* bpmStr = [NSString stringWithUTF8String:l.front()->toString().toCString()];
                float bpmFloat = [bpmStr floatValue];
                bpm = (int) (bpmFloat + 0.5);
            }
        }
    }
    return bpm;
}

-(BOOL)fileExists
{
    if (access([[fileURL path] UTF8String], R_OK) == 0)
    {
        return YES;
    }
    return NO;
}

@end
