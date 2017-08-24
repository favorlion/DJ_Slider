//
//  MatcherRules.cpp
//  Slider
//
//  Created by Joachim Wieland on 5/27/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#include "MatcherRules.h"
#include <map>
#include <iostream>
#include <assert.h>

MatcherRules* gMatcherRules;

using namespace std;

MatcherRules::MatcherRules(int durationForCompletion,
                           int atLeastOnceInThisManySeconds,
                           int expireNotSeen,
                           float maxScoreForPlaying,
                           float minScoreForExpiration)
{
    currentTime = 0;
    this->atLeastOnceInThisManySeconds = atLeastOnceInThisManySeconds;
    this->durationForCompletion = durationForCompletion;
    gMatcherRules = this;
}

const vector< pair< time_t, string > > MatcherRules::getCompleted() {

    // compact our list of datapoints
    map< string, time_t > v = compact();
    vector< pair< time_t, string > > r;
    
    // now what's left is currently playing
    // the timestamp is the oldest valid timestamp
    for (auto x : v) {
        time_t oldestTimestampForThisSong = x.second;
        time_t youngestTimestampForThisSong = getYoungestTimestamp(x.first);
        if (youngestTimestampForThisSong - oldestTimestampForThisSong >= durationForCompletion) {
            pair< time_t, string > p(oldestTimestampForThisSong, x.first);
            r.push_back(p);
        }
    }
    
    return r;
}

const vector< string > MatcherRules::getCurrentlyPlaying() {
    // compact our list of datapoints
    map< string, time_t > v = compact();
    vector< string > r;

    // now what's left is currently playing
    for (auto x : v) {
        r.push_back(x.first);
    }

    return r;
}

map< string, time_t > MatcherRules::compact() {
    map< string, time_t > valid;
    map< string, time_t > invalid;

    // go back from the end
    auto cit = dps.crbegin();
    
    // test for emptyness
    if (cit == dps.crend())
        return valid;
    
    do {
        // if we have never seen it, it's valid, enter time for it
        
        // if we have seen it and the previous time is within boundaries, it's ok, update the time
        
        // if we have seen it but the previous time is outside of boundaries, it's invalid incuding that time
        
        const std::string& f = cit->getFilename();

        // if it's invalid already, it stays invalid
        if (invalid.find(f) != invalid.end()) {
            // invalid, nothing else to do
        } else if (valid.find(f) == valid.end()) {
            // never seen it
            
            // it's neither in invalid nor in valid at this point, so it's the first time we see this data point. Before inserting it into valid, check if the youngest data point is too old or not
            if ((getCurrentTime() - cit->getTime()) > atLeastOnceInThisManySeconds) {
                // the youngest datapoint is already too old, it's invalid
                invalid.insert(make_pair(f, cit->getTime()));
            } else {
                // it's a young enough start of a sequence, add to valid
                auto p = make_pair(f, cit->getTime());
                valid.insert(p);
            }
        } else {
            // because we go backwards, the time we're seeing now is the previous time compared to what we have recorded
            time_t prevTime = cit->getTime();
            time_t laterTime = valid[f];
            
            if (laterTime - prevTime <= atLeastOnceInThisManySeconds) {
                // valid, update the time
                valid[f] = prevTime;
                //std::cout << "Got time: " << prevTime << " for " << f << "\n";
            } else {
                // invalid, will get cleaned out
                invalid.insert(make_pair(f, max(prevTime, laterTime)));
            }
        }
        cit++;
    } while (cit != dps.crend());

    // now delete the invalid ones
    auto it = dps.begin();
    do {
        const std::string& f = it->getFilename();
        auto inv_it = invalid.find(f);
        if (inv_it != invalid.end()) {
            time_t minValidTime = inv_it->second;
            if (it->getTime() < minValidTime) {
                it = dps.erase(it);
                continue;
            }
        }
        it++;
    } while (it != dps.end());
    
    // what's left is currently playing
    return valid;
}

time_t MatcherRules::getYoungestTimestamp(const std::string& filename) const {
    auto cit = dps.crbegin();
    
    // we must have at least one matching entry
    assert(cit != dps.crend());

    do {
        if (filename == cit->getFilename()) {
            return cit->getTime();
        }
        cit++;
    } while (cit != dps.crend());
    
    assert(false);
    return 0;
}

void MatcherRules::addDP(const string filename, float score, time_t t) {
    DataPoint dp(filename, score, t);
    assert(t < 40);
    addDP(dp);
}

void MatcherRules::addDP(const MatcherRules::DataPoint dp) {
    dps.push_back(dp);
}

void MatcherRules::fileOpened(const string& filename) {
    openFiles.push_back(filename);
}

void MatcherRules::fileClosed(const string& filename) {
    auto it = openFiles.begin();
    while (it != openFiles.end()) {
        if (*it == filename) {
            openFiles.erase(it);
            return;
        }
        it++;
    }
}

const vector< string > MatcherRules::getCurrentlyOpen() const {
    return openFiles;
}