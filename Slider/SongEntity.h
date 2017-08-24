//
//  SongEntity.h
//  Slider
//
//  Created by Dmitry Volkov on 07.02.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface SongEntity : NSObject <NSPasteboardWriting>

@property (strong, nonatomic) NSURL *fileURL;
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* artist;
@property (strong, nonatomic) NSString* album;
@property (strong, nonatomic) NSString* display;

-(id)initWithSongPath:(NSString*)filePath;
-(NSDictionary*)getTags;
-(NSString*)path;
-(int)getBPMFromTag;
-(BOOL)fileExists;

@end
