//
//  MessageCollectionTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/14/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface MessageCollectionTests : XCTestCase
// to-customer, from-customer and broadcast
@property (nonatomic) NSDictionary *msgtd, *msgfd, *msgbd;
@property (nonatomic) NSDictionary *custd, *reqd;
@end

@implementation MessageCollectionTests

- (void)setUp {
    [super setUp];
    _custd = @{
               @"id" : @38,
               @"name" : @"John Doe"
               };
    _msgtd = @{
               @"from_customer" : [NSNull null],
               @"id" :@2616,
               @"msg" : @"=",
               @"party_seq" : @1531,
               @"request_id" : [NSNull null],
               @"tm" : @"2016-04-30T18:25:07.589Z",
               @"to_customer" : @{
                       @"id" : @38,
                       @"name" : @"John Doe"
                       }
               };
    _msgfd = @{
               @"from_customer" : @{
                       @"id" : @38,
                       @"name":  @"John Doe"
                       },
               @"id" : @2597,
               @"msg" : @"hj",
               @"party_seq" : @1371,
               @"request_id" : [NSNull null],
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
    _reqd = @{
              @"artist" : @"The Artist",
              @"completed" : @0,
              @"customer" : @{
                      @"id" : @38,
                      @"name" : @"John Doe"
                      },
              @"filename" : @"/path/to/file.mp3",
              @"id" : @364,
              @"msg" : @"",
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
}

- (void)tearDown {
    [super tearDown];
}

-(void) testThatItInitializesEmpty
{
    // given
    Customer* c = [[Customer alloc] initWithDictionary:_custd];
    Request* req = [[Request alloc] initWithDictionary:_reqd];
    // when
    MessageCollection* x = [[MessageCollection alloc] init];
    // then
    XCTAssertEqual(0, [x count]);
    XCTAssertEqual([x highestSeqNo], 0);
    XCTAssertNil([x byId:@2]);
    XCTAssertNotNil([x byCustomer:c]);
    XCTAssertNotNil([x byRequest:req]);
    XCTAssertEqual(0, [[x byCustomer:c] count]);
    XCTAssertEqual(0, [[x byRequest:req] count]);
    XCTAssertNil([x newestFromCustomer:c]);
    XCTAssertEqual(0, [x countCustomers]);
    XCTAssertEqual(0, [[x orderedCustomers] count]);
}

-(void) testThatItAddsTheFirstMessage
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    Message* msg = [[Message alloc] initWithDictionary:_msgfd];
    Customer* c = [msg customer];

    // when
    [x addMessage:msg];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertEqualObjects(msg, [x byId:_msgfd[@"id"]]);
    
    XCTAssertEqual(1, [[x byCustomer:c] count]);
    XCTAssertEqualObjects(msg, [[x byCustomer:c] firstObject]);
    XCTAssertEqualObjects(msg, [x newestFromCustomer:c]);
    
    XCTAssertEqual([x highestSeqNo], [_msgfd[@"party_seq"] longValue]);
    XCTAssertEqual(1, [x countCustomers]);
    XCTAssertEqual(1, [[x orderedCustomers] count]);
    XCTAssertEqualObjects(c, [[x orderedCustomers] firstObject]);
    XCTAssertFalse([x haveSeenAllFromCustomer:c]);
}

-(void) testThatItAddsTheFirstRequestRelatedMessage
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    NSMutableDictionary* msgfd = [_msgfd mutableCopy];
    msgfd[@"request_id"] = @364;
    Message* msg = [[Message alloc] initWithDictionary:msgfd];
    Customer* c = [msg customer];
    Request* req = [[Request alloc] initWithDictionary:_reqd];
    
    // when
    [x addMessage:msg];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertEqualObjects(msg, [x byId:_msgfd[@"id"]]);

    // don't add request-related messages to the per-Customer view
    XCTAssertEqual(0, [[x byCustomer:c] count]);

    XCTAssertEqual(1, [[x byRequest:req] count]);
    XCTAssertEqualObjects(msg, [[x byRequest:req] firstObject]);
    
    XCTAssertEqual([x highestSeqNo], [_msgfd[@"party_seq"] longValue]);
    XCTAssertEqual(0, [x countCustomers]);

    XCTAssertFalse([x haveSeenAllMessagesForRequest:req]);
}

-(void) testThatItDoesntAddTheSameMessageTwice
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    Message* msg = [[Message alloc] initWithDictionary:_msgfd];
    Customer* c = [msg customer];
    [x addMessage:msg];

    // when
    [x addMessage:msg];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertEqualObjects(msg, [x byId:_msgfd[@"id"]]);
    XCTAssertEqual(1, [[x byCustomer:c] count]);
    XCTAssertEqual([x highestSeqNo], [_msgfd[@"party_seq"] longValue]);
    XCTAssertEqual(1, [x countCustomers]);
    XCTAssertEqual(1, [[x orderedCustomers] count]);
}

-(void) testThatItDoesntAddTheSameRequestRelatedMessageTwice
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    NSMutableDictionary* msgfd = [_msgfd mutableCopy];
    msgfd[@"request_id"] = @364;
    Message* msg = [[Message alloc] initWithDictionary:msgfd];
    Customer* c = [msg customer];
    Request* req = [[Request alloc] initWithDictionary:_reqd];
    [x addMessage:msg];
    
    // when
    [x addMessage:msg];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertEqualObjects(msg, [x byId:_msgfd[@"id"]]);
    XCTAssertEqual(0, [[x byCustomer:c] count]);
    XCTAssertEqual(1, [[x byRequest:req] count]);
    XCTAssertEqual([x highestSeqNo], [_msgfd[@"party_seq"] longValue]);
    XCTAssertEqual(0, [x countCustomers]);
}

-(void) testThatItAddsASecondMessage
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];

    Message *msgf = [[Message alloc] initWithDictionary:_msgfd];
    [x addMessage:msgf];

    Message *msgt = [[Message alloc] initWithDictionary:_msgtd];
    Customer* c = [msgf customer];
    Request* req = [[Request alloc] initWithDictionary:_reqd];

    // when
    [x addMessage:msgt];
    
    // then
    XCTAssertEqual(2, [x count]);
    XCTAssertEqualObjects(msgf, [x byId:_msgfd[@"id"]]);
    XCTAssertEqualObjects(msgt, [x byId:_msgtd[@"id"]]);
    XCTAssertEqual(2, [[x byCustomer:c] count]);
    // assume ordered by insertion time
    XCTAssertEqualObjects(msgf, [x byCustomer:c][0]);
    XCTAssertEqualObjects(msgt, [x byCustomer:c][1]);
    XCTAssertEqual(1, [x countCustomers]);
    
    // msgt has the more recent timestamp but we filter for FROM messages
    XCTAssertEqualObjects(msgf, [x newestFromCustomer:c]);
    XCTAssertEqual(1, [[x orderedCustomers] count]);

    // not request related
    XCTAssertEqual(0, [[x byRequest:req] count]);
    
    long highestSeq = MAX([_msgfd[@"party_seq"] longValue], [_msgtd[@"party_seq"] longValue]);
    XCTAssertEqual([x highestSeqNo], highestSeq);
}

-(void) testThatItAddsASecondRequestRelatedMessage
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];

    NSMutableDictionary* msgfd = [_msgfd mutableCopy];
    msgfd[@"request_id"] = @364;
    msgfd[@"party_seq"] = @3444;

    Message *msgf = [[Message alloc] initWithDictionary:msgfd];
    [x addMessage:msgf];

    NSMutableDictionary* msgtd = [_msgtd mutableCopy];
    msgtd[@"request_id"] = @364;
    msgtd[@"party_seq"] = @3445;

    Message *msgt = [[Message alloc] initWithDictionary:msgtd];
    Customer* c = [msgf customer];
    Request* req = [[Request alloc] initWithDictionary:_reqd];
    
    // when
    [x addMessage:msgt];
    
    // then
    XCTAssertEqual(2, [x count]);
    XCTAssertEqual(0, [[x byCustomer:c] count]);
    
    // msgt is linked to a request
    XCTAssertEqual(2, [[x byRequest:req] count]);
    XCTAssertEqualObjects(msgf, [x byRequest:req][0]);
    XCTAssertEqualObjects(msgt, [x byRequest:req][1]);

    
    long highestSeq = MAX([msgfd[@"party_seq"] longValue], [msgtd[@"party_seq"] longValue]);
    XCTAssertEqual([x highestSeqNo], highestSeq);
}

-(void) testThatItResets
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    
    Message *msgf = [[Message alloc] initWithDictionary:_msgfd];
    [x addMessage:msgf];
    
    Message *msgt = [[Message alloc] initWithDictionary:_msgtd];
    [x addMessage:msgt];

    Customer* c = [msgf customer];

    Request* req = [[Request alloc] initWithDictionary:_reqd];

    // when
    [x reset];
    
    // then
    XCTAssertEqual(0, [x count]);
    XCTAssertNil([x byId:_msgfd[@"id"]]);
    XCTAssertNil([x byId:_msgtd[@"id"]]);
    XCTAssertEqual(0, [[x byCustomer:c] count]);
    XCTAssertEqual(0, [x countCustomers]);
    XCTAssertNil([x newestFromCustomer:c]);
    XCTAssertEqual(0, [[x orderedCustomers] count]);
    XCTAssertEqual(0, [[x byRequest:req] count]);
    XCTAssertEqual([x highestSeqNo], 0);
}

-(void) testThatItRecordsSeenStatus
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    
    Message *msgf = [[Message alloc] initWithDictionary:_msgfd];
    [x addMessage:msgf];
    
    Message *msgt = [[Message alloc] initWithDictionary:_msgtd];
    [x addMessage:msgt];
    
    Customer* c = [msgf customer];

    Request* req = [[Request alloc] initWithDictionary:_reqd];

    // when
    [msgf setSeen:YES];
    
    // then
    XCTAssertTrue([x haveSeenAllFromCustomer:c]);
    XCTAssertTrue([x haveSeenAllMessagesForRequest:req]);
}

-(void) testThatItRecordsSeenStatusForAllFromCustomer
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    
    // request-related
    NSMutableDictionary* msgfd = [_msgfd mutableCopy];
    msgfd[@"request_id"] = @364;
    msgfd[@"id"] = @10;
    msgfd[@"party_seq"] = @10;
    Message *msgfr = [[Message alloc] initWithDictionary:msgfd];
    [x addMessage:msgfr];

    // same message as in the beginning but without a request-id
    Message *msgf = [[Message alloc] initWithDictionary:_msgfd];
    [x addMessage:msgf];

    Message *msgt = [[Message alloc] initWithDictionary:_msgtd];
    [x addMessage:msgt];

    Customer* c = [msgfr customer];

    // when
    [x setSeenAllFromCustomer:c];

    // then
    XCTAssertTrue([x haveSeenAllFromCustomer:c]);
    XCTAssertFalse([msgfr seen]);
    XCTAssertTrue([msgf seen]);
}

-(void) testThatItRecordsSeenStatusForAllForRequest
{
    // given
    MessageCollection* x = [[MessageCollection alloc] init];
    
    // request-related
    NSMutableDictionary* msgfd = [_msgfd mutableCopy];
    msgfd[@"request_id"] = @364;
    msgfd[@"id"] = @123;
    msgfd[@"party_seq"] = @12;
    Message *msgfr = [[Message alloc] initWithDictionary:msgfd];
    [x addMessage:msgfr];
    
    Message *msgf = [[Message alloc] initWithDictionary:_msgfd];
    [x addMessage:msgf];
    
    Message *msgt = [[Message alloc] initWithDictionary:_msgtd];
    [x addMessage:msgt];
    
    Request* req = [[Request alloc] initWithDictionary:_reqd];

    // when
    [x setSeenAllMessagesForRequest:req];

    // then
    XCTAssertTrue([x haveSeenAllMessagesForRequest:req]);

    XCTAssertTrue([msgfr isRequestRelated]);
    XCTAssertTrue([msgfr seen]);

    XCTAssertFalse([msgf isRequestRelated]);
    XCTAssertFalse([msgf seen]);
}

// misses a testcase with different customers

@end
