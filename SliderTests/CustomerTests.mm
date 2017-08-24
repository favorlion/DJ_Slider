//
//  CustomerTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/17/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface CustomerTests : XCTestCase
@property (nonatomic, readonly) NSDictionary* custd;
@end

@implementation CustomerTests

- (void)setUp {
    [super setUp];
    _custd = @{
              @"id" : @38,
              @"name" : @"John Doe"
              };
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testInit {
    // given
    NSDictionary* custd = self.custd;
    
    // when
    Customer *cust = [[Customer alloc] initWithDictionary:custd];
    
    // then
    XCTAssertEqualObjects([cust custId], custd[@"id"]);
    XCTAssertEqualObjects([cust name], custd[@"name"]);
}

@end
