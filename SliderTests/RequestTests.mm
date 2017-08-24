//
//  RequestTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/14/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface RequestTests : XCTestCase
@property (nonatomic, readonly) NSDictionary* reqd;
@property (nonatomic, readonly) NSDictionary* msgfd;
@property (nonatomic, readonly) MessageCollection* msgColl;
@end

@implementation RequestTests

- (void)setUp {
    [super setUp];
    _reqd = @{
              @"artist" : @"The Artist",
              @"completed" : @0,
              @"customer" : @{
                      @"id" : @38,
                      @"name" : @"John Doe"
                      },
              @"filename" : @"/path/to/file.mp3",
              @"id" : @240,
              @"msg" : @"initial Message",
              @"party_seq" : @39,
              @"played_file" : [NSNull null],
              @"time_played_begin" : @0,
              @"time_played_end" : @0,
              @"tip_amount" : @3.14,
              @"tip_currency" : @"USD",
              @"title" : @"The Title",
              @"tm" : @"2016-01-14T01:01:30.702Z",
              @"deleted" : @0,
              };
    _msgfd = @{
               @"from_customer" : @{
                       @"id" : @38,
                       @"name":  @"John Doe"
                       },
               @"id" : @2597,
               @"msg" : @"hj",
               @"party_seq" : @1371,
               @"request_id" : @240,
               @"tm" : @"2016-04-17T01:21:04.113Z",
               @"to_customer" :[NSNull null],
               };
    _msgColl = [[MessageCollection alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testInit {
    // given
    NSDictionary* reqd = _reqd;
    
    // when
    Request *req = [[Request alloc] initWithDictionary:reqd andMessageCollection:_msgColl];

    // then
    XCTAssertEqualObjects([req reqId], reqd[@"id"]);
    XCTAssertEqualObjects([req tip_currency], reqd[@"tip_currency"]);
    float dictTip = [reqd[@"tip_amount"] floatValue];
    float reqTip = [req tip_amount];
    XCTAssertEqualWithAccuracy(dictTip, reqTip, 0.01, @"");
    
    XCTAssertEqualObjects([NSNumber numberWithLong:[req party_seq]], reqd[@"party_seq"]);
    XCTAssertEqualObjects([req requested_file], reqd[@"filename"]);
    XCTAssertEqualObjects([req played_file], reqd[@"played_file"]);
    XCTAssertEqual([[req time_played_begin] timeIntervalSince1970], [reqd[@"time_played_begin"] intValue]);
    XCTAssertEqual([[req time_played_end] timeIntervalSince1970], [reqd[@"time_played_end"] intValue]);
    XCTAssertTrue([req time_played_end] == 0);
    XCTAssertTrue([req time_played_begin] == 0);
    
    XCTAssertEqualObjects([[req customer] custId], reqd[@"customer"][@"id"]);
    XCTAssertEqualObjects([req custId], reqd[@"customer"][@"id"]);
    XCTAssertEqualObjects([[req customer] name], reqd[@"customer"][@"name"]);
    XCTAssertEqualObjects([req custName], reqd[@"customer"][@"name"]);


    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSz"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *tmstr = [dateFormatter stringFromDate:[req time_requested]];
    tmstr = [tmstr stringByReplacingOccurrencesOfString:@"GMT" withString:@"Z"];
    XCTAssertEqualObjects(tmstr, reqd[@"tm"]);

    XCTAssertNil([req bpm]);
    XCTAssertTrue([req visible]);
    XCTAssertFalse([req complete]);
    
    XCTAssertTrue([[req initialMessage] isKindOfClass:[Message class]]);
    Message* msg = [req initialMessage];
    XCTAssertEqualObjects([msg text], reqd[@"msg"]);
    XCTAssertEqualObjects([msg time_sent], [req time_requested]);
    XCTAssertEqualObjects([msg msgId], @0);
    XCTAssertEqualObjects([msg custId], [req custId]);
    XCTAssertTrue([msg isFromCustomer]);
    XCTAssertEqualObjects([msg reqId], [req reqId]);
    
    XCTAssertEqual(1, [[req messages] count]);
    XCTAssertEqualObjects([[req messages] firstObject], [req initialMessage]);
}

- (void) testInitPlaying {
    // given
    NSMutableDictionary* reqd = [_reqd mutableCopy];
    NSString* filePlaying = @"/some/file.mp3";
    reqd[@"played_file"] = filePlaying;
    reqd[@"time_played_begin"] = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
    reqd[@"bpm"] = @"123";

    // when
    Request *req = [[Request alloc] initWithDictionary:reqd andMessageCollection:_msgColl];

    // then
    XCTAssertEqualObjects([req played_file], filePlaying);
    XCTAssertEqualObjects([req bpm], @"123");
    XCTAssertTrue([req visible]);
    XCTAssertFalse([req complete]);
}

- (void) testThatItRecognizesPlayed {
    // given
    NSMutableDictionary* reqd = [_reqd mutableCopy];
    NSString* filePlaying = @"/some/file.mp3";
    reqd[@"played_file"] = filePlaying;
    reqd[@"time_played_begin"] = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
    reqd[@"time_played_end"] = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970] + 30];

    // when
    Request *req_visible = [[Request alloc] initWithDictionary:reqd andMessageCollection:_msgColl];
    reqd[@"time_played_begin"] = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970] - 121];
    Request *req_invisible = [[Request alloc] initWithDictionary:reqd andMessageCollection:_msgColl];

    // then
    XCTAssertTrue([req_visible visible]);
    XCTAssertTrue([req_visible complete]);
    XCTAssertFalse([req_invisible visible]);
    XCTAssertTrue([req_invisible complete]);
}

- (void) testThatItIgnoresDeleted {
    // given
    NSMutableDictionary* reqd = [_reqd mutableCopy];
    reqd[@"deleted"] = @1;

    // when
    Request *req = [[Request alloc] initWithDictionary:reqd andMessageCollection:_msgColl];
    
    // then
    XCTAssertFalse([req visible]);
    XCTAssertFalse([req complete]);
    XCTAssertTrue([req deleted]);
}

- (void) testThatItDeletes {
    // given
    Request *req = [[Request alloc] initWithDictionary:_reqd andMessageCollection:_msgColl];
    XCTAssertFalse([req deleted]);
    
    // when
    [req setDeleted:YES];
    
    // then
    XCTAssertTrue([req deleted]);
}

-(void) testThatItCompletes {
    // given
    Request* req = [[Request alloc] initWithDictionary:_reqd andMessageCollection:_msgColl];
    NSString* file = @"/some/file.mp3";
    SongEntity* song = [[SongEntity alloc] initWithSongPath:file];

    // when
    NSDate* x = [NSDate dateWithTimeIntervalSinceNow:-30.0];
    [req completeWithSong:song inParty:@"123" withStarted:x];
    NSDate* y = [NSDate date];

    // then
    XCTAssertEqualObjects([req played_file], file);
    XCTAssertEqualObjects([req time_played_begin], x);
    XCTAssertEqualWithAccuracy([[req time_played_end] timeIntervalSince1970], [y timeIntervalSince1970], 0.01, @"");
}

-(void) testThatItRetrievesRelatedMessages {
    // given
    Request* req = [[Request alloc] initWithDictionary:_reqd andMessageCollection:_msgColl];
    Message* msg = [[Message alloc] initWithDictionary:_msgfd];
    [_msgColl addMessage:msg];
    
    // when
    NSArray* x = [req messages];

    // then
    XCTAssertEqual(2, [x count]);
    XCTAssertEqualObjects(x[0], [req initialMessage]);
    XCTAssertEqualObjects(x[1], msg);
}

-(void) testThatItDeletesRelatedMessages {
    // given
    Request* req = [[Request alloc] initWithDictionary:_reqd andMessageCollection:_msgColl];
    Message* msg = [[Message alloc] initWithDictionary:_msgfd];
    [_msgColl addMessage:msg];
    
    // when
    [req delete];

    // then
    NSArray* x = [_msgColl byRequest:req];
    XCTAssertEqual(0, [x count]);
}

-(void) testThatItSetsInitialMessage {
    // given
    NSMutableDictionary* reqd_empty = [_reqd mutableCopy];
    reqd_empty[@"msg"] = @"";
    
    // when
    Request *req = [[Request alloc] initWithDictionary:_reqd andMessageCollection:_msgColl];
    Request *req_empty = [[Request alloc] initWithDictionary:reqd_empty andMessageCollection:_msgColl];

    // then
    XCTAssertNil([req_empty initialMessage]);
    XCTAssertNotNil([req initialMessage]);
}

@end
