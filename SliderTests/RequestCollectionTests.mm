//
//  RequestCollectionTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/17/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface RequestCollectionTests : XCTestCase
@property (nonatomic, readonly) NSDictionary* reqd;
@end

@implementation RequestCollectionTests

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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItInitializesToEmpty {
    // given
    // when
    RequestCollection* x = [[RequestCollection alloc] init];
    NSArray *arr = [x getOpenRequestsForFile:@"/some/foo.mp3"];
    
    // then
    XCTAssertNotNil(x);
    XCTAssertNotNil(arr);
    XCTAssertEqual(0, [x count]);
    XCTAssertEqual(0, [arr count]);
    XCTAssertNil([x byId:@2]);
    XCTAssertNotNil([x byFile:@"abc"]);
    XCTAssertEqual(0, [[x byFile:@"abc"] count]);
}

- (void) testThatItAddsTheFirstRequest {
    // given
    RequestCollection* x = [[RequestCollection alloc] init];
    Request* req = [[Request alloc] initWithDictionary:_reqd];

    // when
    [x addRequest:req];

    // then
    XCTAssertEqual(1, [x count]);
    
    XCTAssertNil([x byId:@2]);
    XCTAssertNotNil([x byId:_reqd[@"id"]]);
    XCTAssertEqual(req, [x byId:_reqd[@"id"]]);

    NSArray* yarr = [x getOpenRequestsForFile:@"/path/to/file.mp3"];
    NSArray* narr = [x getOpenRequestsForFile:@"/some/foo.mp3"];
    
    XCTAssertEqual(1, [yarr count]);
    XCTAssertEqual(0, [narr count]);

    XCTAssertNotNil([x byFile:@"/some/foo.mp3"]);
    XCTAssertEqual(0, [[x byFile:@"/some/foo.mp3"] count]);
    XCTAssertNotNil([x byFile:@"/path/to/file.mp3"]);
}

- (void) testThatItDoesntAddTheSameRequestTwice {
    // given
    RequestCollection* x = [[RequestCollection alloc] init];
    Request* req = [[Request alloc] initWithDictionary:_reqd];
    [x addRequest:req];

    // when
    [x addRequest:req];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertEqual(req, [x byId:_reqd[@"id"]]);
}

- (void) testThatItAddsASecondRequest {
    // given
    RequestCollection* x = [[RequestCollection alloc] init];
    Request* req1 = [[Request alloc] initWithDictionary:_reqd];
    [x addRequest:req1];
    NSMutableDictionary* req2d = [_reqd mutableCopy];
    req2d[@"id"] = @2;
    Request* req2 = [[Request alloc] initWithDictionary:req2d];
    
    // when
    [x addRequest:req2];

    // then
    XCTAssertEqual(2, [x count]);
    XCTAssertEqual(req1, [x byId:_reqd[@"id"]]);
    XCTAssertEqual(req2, [x byId:req2d[@"id"]]);
}

- (void) testThatItDeletes {
    // given
    RequestCollection* x = [[RequestCollection alloc] init];
    Request* req1 = [[Request alloc] initWithDictionary:_reqd];
    [x addRequest:req1];
    NSMutableDictionary* req2d = [_reqd mutableCopy];
    req2d[@"id"] = @2;
    Request* req2 = [[Request alloc] initWithDictionary:req2d];
    [x addRequest:req2];

    // when
    [x removeRequest:req1];
    
    // then
    XCTAssertEqual(1, [x count]);
    XCTAssertNil([x byId:_reqd[@"id"]]);
    XCTAssertEqual(req2, [x byId:req2d[@"id"]]);
    
    // when
    [x removeRequest:req2];
    
    // then
    XCTAssertEqual(0, [x count]);
    XCTAssertNil([x byId:_reqd[@"id"]]);
    XCTAssertNil([x byId:req2d[@"id"]]);
}

@end
