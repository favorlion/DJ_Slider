/*
 *  Matcher.hpp
 *  Matcher
 *
 *  Created by jwieland on 1/24/16.
 *  Copyright © 2016 Automatic System Metering. All rights reserved.
 *
 */

#ifndef Matcher_
#define Matcher_

#include <functional>
#include <vector>
#include <CoreFoundation/CoreFoundation.h>

/* The classes below are exported */
#pragma GCC visibility push(default)

class Matcher
{
public:
    using cbT = std::function<void(const std::string& file)>;
    Matcher(const char* deviceUid);
    void start(void);
    void stop(void);
    void pause(void);
    void resume(void);
    std::vector< std::pair< CFStringRef, std::string > > getInterfaceList(void);
private:
};

#pragma GCC visibility pop
#endif
