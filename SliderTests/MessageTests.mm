//
//  MessageTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/14/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface MessageTests : XCTestCase
// to-customer, from-customer and broadcast
@property (nonatomic) NSDictionary *msgtd, *msgfd, *msgbd;
@end

@implementation MessageTests

- (void)setUp {
    [super setUp];
    _msgtd = @{
               @"from_customer" : [NSNull null],
               @"id" :@2616,
               @"msg" : @"=",
               @"party_seq" : @1531,
               @"request_id" : [NSNull null],
               @"tm" : @"2016-04-30T18:25:07.589Z",
               @"to_customer" : @{
                       @"id" : @2,
                       @"name" : @"Joachim Wieland"
                       }
               };
    _msgfd = @{
               @"from_customer" : @{
                       @"id" : @2,
                       @"name":  @"Joachim Wieland"
                       },
               @"id" : @2597,
               @"msg" : @"hi",
               @"party_seq" : @1371,
               @"request_id" : @364,
               @"tm" : @"2016-04-17T01:21:04.113Z",
               @"to_customer" :[NSNull null],
               };
    _msgbd = @{
               @"from_customer" : [NSNull null],
               @"to_customer" :[NSNull null],
               @"id" : @2596,
               @"msg" : @"broadcast",
               @"party_seq" : @1372,
               @"tm" : @"2016-04-17T01:21:04.113Z",
               };
}

- (void)tearDown {
    [super tearDown];
}

- (void) testThatItInitializesMsgFromCust {
    // given
    NSDictionary* msgd = _msgfd;

    // when
    Message *msg = [[Message alloc] initWithDictionary:msgd];

    // then
    XCTAssertEqualObjects([msg msgId], msgd[@"id"]);
    XCTAssertEqualObjects([msg reqId], msgd[@"request_id"]);
    XCTAssertFalse([msg isBroadcast]);
    XCTAssertFalse([msg isToCustomer]);
    XCTAssertTrue([msg isFromCustomer]);
    XCTAssertTrue([msg isRequestRelated]);
    XCTAssertEqualObjects([NSNumber numberWithLong:[msg party_seq]], msgd[@"party_seq"]);
    XCTAssertEqualObjects([[msg customer] name],
                          msgd[@"from_customer"][@"name"]);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSz"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *tmstr = [dateFormatter stringFromDate:[msg time_sent]];
    tmstr = [tmstr stringByReplacingOccurrencesOfString:@"GMT" withString:@"Z"];
    XCTAssertEqualObjects(tmstr, msgd[@"tm"]);
    XCTAssertTrue([msg visible]);
    XCTAssertFalse([msg seen]);
    XCTAssertEqualObjects([[msg customer] name], [msg custName]);
    XCTAssertEqualObjects([[msg customer] custId], [msg custId]);
}

- (void) testThatItInitializesMsgToCust {
    // given
    NSDictionary* msgd = _msgtd;
    
    // when
    Message *msg = [[Message alloc] initWithDictionary:msgd];

    // then
    XCTAssertEqualObjects([msg msgId], msgd[@"id"]);
    XCTAssertNil([msg reqId]);
    XCTAssertFalse([msg isBroadcast]);
    XCTAssertTrue([msg isToCustomer]);
    XCTAssertFalse([msg isFromCustomer]);
    XCTAssertFalse([msg isRequestRelated]);
    XCTAssertEqualObjects([[msg customer] name],
                          msgd[@"to_customer"][@"name"]);
    XCTAssertEqualObjects([[msg customer] name], [msg custName]);
    XCTAssertEqualObjects([[msg customer] custId], [msg custId]);
}

- (void) testThatItInitializesBroadcast {
    // given
    NSDictionary* msgd = _msgbd;
    
    // when
    Message *msg = [[Message alloc] initWithDictionary:msgd];
    
    // then
    XCTAssertEqualObjects([msg msgId], msgd[@"id"]);
    XCTAssertTrue([msg isBroadcast]);
    XCTAssertFalse([msg isToCustomer]);
    XCTAssertFalse([msg isFromCustomer]);
    XCTAssertFalse([msg isRequestRelated]);
}

-(void)testThatSeenIsRecorded {
    // given
    NSDictionary* msgd = _msgfd;
    Message *msg = [[Message alloc] initWithDictionary:msgd];
    
    // when
    [msg setSeen:YES];

    // then
    XCTAssertTrue([msg seen]);
}

-(void) testThatItFormatsTheTime {
    // given
    NSDictionary* msgd = _msgfd;
    Message *msg = [[Message alloc] initWithDictionary:msgd];
    // XXX how to override readonly for test driver?
    //msg.time_sent = [NSDate date];

    // when
    NSString* s = [msg relativeTimeString];

    // then
    XCTAssertTrue([s containsString:@" minutes ago"]);
    // XXX
}

-(void) testThatItReturnsTheTextFormatted {
    // given
    NSDictionary* msgd = _msgfd;
    Message *msg = [[Message alloc] initWithDictionary:msgd];
    
    // when
    NSAttributedString* as = [msg formattedText];
    NSString* s = [as string];
    
    // then
    XCTAssertTrue([as isKindOfClass:[NSAttributedString class]]);
    XCTAssertTrue([s containsString:@"Joachim Wieland - "]);
    XCTAssertTrue([s containsString:@"minutes ago\nhi\n\n"]);
}

@end
