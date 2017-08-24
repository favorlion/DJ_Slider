//
//  MatcherInterface.h
//  Slider
//
//  Created by jwieland on 1/24/16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#ifndef MatcherInterface_h
#define MatcherInterface_h

#import <CoreAudio/CoreAudio.h>
#import <vector>
#include "Matcher.hpp"

// we need a small ObjC object for the NSThread
@interface matcherStartupWrapper : NSObject
-(void)startMatcherInThread;
@end

class MatcherInterface
{
public:
    MatcherInterface() {}
    std::vector< std::pair< CFStringRef, std::string > > getInterfaceList(void);
    void start(NSString* deviceUid);
    void stop(void);
    void pause(void);
    void resume(void);
private:
    matcherStartupWrapper* matcherStarter;
    Matcher* matcher;
};

#endif /* MatcherInterface_h */
