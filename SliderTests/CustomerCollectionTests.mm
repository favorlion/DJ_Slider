//
//  CustomerCollectionTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/17/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface CustomerCollectionTests : XCTestCase
@property (nonatomic, readonly) NSDictionary* custd;
@end

@implementation CustomerCollectionTests

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
    
    // when
    CustomerCollection* cc = [[CustomerCollection alloc] init];
    
    // then
    XCTAssertEqual([cc count], 0l);
    XCTAssertNil([cc byId:@2]);
}

- (void) testAdd {
    // given
    Customer* c = [[Customer alloc] initWithDictionary:_custd];
    CustomerCollection* cc = [[CustomerCollection alloc] init];

    // when
    [cc addCustomer:c];
    
    // then
    XCTAssertNotNil([cc byId:_custd[@"id"]]);
    XCTAssertEqual([cc count], 1l);
}

- (void) testRepeatedAdd {
    // given
    Customer* c = [[Customer alloc] initWithDictionary:_custd];
    CustomerCollection* cc = [[CustomerCollection alloc] init];
    [cc addCustomer:c];
    c = [cc byId:_custd[@"id"]];

    // when
    [cc addCustomer:c];
    
    // then
    XCTAssertEqual(c, [cc byId:_custd[@"id"]]);
    XCTAssertEqual([cc count], 1l);
}

- (void) testAddSecond {
    // given
    Customer* c = [[Customer alloc] initWithDictionary:_custd];
    CustomerCollection* cc = [[CustomerCollection alloc] init];
    [cc addCustomer:c];
    NSMutableDictionary* cust2d = [_custd mutableCopy];
    cust2d[@"id"] = @2;
    Customer* c2 = [[Customer alloc] initWithDictionary:cust2d];

    // when
    [cc addCustomer:c2];
    
    // then
    XCTAssertEqual(c2, [cc byId:cust2d[@"id"]]);
    XCTAssertNotEqual(c2, [cc byId:_custd[@"id"]]);
    XCTAssertEqual([cc count], 2l);
}


- (void) testReset {
    // given
    Customer* c = [[Customer alloc] initWithDictionary:_custd];
    CustomerCollection* cc = [[CustomerCollection alloc] init];
    [cc addCustomer:c];
    NSMutableDictionary* cust2d = [_custd mutableCopy];
    cust2d[@"id"] = @2;
    Customer* c2 = [[Customer alloc] initWithDictionary:cust2d];
    [cc addCustomer:c2];

    
    // when
    [cc reset];
    
    // then
    XCTAssertEqual([cc count], 0l);
}
@end
