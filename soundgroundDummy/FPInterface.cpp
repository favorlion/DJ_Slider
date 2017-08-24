//
//  FPInterface.cpp
//  Slider
//
//  Created by Joachim Wieland on 4/22/16.
//  Copyright © 2016 Joachim Wieland. All rights reserved.
//

#include "FPInterface.h"

int getChromaprintFP(const std::string& filename, std::string& fp, int& duration)
{
    // return a fake Fingerprint
    fp = "FakeFingerprint";
    duration = 10;
    return 0;
}