//
//  CurlHelper.m
//  Slider
//
//  Created by Dmitry Volkov on 08.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "CurlHelper.h"
#import "HTMLParser.h"
#import "BZipCompression.h"
#import <cmath>

#define HOSTNAME "https://www.morequests.com"

std::string gReadBuffer;

static size_t writeCallback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    gReadBuffer.append((char*)contents, realsize);
    return realsize;
}

static std::string readAuthenticityToken()
{
    NSString* html = [NSString stringWithFormat:@"%s", gReadBuffer.c_str()];
    NSString* token = nil;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    std::string authenticityToken;
    
    if (error)
    {
        //NSLog(@"Error:%@ FILE: %s LINE: %d ", error, __FILE__, __LINE__);
        return nil;
    }

    HTMLNode *bodyNode = [parser head];
    NSArray *inputNodes = [bodyNode findChildTags:@"meta"];

    for (HTMLNode *inputNode in inputNodes)
    {
        if ([[inputNode getAttributeNamed:@"name"] isEqualToString:@"csrf-token"])
        {
            token = [[inputNode getAttributeNamed:@"content"] copy];
            break;
        }
    }
    
    if (token)
    {
        authenticityToken = [token UTF8String];
    }
    
    return authenticityToken;
}

CurlHelper::CurlHelper() : curlHandle(nullptr)
{
    mutex = [[NSLock alloc] init];
}

CurlHelper::~CurlHelper()
{
    signOut();
}

bool CurlHelper::signIn(const char* user, const char* pass)
{
    curl_global_init( CURL_GLOBAL_ALL );
    curlHandle = curl_easy_init ();
    
    curl_easy_setopt(curlHandle, CURLOPT_USERAGENT,
                     "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322)");
    curl_easy_setopt(curlHandle, CURLOPT_AUTOREFERER, 1);
    curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curlHandle, CURLOPT_COOKIE, "");
    curl_easy_setopt(curlHandle, CURLOPT_COOKIEJAR, "");
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback);
    curl_easy_setopt(curlHandle, CURLOPT_SSL_VERIFYHOST, 2L);
    
    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sign_in");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }
    
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sign_in");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }
    
    char data[1024];
    authenticityToken = readAuthenticityToken();
    
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(data, sizeof(data), "session[username]=%s&session[password]=%s&authenticity_token=%s", user, pass, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sessions");
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);
    gReadBuffer.clear();
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        // reset the handle to the non-POST default
        curl_easy_setopt(curlHandle, CURLOPT_POST, false);

        return false;
    }

    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/menu");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        // reset the handle to the non-POST default
        curl_easy_setopt(curlHandle, CURLOPT_POST, false);

        return false;
    }

    authenticityToken = readAuthenticityToken();

    long httpCode = 0;
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    // reset the handle to the non-POST default
    curl_easy_setopt(curlHandle, CURLOPT_POST, false);

    if (200 == httpCode)
    {
        return true; 
    }

    return false;
}

void CurlHelper::signOut()
{
    curl_easy_cleanup(curlHandle);
    curl_global_cleanup();
    curlHandle = nullptr;
}

std::string CurlHelper::partiesJSON()
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/my_parties.json");
    curl_easy_perform(curlHandle);
    
    [mutex unlock];
    
    return gReadBuffer;
}

std::string CurlHelper::messagesJSON(const char* partyID)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/messages.json", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    
    [mutex unlock];
    
    return gReadBuffer;
}

std::string CurlHelper::requestJSON(const char* partyID)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/requests.json", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    [mutex unlock];
    
    return gReadBuffer;
}

static int progressMeter(void *p,
                         curl_off_t dltotal, curl_off_t dlnow,
                         curl_off_t ultotal, curl_off_t ulnow)
{
    float up_percent = 100.0f * (float) ulnow / (float) ultotal;
    float down_percent = 100.0f * (float) dlnow / (float) dltotal;

    CurlHelper* ch = (CurlHelper*) p;

    if (!std::isnan(up_percent))
        ch->callProgressFunc(up_percent);
    else if (!std::isnan(down_percent))
        ch->callProgressFunc(down_percent);

    fprintf(stderr, "UP %%: %2f - DOWN %%: %2f\n", up_percent, down_percent);

    return 0;
}

// what I don't like about this is that the upload has the BZip2Compression outside of curl but for the download it's within curl...
NSData* CurlHelper::inventoryJSON(const char* partyID)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    long httpCode = 0;

    [mutex lock];

    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/inventory.json?compress=1", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    
    curl_easy_setopt(curlHandle, CURLOPT_XFERINFOFUNCTION, progressMeter);
    curl_easy_setopt(curlHandle, CURLOPT_XFERINFODATA, this);
    curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 0L);
    
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 1L);

    [mutex unlock];

    if (CURLE_OK == res && 200 == httpCode)
    {
        NSError* error = nil;
        NSData* bz2Data = [NSData dataWithBytes:gReadBuffer.c_str() length:gReadBuffer.length()];
        return [BZipCompression decompressedDataWithData:bz2Data error:&error];
    }
    else
    {
        return nil;
    }
}

bool CurlHelper::uploadSongs(const char* partyID, const char* filePath)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[1024] = {0};
    snprintf(url, sizeof(url), "%s/parties/%s/putinventory.json", HOSTNAME, partyID);

    struct curl_httppost *formpost=NULL;
    struct curl_httppost *lastptr=NULL;
    
    curl_formadd(&formpost,
                 &lastptr,
                 CURLFORM_COPYNAME, "authenticity_token",
                 CURLFORM_COPYCONTENTS, authenticityToken.c_str(),
                 CURLFORM_END);
    
    curl_formadd(&formpost,
                 &lastptr,
                 CURLFORM_COPYNAME, "inventory",
                 CURLFORM_FILE, filePath,
                 CURLFORM_END);
    
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_COOKIE, "");
    curl_easy_setopt(curlHandle, CURLOPT_COOKIEJAR, "");
    curl_easy_setopt(curlHandle, CURLOPT_HTTPPOST, formpost);
    curl_easy_setopt(curlHandle, CURLOPT_CUSTOMREQUEST, "PUT");
    curl_easy_setopt(curlHandle, CURLOPT_XFERINFOFUNCTION, progressMeter);
    curl_easy_setopt(curlHandle, CURLOPT_XFERINFODATA, this);
    curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 0L);
    
    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    // reset the handle to the non-POST default
    curl_easy_setopt(curlHandle, CURLOPT_POST, false);
    curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 1L);
    
    [mutex unlock];

    if (CURLE_OK == res && 201 == httpCode)
    {
        return true;
    }
    
    return false;
}


// Post selected song for third window on slider panel to the server
bool CurlHelper::postSelectedSong(const char* partyID, const char* artist,
                                  const char* title, const char* path, const char* startTime,
                                  const char* fp, int fp_duration)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[1024] = {0};

    snprintf(url, sizeof(url), "%s/new_playlist_entry.json", HOSTNAME);

    char data[32000] = {0};
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    char *escapedArtist = curl_easy_escape(curlHandle, artist, (int)strlen(artist));
    char *escapedTitle = curl_easy_escape(curlHandle, title, (int)strlen(title));
    char *escapedPath = curl_easy_escape(curlHandle, path, (int)strlen(path));
    char *escapedFp = curl_easy_escape(curlHandle, fp, (int)strlen(fp));

    snprintf(data, sizeof(data), "party_id=%s&artist=%s&title=%s&filename=%s&startTime=%s&fp=%s&fp_duration=%d&authenticity_token=%s",
             partyID, escapedArtist, escapedTitle, escapedPath, startTime, escapedFp, fp_duration, escapedAuthtoken);

    curl_free(escapedAuthtoken);
    curl_free(escapedArtist);
    curl_free(escapedTitle);
    curl_free(escapedPath);
    curl_free(escapedFp);

    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);

    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    // reset the handle to the non-POST default
    curl_easy_setopt(curlHandle, CURLOPT_POST, false);

    [mutex unlock];
    
    if (CURLE_OK == res && 201 == httpCode)
    {
        return true;
    }

    return false;
}

std::string CurlHelper::sequencesJSON(const char* partyID, unsigned long lastKnownSequence)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    gReadBuffer.clear();
    
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/sequence.json?last_known=%lu", HOSTNAME, partyID, lastKnownSequence);

    curl_easy_setopt(curlHandle, CURLOPT_POST, false);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback);
    curl_easy_perform(curlHandle);
    
    [mutex unlock];
    
    return gReadBuffer;
}

bool CurlHelper::sendBroadcastMessage(const char* partyID, const char* msg)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[1024] = {0};

    snprintf(url, sizeof(url), "%s/new_broadcast", HOSTNAME);

    char data[4096] = {0};
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    char *escapedMsg = curl_easy_escape(curlHandle, msg, (int)strlen(msg));
    snprintf(data, sizeof(data), "party_id=%s&msg=%s&authenticity_token=%s",
             partyID, escapedMsg, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    curl_free(escapedMsg);

    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);

    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    // reset the handle to the non-POST default
    curl_easy_setopt(curlHandle, CURLOPT_POST, false);

    [mutex unlock];
    
    if (CURLE_OK == res && 200 == httpCode)
    {
        return true;
    }

    return false;
}

bool CurlHelper::sendMessageToGuest(const char* partyID, const char* customerId, const char* msg, const char* requestId)
{
    //Poco::Mutex::ScopedLock lock(mutex);
    
    [mutex lock];
    
    char url[1024] = {0};
    snprintf(url, sizeof(url), "%s/new_message", HOSTNAME);

    char data[4096] = {0};
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    char *escapedMsg = curl_easy_escape(curlHandle, msg, (int)strlen(msg));
    snprintf(data, sizeof(data), "party_id=%s&to_customer_id=%s&message=%s&request_id=%s&authenticity_token=%s",
             partyID, customerId, escapedMsg, requestId, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    curl_free(escapedMsg);

    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);

    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    // reset the handle to the non-POST default
    curl_easy_setopt(curlHandle, CURLOPT_POST, false);

    [mutex unlock];
    
    if (CURLE_OK == res && 200 == httpCode)
    {
        return true;
    }
    
    NSLog(@"Error can't send message to guest( HTTP CODE == %ld", httpCode);

    return false;
}

bool CurlHelper::deleteRequest(const char* requestID)
{
    [mutex lock];
    char url[4096];
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(url, sizeof(url), "%s/requests/%s.json?authenticity_token=%s", HOSTNAME, requestID, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    curl_easy_setopt(curlHandle, CURLOPT_CUSTOMREQUEST, "DELETE");
    
    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    
    // have a more global reset
    curl_easy_reset(curlHandle);

    [mutex unlock];

    // returns "204 - no content" for JSON on success
    if (CURLE_OK == res && 204 == httpCode)
    {
        return true;
    }
    return false;
}

bool CurlHelper::resetParty(const char* partyID)
{
    [mutex lock];
    char url[4096];
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(url, sizeof(url), "%s/parties/%s/reset.json?authenticity_token=%s", HOSTNAME, partyID, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_CUSTOMREQUEST, "DELETE");
    
    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    
    // have a more global reset
    curl_easy_reset(curlHandle);
    
    [mutex unlock];
    
    // returns "204 - no content" for JSON on success
    if (CURLE_OK == res && 204 == httpCode)
    {
        return true;
    }
    return false;
}

bool
CurlHelper::completeRequest(const char* requestID, const char* partyID,
                            unsigned long played_begin, unsigned long played_end,
                            const char *file, const char* fileArtist, const char* fileTitle)
{
    [mutex lock];
    char url[4096];
    char data[4096] = {0};

    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(url, sizeof(url), "%s/requests/%s/complete.json?authenticity_token=%s", HOSTNAME, requestID, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    gReadBuffer.clear();

    char *escapedFile = curl_easy_escape(curlHandle, file, (int)strlen(file));
    char *escapedFileArtist = curl_easy_escape(curlHandle, fileArtist, (int)strlen(fileArtist));
    char *escapedFileTitle = curl_easy_escape(curlHandle, fileTitle, (int)strlen(fileTitle));
    
    snprintf(data, sizeof(data), "party_id=%s&time_played_begin=%lu&time_played_end=%lu&played_file=%s&played_file_artist=%s&played_file_title=%s",
             partyID, played_begin, played_end, escapedFile, escapedFileArtist, escapedFileTitle);
    
    curl_free(escapedFileTitle);
    curl_free(escapedFileArtist);
    curl_free(escapedFile);
    
    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);
    curl_easy_perform(curlHandle);

    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);
    
    // have a more global reset
    curl_easy_reset(curlHandle);
    
    [mutex unlock];
    
    // returns "204 - no content" for JSON on success
    if (CURLE_OK == res && (204 == httpCode || 200 == httpCode))
    {
        return true;
    }
    return false;
}

void CurlHelper::reset()
{
    //Poco::Mutex::ScopedLock lock(mutex);
    curl_easy_reset(curlHandle);
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback);
}
