//
//  CommunicationCenterTests.mm
//  Slider
//
//  Created by Joachim Wieland on 6/5/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessageCenter.h"

@interface CommunicationCenterTests : XCTestCase

@end

@implementation CommunicationCenterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testThatItInitializes {
    // given
    // when
    CommunicationCenter* commCtr = [[CommunicationCenter alloc] init];
    MessageCollection *mc = [commCtr messageCollection];
    RequestCollection *rc = [commCtr requestCollection];

    // then
    XCTAssertTrue([mc isKindOfClass:[MessageCollection class]]);
    XCTAssertTrue([rc isKindOfClass:[RequestCollection class]]);
    XCTAssertEqual(0ul, [mc count]);
    XCTAssertEqual(0ul, [rc count]);
}

@end
