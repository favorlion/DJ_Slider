//
//  CurlHelper.h
//  Slider
//
//  Created by Dmitry Volkov on 08.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

//#ifndef Slider_CurlHelper_h
//#define Slider_CurlHelper_h

#import <curl/curl.h>
#import <string>
#import <functional>
#import <Foundation/Foundation.h>

class CurlHelper {
public:
    CurlHelper();
    ~CurlHelper();
    
    CurlHelper(const CurlHelper&) = delete;
    CurlHelper operator = (const CurlHelper&) = delete;

    bool signIn(const char* user, const char* pass);
    void signOut();

    void setProgressFunc(std::function<void(void*, double)> f, void* d)
    {
        progressFunc = f;
        progressData = d;
    }
    void callProgressFunc(double v)
    {
        if (progressFunc)
            progressFunc(progressData, v);
    }

    std::string partiesJSON();
    std::string messagesJSON(const char* partyID);
    std::string requestJSON(const char* partyID);
    NSData* inventoryJSON(const char* partyID);
    
    std::string sequencesJSON(const char* partyID, unsigned long lastKnownSequence);
    
    bool sendBroadcastMessage(const char* partyID, const char* msg);
    bool sendMessageToGuest(const char* partyID, const char* customerId, const char* msg, const char* requestId);
    
    bool uploadSongs(const char* partyID, const char* filePath);
    
    bool postSelectedSong(const char* partyID, const char* artist,
                          const char* title, const char* path, const char* startTime,
                          const char* fp, int fp_duration);
    
    bool deleteRequest(const char* requestID);
    bool completeRequest(const char* requestID, const char* partyID,
                         unsigned long played_begin, unsigned long played_end,
                         const char *file, const char* fileArtist, const char* fileTitle);
    void reset();
    bool resetParty(const char* partyID);
    
private:
    CURL *curlHandle;
    std::string authenticityToken;
    std::function<void(void*, double)> progressFunc;
    void* progressData;
    NSLock *mutex;
};

extern CurlHelper* gCurlHelper;

//#endif
