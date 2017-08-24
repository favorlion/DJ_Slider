//
//  MatcherRules.h
//  Slider
//
//  Created by Joachim Wieland on 5/27/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#ifndef MatcherRules_h
#define MatcherRules_h

#include <string>
#include <deque>
#include <vector>
#include <map>
#include <ctime>

class MatcherRules {
private:
    class DataPoint;
public:
    // a song is considered playing if we see it once in atLeastOnceInThisManySeconds with a score of less than maxScoreForPlaying

    // a song is considered completed if we saw it atLeastOnceInThisManySeconds for durationForCompletion seconds
    
    // a song is considered expired if we haven't seen it in expireNotSeen seconds with a score less than minScoreForExpiration

    MatcherRules(int durationForCompletion = 30,
                 int atLeastOnceInThisManySeconds = 5,
                 int expireNotSeen = 30,
                 float maxScoreForPlaying = 0.085,
                 float minScoreForExpiration = 0.150);
    const std::vector< std::string > getCurrentlyOpen() const;
    const std::vector< std::string > getCurrentlyPlaying();
    const std::vector< std::pair< time_t, std::string > > getCompleted();

    void fileOpened(const std::string& filename);
    void fileClosed(const std::string& filename);
    void addDP(const std::string filename, float score, time_t t = 0);
    void testSetTimeNow(time_t t) { currentTime = t; }
    size_t testCountDatapoints(void) { return dps.size(); }
    time_t getYoungestTimestamp(const std::string& filename) const;
    time_t getCurrentTime(void) {
        return currentTime ? currentTime : time(NULL);
    }
    void clear(void) {
        dps.clear();
        openFiles.clear();
        currentTime = 0;
    }
private:
    class DataPoint {
    public:
        // primarily for testing to override the time, otherwise it will be the current time
        DataPoint(std::string filename, float score, time_t t = 0)
        : score(score) {
            this->filename = filename;
            if (!t)
                this->t = time(nullptr);
            else
                this->t = t;
        }
        time_t getTime() const { return t; }
        float getScore() const { return score; }
        const std::string& getFilename() const { return filename; }
    private:
        time_t t;
        float score;
        std::string filename;
    };

    std::map< std::string, time_t > compact();
    void addDP(const DataPoint dp);
    std::deque<DataPoint> dps;
    std::vector< std::string > openFiles;
    time_t currentTime;
    int atLeastOnceInThisManySeconds;
    int durationForCompletion;
};

extern MatcherRules* gMatcherRules;

#endif /* MatcherRules_h */
