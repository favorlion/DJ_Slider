//
//  JSONItem.h
//  Slider
//
//  Created by Dmitry Volkov on 18.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface JSONItem : NSObject <NSPasteboardWriting>

@property (strong, readonly) NSString* artist;
@property (strong, readonly) NSString* file;
@property (strong, readonly) NSString* title;

@property (strong, nonatomic) NSURL *fileURL;

-(id) initWithArtist:(NSString*) Artist andFile:(NSString*)File  andTitle:(NSString*) Title andFileUrl:(NSURL*) url;

@end
