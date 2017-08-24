//
//  main.mm
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <functional>
#include <vector>
#include <CoreFoundation/CoreFoundation.h>
#include "Matcher.hpp"

NSString* myPath;

int main(int argc, const char * argv[])
{
    myPath = [[NSBundle mainBundle] executablePath];

    if (argc == 3 && strcmp(argv[1], "-matcher") == 0)
    {
        // we have been set up with 3 streams:
        // stdin: input (for commands, like PAUSE, RESUME)
        // stdout: output (for results, like OPENED, CLOSED, PLAYING)
        // stderr: output (for log)
        Matcher m(argv[2]);
        m.start();
        return 0;
    }
    else
    {
        return NSApplicationMain(argc, argv);
    }
}
