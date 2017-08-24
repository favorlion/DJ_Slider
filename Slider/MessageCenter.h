//
//  MessageCenter.h
//  Slider
//
//  Created by Dmitry Volkov on 10.01.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CurlHelper.h"
#import "SongEntity.h"

@class Request;
@class MessageCollection;
@class CommunicationCenter;

@interface Customer : NSObject
@property (nonatomic, readonly, copy) NSString* name;
@property (nonatomic, readonly) NSNumber* custId;
-(instancetype)initWithDictionary:(NSDictionary*)dict;
@end

@interface CustomerCollection : NSObject
-(instancetype)init;
-(void)reset;
-(NSUInteger)count;
-(void)addCustomer:(Customer*)cust;
-(Customer*)byId:(NSNumber*)custId;
@end

@interface Message : NSObject
-(instancetype)initWithDictionary:(NSDictionary*)dict;
-(NSString*)custName;
-(NSNumber*)custId;
-(NSString*)ageAsString;
-(BOOL)isToCustomer;
-(BOOL)isFromCustomer;
-(BOOL)isBroadcast;
-(BOOL)isRequestRelated;
-(NSString*)relativeTimeString;
-(NSAttributedString*)formattedText;
@property (nonatomic, readonly) NSNumber* msgId;
@property (nonatomic, readonly) NSNumber* reqId;
@property (nonatomic, readonly) long party_seq;
@property (nonatomic, readonly) Customer* customer;
@property (nonatomic, readonly, copy) NSDate* time_sent;
@property (nonatomic, readonly, copy) NSString* text;
@property (nonatomic) BOOL seen;
@property (nonatomic) BOOL visible;
@end

@interface Request : NSObject
-(instancetype)initWithDictionary:(NSDictionary*)dict;
-(instancetype)initWithDictionary:(NSDictionary*)dict andMessageCollection:(MessageCollection*)msgCollection;
-(NSString*)display;
-(NSString*)custName;
-(NSNumber*)custId;
-(NSString*)relativeTimeString;
-(NSArray*)messages;
-(BOOL)haveSeenAllMessages;
-(void)setSeenAllMessages;
-(void)completeWithSong:(SongEntity*)song
                inParty:(NSString*)partyIdX
            withStarted:(NSDate*)startDate;
-(BOOL)requestedFileExists;
-(BOOL)complete;
-(BOOL)visible;
-(void)delete;
-(long)highestSeqNo;
@property (nonatomic, readonly) NSNumber *reqId;
@property (nonatomic, readonly) long party_seq;
@property (nonatomic, readonly) Customer* customer;
@property (nonatomic, readonly, copy) NSString* tip_currency;
@property (nonatomic, readonly) float tip_amount;
@property (nonatomic, readonly, copy) NSString* title;
@property (nonatomic, readonly, copy) NSString* artist;
@property (nonatomic, readonly, copy) Message* initialMessage;
@property (nonatomic, readonly, copy) NSString* requested_file;
@property (nonatomic, readonly, copy) NSString* played_file;
@property (nonatomic, readonly, copy) NSDate* time_played_begin;
@property (nonatomic, readonly, copy) NSDate* time_played_end;
@property (nonatomic, readonly, copy) NSDate* time_requested;
@property (nonatomic, copy) NSString* bpm;
@property (nonatomic) BOOL deleted;
@property (nonatomic, readonly) MessageCollection* msgCollection;
@end

@interface MessageCollection : NSObject
-(instancetype)initWithCommCenter:(CommunicationCenter*)commCtr;
-(void)addMessage:(Message*)msg;
-(void)removeMessage:(Message*)msg;
-(void)removeMessagesRelatedToRequest:(Request*)req;
-(Message*)byId:(NSNumber*)msgId;
-(NSUInteger)count;
-(NSUInteger)countCustomers;
-(void)reset;
-(NSArray*)orderedCustomers;
-(NSArray*)byCustomer:(Customer*)cust;
-(NSArray*)byRequest:(Request*)req;
-(Message*)newestFromCustomer:(Customer*)cust;
-(Message*)newestFromOrToCustomer:(Customer*)cust;
-(BOOL)haveSeenAllFromCustomer:(Customer*)cust;
-(void)setSeenAllFromCustomer:(Customer*)cust;
-(BOOL)haveSeenAllMessagesForRequest:(Request*)req;
-(void)setSeenAllMessagesForRequest:(Request*)req;
@property (nonatomic, readonly) long highestSeqNo;
@end

@interface RequestCollection : NSObject
-(instancetype)initWithCommCenter:(CommunicationCenter*)commCtr;
-(NSUInteger)count;
-(Request*)byId:(NSNumber*)reqId;
-(NSArray*)byFile:(NSString*)file;
-(void)addRequest:(Request*)req;
-(void)removeRequest:(Request*)req;
-(NSArray*)getOpenRequestsForFile:(NSString*) path;
-(void)requestNowPlaying:(NSString*)songPath;
-(NSArray*)orderedByDate;
@property (nonatomic, readonly) long highestSeqNo;
@end

@interface CommunicationCenter : NSObject
+(NSDate*)parseTimestamp:(NSString*)timestamp;
+(NSString*)relativeTimestampStringForDate:(NSDate*)date;
-(instancetype)init;
-(void)reset;
-(void)updateMessages:(NSString*)partyId;
-(MessageCollection*)messageCollection;
-(RequestCollection*)requestCollection;
@property (nonatomic, readonly) long highestSeqNo;
@property (readonly, copy) NSString* partyId;
@end

extern CommunicationCenter* gCommCenter;
