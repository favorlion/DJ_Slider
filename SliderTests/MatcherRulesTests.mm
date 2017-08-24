//
//  MatcherRulesTests.mm
//  Slider
//
//  Created by Joachim Wieland on 5/27/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "MatcherRules.h"

using namespace std;

@interface MatcherRulesTests : XCTestCase

@end

@implementation MatcherRulesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItInitializes {
    MatcherRules mr;

    XCTAssertEqual(0, mr.getCurrentlyPlaying().size());
    XCTAssertEqual(0, mr.getCompleted().size());
    XCTAssertEqual(0, mr.getCurrentlyOpen().size());
}

- (void)testThatItAdds {
    // given
    MatcherRules mr;

    mr.addDP("file1", 0.01, 0);
    mr.addDP("file1", 0.01, 5);

    mr.testSetTimeNow(7);

    // when
    size_t c = mr.testCountDatapoints();
    
    // then
    XCTAssertEqual(2ul, c);
}

- (void)testThatItSetsToPlaying {
    // given
    MatcherRules mr;
    
    // can't use a time of 0
    mr.addDP("file1", 0.085, 1);
    mr.addDP("file1", 0.085, 6);
    mr.testSetTimeNow(10);

    // when
    auto x = mr.getCurrentlyPlaying();
    
    // then
    XCTAssertEqual(1ul, x.size());
    XCTAssertEqual("file1", x[0]);
}

- (void)testThatItSetsToCompleted {
    // given
    MatcherRules mr;

    // this song is completed, has datapoints spreading 30 seconds
    mr.addDP("file1", 0.085, 6);
    mr.addDP("file1", 0.085, 11);
    mr.addDP("file1", 0.085, 16);
    mr.addDP("file1", 0.085, 21);
    mr.addDP("file1", 0.085, 26);
    mr.addDP("file1", 0.085, 31);
    mr.addDP("file1", 0.085, 36);

    // this song is not completed, has datapoints for 29 seconds only
    mr.addDP("file2", 0.085, 7);
    mr.addDP("file2", 0.085, 11);
    mr.addDP("file2", 0.085, 16);
    mr.addDP("file2", 0.085, 21);
    mr.addDP("file2", 0.085, 26);
    mr.addDP("file2", 0.085, 31);
    mr.addDP("file2", 0.085, 36);
    
    // when
    mr.testSetTimeNow(38);
    auto x = mr.getCompleted();
    
    // then
    XCTAssertEqual(1ul, x.size());
    XCTAssertEqual(6ul, x[0].first);
    XCTAssertEqual("file1", x[0].second);
}

// consider a sequence of songs A and B:

//           1    1    2    2    3    3    4
// 0....5....0....5....0....5....0....5....0
//  A    A    A  A    A  A AA    A            <-- consistently played but not completed
//   B    B      B         B   B   B          <-- not consistently played (expires in between)
//  C  CC   CCCC    C    C    C    C          <-- consistently played and completed

// times for A: 1, 6, 11, 14, 19, 22, 24, 25, 30
// times for B: 2, 7, 14, 24, 28, 30
// times for C: 2, 4, 5, 9, 10, 11, 12, 17, 22, 27, 32

- (void)testThatItSetsStatuses {
    // given
    MatcherRules mr;
    
    // can't use a time of 0
    int songATimes[] = { 1, 6, 11, 14, 19, 22, 24, 25, 30, 0 };
    int songBTimes[] = { 2, 7, 14, 24, 28, 30, 0 };
    int songCTimes[] = { 2, 4, 5, 9, 10, 11, 12, 17, 22, 27, 32, 0 };

    int aidx, bidx, cidx;
    aidx = bidx = cidx = 0;

    while (songATimes[aidx] || songBTimes[bidx] || songCTimes[cidx]) {
        if (songATimes[aidx] && songATimes[aidx] <= songBTimes[bidx] && songATimes[aidx] <= songCTimes[cidx]) {
            mr.addDP("fileA", 0.085, songATimes[aidx]);
            aidx++;
            continue;
        }
        if (songBTimes[bidx] && songBTimes[bidx] <= songCTimes[cidx]) {
            mr.addDP("fileB", 0.085, songBTimes[bidx]);
            bidx++;
            continue;
        }
        if (songCTimes[cidx]) {
            mr.addDP("fileC", 0.085, songCTimes[cidx]);
            cidx++;
            continue;
        }
    }

    // uncompacted
    XCTAssertEqual(26ul, mr.testCountDatapoints());
    
    // when
    // this will compact as a side effect
    mr.testSetTimeNow(32);
    auto x = mr.getCurrentlyPlaying();
    
    // then
    XCTAssertEqual(23ul, mr.testCountDatapoints());
    XCTAssertEqual(3ul, x.size());
    XCTAssertEqual("fileA", x[0]);
    XCTAssertEqual("fileB", x[1]);
    XCTAssertEqual("fileC", x[2]);
    
    // when
    auto y = mr.getCompleted();
    XCTAssertEqual(23ul, mr.testCountDatapoints());
    XCTAssertEqual(1ul, y.size());
    XCTAssertEqual(2ul, y[0].first);
    XCTAssertEqual("fileC", y[0].second);
}

- (void)testThatItIgnoresExpiredSongs {
    // given
    MatcherRules mr;
    
    // can't use a time of 0
    mr.addDP("file1", 0.085, 1);
    mr.addDP("file1", 0.085, 6);
    mr.testSetTimeNow(999);

    // when
    auto x = mr.getCurrentlyPlaying();
    
    // then
    XCTAssertEqual(0ul, x.size());
}

- (void)testThatItRecordsOpenFiles {
    // given
    MatcherRules mr;
    
    // when
    mr.fileOpened("fileA");
    auto x = mr.getCurrentlyOpen();

    // then
    XCTAssertEqual(1, x.size());
    XCTAssertEqual("fileA", x[0]);
}

- (void)testThatItRecordsClosedFiles {
    // given
    MatcherRules mr;
    mr.fileOpened("fileA");
    
    // when
    mr.fileClosed("fileA");
    auto x = mr.getCurrentlyOpen();
    
    // then
    XCTAssertEqual(0, x.size());
}

@end
