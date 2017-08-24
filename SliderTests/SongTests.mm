//
//  SongTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/14/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SongEntity.h"

#import <tag/fileref.h>
#import <tag/tstring.h>
#import <tag/popularimeterframe.h>
#import <tag/mpegfile.h>
#import <tag/id3v2frame.h>
#import <tag/textidentificationframe.h>
#import <tag/id3v2tag.h>

@interface SongTests : XCTestCase

@end

@implementation SongTests

-(NSString*)getExampleFile
{
    NSString* path = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString* origPath = [NSString stringWithFormat:@"%@/%s", path, "bensound-dubstep.mp3"];
    NSString* copyPath = [self tempFileForBasename:@"test.mp3"];
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:copyPath error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:origPath toPath:copyPath error:&error];
    return copyPath;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

-(void) tagFile:(NSString*)file withBPM:(int)bpm
{
    TagLib::MPEG::File f([file UTF8String]);
    TagLib::ID3v2::Tag* id3v2 = f.ID3v2Tag();

    NSString* bpmStr = [NSString stringWithFormat:@"%d", bpm];
    if (id3v2) {
        // if it crashes here, verify you're linking against the library, not the tag framework
        TagLib::ID3v2::FrameList bpmFrame = id3v2->frameListMap()["TBPM"];
        if (!bpmFrame.isEmpty()) {
            bpmFrame.front()->setText([bpmStr UTF8String]);
        } else {
            TagLib::ID3v2::TextIdentificationFrame* newFrame;
            newFrame = new TagLib::ID3v2::TextIdentificationFrame("TBPM", TagLib::String::Latin1);
            newFrame->setText([bpmStr UTF8String]);
            id3v2->addFrame(newFrame);
        }
    }
    f.save();
}

-(void) tagFile:(NSString*)file withAlbum:(NSString*)album
{
    TagLib::FileRef f([file UTF8String]);
    f.tag()->setAlbum([album UTF8String]);
    f.save();
}

-(void) tagFile:(NSString*)file withArtist:(NSString*)artist
{
    TagLib::FileRef f([file UTF8String]);
    f.tag()->setArtist([artist UTF8String]);
    f.save();
}

-(void) tagFile:(NSString*)file withTitle:(NSString*)title
{
    TagLib::FileRef f([file UTF8String]);
    f.tag()->setTitle([title UTF8String]);
    f.save();
}

-(NSString*) tempFileForBasename:(NSString*)basename
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:basename];
}

- (void)testExampleExists {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

-(void) testNonExistantInit {
    // given
    SongEntity* song;
    NSString* file = @"/path/to/song.mp3";
    NSString* display = @"song.mp3";

    // when
    song = [[SongEntity alloc] initWithSongPath:file];

    // then
    XCTAssertFalse([song fileExists]);
    XCTAssertEqualObjects(file, [song path]);
    XCTAssertEqualObjects(@"", [song artist]);
    XCTAssertEqualObjects(@"", [song album]);
    XCTAssertEqualObjects(@"", [song title]);
    XCTAssertEqualObjects(display, [song display]);
    XCTAssertEqual(0, [song getBPMFromTag]);
}

-(void) testInitExistingEmpty {
    // given
    SongEntity* song;
    NSString* file = [self getExampleFile];
    NSLog(@"using file %@", file);

    // when
    song = [[SongEntity alloc] initWithSongPath:file];

    // then
    XCTAssertTrue([song fileExists]);
    XCTAssertEqualObjects(file, [song path]);
    XCTAssertEqualObjects(@"", [song artist]);
    XCTAssertEqualObjects(@"", [song album]);
    XCTAssertEqualObjects(@"", [song title]);
    XCTAssertEqual(0, [song getBPMFromTag]);
}

-(void) testInitExistingTitleAlbumArtistBPM {
    // given
    SongEntity* song;
    NSString* file = [self getExampleFile];
    NSLog(@"using file %@", file);
    
    [self tagFile:file withAlbum:@"The album"];
    [self tagFile:file withArtist:@"The artist"];
    [self tagFile:file withTitle:@"The title"];
    [self tagFile:file withBPM:123];
    
    // when
    song = [[SongEntity alloc] initWithSongPath:file];
    
    // then
    XCTAssertTrue([song fileExists]);
    XCTAssertEqualObjects(file, [song path]);
    XCTAssertEqualObjects(@"The artist", [song artist]);
    XCTAssertEqualObjects(@"The album", [song album]);
    XCTAssertEqualObjects(@"The title", [song title]);
    XCTAssertEqual(123, [song getBPMFromTag]);
}




@end
