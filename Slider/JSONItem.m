//
//  JSONItem.m
//  Slider
//
//  Created by Dmitry Volkov on 18.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "JSONItem.h"

@implementation JSONItem : NSObject

@synthesize artist;
@synthesize file;
@synthesize title;
@synthesize fileURL;

-(id) init
{
    self = [super init];
    
    if (self)
    {
        artist = [[NSString alloc] init];
        file = [[NSString alloc] init];
        title = [[NSString alloc] init];
    }
    
    return self;
}

-(id) initWithArtist:(NSString*) Artist andFile:(NSString*)File  andTitle:(NSString*) Title andFileUrl:(NSURL*) url
{
    self = [super init];
    
    if (self)
    {
        artist = Artist;
        file = File;
        title = Title;
        fileURL = url;
    }
    
    return self;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return [self.fileURL writingOptionsForType:type pasteboard:pasteboard];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [self.fileURL writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    return [self.fileURL pasteboardPropertyListForType:type];
}


@end
