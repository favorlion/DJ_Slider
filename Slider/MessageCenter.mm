//
//  MessageCenter.m
//  Slider
//
//  Created by Dmitry Volkov on 10.01.16.
//  Copyright © 2016 Automatic System Metering. All rights reserved.
//

#import "MessageCenter.h"
#import "CurlHelper.h"
#import "Configuration.h"
#import "SongEntity.h"
#import "BPMDetectorInterface.h"
#import "ArtistAndTitleTableViewController.h"

CommunicationCenter* gCommCenter;

@implementation Customer
-(instancetype)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    _custId = dict[@"id"];
    _name = dict[@"name"];
    return self;
}
@end

@implementation Message
{
    char direction; // 't'o or 'f'rom customer or 'b' for broadcast
}
-(instancetype)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    _msgId = dict[@"id"];
    _reqId = dict[@"request_id"];

    if (_reqId && [_reqId isKindOfClass:[NSNull class]])
        _reqId = nil;

    NSDictionary* to_cust = dict[@"to_customer"];
    if (to_cust && [to_cust isKindOfClass:[NSNull class]])
        to_cust = nil;
    NSDictionary* from_cust = dict[@"from_customer"];
    if (from_cust && [from_cust isKindOfClass:[NSNull class]])
        from_cust = nil;
    NSAssert(!(to_cust && from_cust), @"Both to_customer and from_customer set in message with id %@", dict[@"id"]);

    NSDictionary* cust = to_cust;
    if (!cust)
        cust = from_cust;

    // it's a broadcast if we have neither to_customer nor from_customer
    direction = 'b';
    if (cust) {
        _customer = [[Customer alloc] initWithDictionary:cust];
        if (to_cust == cust)
            direction = 't';
        if (from_cust == cust)
            direction = 'f';
    }

    _time_sent = [CommunicationCenter parseTimestamp:dict[@"tm"]];
    _text = dict[@"msg"];
    _party_seq = [dict[@"party_seq"] longValue];

    // initialize to NO
    _seen = NO;
    
    // visible if not associated to a request OR the request visible
    _visible = YES;

    return self;
}
-(NSString*)custName
{
    if (_customer)
        return [_customer name];
    else
        return nil;
}
-(NSNumber*)custId
{
    if (_customer)
        return [_customer custId];
    else
        return nil;
}
-(NSString*)ageAsString
{
    return @"x min y sec";
}
-(Request*)request
{
    //Request* req = _reqId;
    return nil;
}
-(BOOL)isFromCustomer
{
    return direction == 'f';
}
-(BOOL)isToCustomer
{
    return direction == 't';
}
-(BOOL)isBroadcast
{
    return direction == 'b';
}
-(BOOL)isRequestRelated
{
    return _reqId != nil;
}
-(NSString*)relativeTimeString
{
    return [CommunicationCenter relativeTimestampStringForDate:_time_sent];
}
-(NSAttributedString*)formattedText
{
    NSString* relativeTimeStampString = [self relativeTimeString];
    NSDictionary* style = [self getFormatStyle];

    NSString* timeStr = [NSString stringWithFormat:@"%@ - %@\n", style[@"sender"], relativeTimeStampString];
    long timeStrLen = [timeStr length];
    NSString* msgStr = [NSString stringWithFormat:@"%@\n\n", _text];
    long msgStrLen = [msgStr length];
    NSString* newMsg = [NSString stringWithFormat:@"%@%@", timeStr, msgStr];
    
    NSMutableAttributedString *attrString =
    [[NSMutableAttributedString alloc] initWithString:newMsg];
    
    [attrString addAttribute:NSForegroundColorAttributeName
                       value:style[@"bgColor"] range:NSMakeRange(0, [attrString length])];
    
    [attrString addAttribute:NSParagraphStyleAttributeName
                       value:style[@"pgStyle"] range:NSMakeRange(0, [attrString length])];
    
    NSFont* timeStampFont = [NSFont systemFontOfSize:8.0f];
    NSFont* messageFont = [NSFont systemFontOfSize:14.0f];
    
    [attrString addAttribute:NSFontAttributeName
                       value:timeStampFont range:NSMakeRange(0, timeStrLen)];
    
    [attrString addAttribute:NSFontAttributeName
                       value:messageFont range:NSMakeRange(timeStrLen, msgStrLen)];
    
    return attrString;
}
// this is private
-(NSDictionary*)getFormatStyle
{
    // returns a dictionary with
    // "sender" => NSString* to sender name
    // "bgColor" => NSColor* to the backgroundColor
    // "pgStyle" => NSParagraphStyle*
    
    NSMutableDictionary* style = [[NSMutableDictionary alloc] init];
    
    style[@"pgStyle"] = [[NSMutableParagraphStyle alloc]init];
    
    NSAssert(![self isBroadcast], @"getFormatStyle called on a broadcast message");
    
    if ([self isFromCustomer])
    {
        // message from the customer to the DJ
        style[@"bgColor"] = [NSColor colorWithCalibratedRed:0.191f green:0.515f blue:0.984f alpha:1.0f];
        [style[@"pgStyle"] setAlignment: NSTextAlignmentLeft];
        style[@"sender"] = [[self customer] name];
    }
    else
    {
        // message from the DJ to the customer
        style[@"bgColor"] = [NSColor colorWithCalibratedRed:0.591f green:0.100f blue:0.100f alpha:1.0f];
        [style[@"pgStyle"] setAlignment: NSTextAlignmentRight];
        style[@"sender"] = @"You";
    }
    return style;
}
@end

@implementation Request
-(instancetype)initWithDictionary:(NSDictionary*)dict
{
    return [self initWithDictionary:dict andMessageCollection:nil];
}
-(instancetype)initWithDictionary:(NSDictionary*)dict andMessageCollection:(MessageCollection*)msgCollection
{
    self = [super init];

    _msgCollection = msgCollection;
    
    _reqId = dict[@"id"];
    _party_seq = [dict[@"party_seq"] intValue];
    _customer = [[Customer alloc] initWithDictionary:dict[@"customer"]];
    
    _artist = dict[@"artist"];
    _title = dict[@"title"];
    _requested_file = dict[@"filename"];
    
    _played_file = dict[@"played_file"];
    
    _time_played_begin = _time_played_end = nil;
    if (dict[@"time_played_begin"] && [dict[@"time_played_begin"] intValue] > 0)
        _time_played_begin = [NSDate dateWithTimeIntervalSince1970:[dict[@"time_played_begin"] intValue]];
    if (dict[@"time_played_end"] && [dict[@"time_played_end"] intValue] > 0)
        _time_played_end = [NSDate dateWithTimeIntervalSince1970:[dict[@"time_played_end"] intValue]];
    
    _tip_amount = 0.0;
    if (dict[@"tip_amount"] && ![dict[@"tip_amount"] isKindOfClass:[NSNull class]]) {
         _tip_amount = [dict[@"tip_amount"] floatValue];
    }
    _tip_currency = dict[@"tip_currency"];
    
    _time_requested = [CommunicationCenter parseTimestamp:dict[@"tm"]];
    _bpm = dict[@"bpm"];
    
    _deleted = [dict[@"deleted"] intValue] == 1;
    
    if (dict[@"msg"] && [dict[@"msg"] isKindOfClass:[NSString class]] && [dict[@"msg"] length] > 0) {
        NSMutableDictionary* msgdict = [dict mutableCopy];
        msgdict[@"to_customer"] = [NSNull null];
        msgdict[@"from_customer"] = msgdict[@"customer"];
        msgdict[@"request_id"] = msgdict[@"id"];
        msgdict[@"id"] = @0;
        _initialMessage = [[Message alloc] initWithDictionary:msgdict];
    } else {
        _initialMessage = nil;
    }
    
    return self;
}
-(NSString*)display
{
    return [NSString stringWithFormat:@"$%d %@ - %@",
            (int) [self tip_amount], [self artist], [self title]];
}
-(BOOL)requestedFileExists
{
    NSURL *url = [NSURL fileURLWithPath:_requested_file isDirectory:NO];
    NSError *err;
    return [url checkResourceIsReachableAndReturnError:&err];
}
-(NSString*)custName
{
    if (_customer)
        return [_customer name];
    else
        return nil;
}
-(NSNumber*)custId
{
    if (_customer)
        return [_customer custId];
    else
        return nil;
}
-(NSString*)relativeTimeString
{
    return [CommunicationCenter relativeTimestampStringForDate:_time_requested];
}
-(BOOL)complete
{
    return _played_file && _time_played_begin && _time_played_end;
}
-(BOOL)visible
{
    if (_deleted)
        return NO;
    
    if (self.complete) {
        // show it for two more minutes after it started playing
        NSDate* disappear_time = [_time_played_begin dateByAddingTimeInterval:60*2];
        return [[NSDate date] isLessThan:disappear_time];
    }

    return YES;
}
-(void)delete
{
    [self setDeleted:YES];
    [_msgCollection removeMessagesRelatedToRequest:self];
}
-(NSArray*)messages
{
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    if ([self initialMessage]) {
        [arr addObject:[self initialMessage]];
    }
    [arr addObjectsFromArray:[_msgCollection byRequest:self]];
    return arr;
}
-(long)highestSeqNo
{
    long seq = [self party_seq];
    for (Message* msg in [self messages]) {
        seq = MAX(seq, [msg party_seq]);
    }
    return seq;
}
-(void)completeWithSong:(SongEntity*)song
                inParty:(NSString*)partyIdX
            withStarted:(NSDate*)startDate
{
    _time_played_begin = startDate;
    _time_played_end = [NSDate date];
    _played_file = [song path];
}
-(BOOL)haveSeenAllMessages
{
    NSArray* arr = [self messages];
    for (Message* msg in arr) {
        if (![msg seen])
            return NO;
    }
    return YES;
}
-(void)setSeenAllMessages
{
    NSArray* arr = [self messages];
    for (Message* msg in arr) {
        [msg setSeen:YES];
    }
}
@end

@implementation CustomerCollection
{
    NSMutableDictionary* custs;
}
-(instancetype)init
{
    self = [super init];
    custs = [[NSMutableDictionary alloc] init];
    return self;
}
-(void)reset
{
    [custs removeAllObjects];
}
-(NSUInteger)count
{
    return [custs count];
}
-(void)addCustomer:(Customer*)cust
{
    NSNumber* custId = [cust custId];
    NSAssert([custId isKindOfClass:[NSNumber class]], @"cust to add has no NSNumber id");
    
    // return if we have it already
    if ([custs objectForKey:custId])
        return;
    
    custs[custId] = cust;
}
-(Customer*)byId:(NSNumber*)custId
{
    NSAssert([custId isKindOfClass:[NSNumber class]], @"custId in byId has no NSNumber id");
    return custs[custId];
}
@end

@implementation RequestCollection
{
    NSMutableArray* requests;
    NSMutableDictionary* byIdDict;
    NSMutableDictionary* byFileDict;
    CustomerCollection* customers;
    CommunicationCenter* commCtr;
    NSLock* mutex;
}
-(instancetype)init
{
    return [self initWithCommCenter:nil];
}
-(instancetype)initWithCommCenter:(CommunicationCenter *)XcommCtr
{
    if (self = [super init]) {
        customers = [[CustomerCollection alloc] init];
        requests = [[NSMutableArray alloc] init];
        byIdDict = [[NSMutableDictionary alloc] init];
        byFileDict = [[NSMutableDictionary alloc] init];
        commCtr = XcommCtr;
        mutex = [[NSLock alloc] init];
    }
    return self;
}
-(NSUInteger)count
{
    [mutex lock];
    NSUInteger c = [requests count];
    [mutex unlock];
    return c;
}
-(void) addRequest:(Request *)req
{
    NSNumber* reqId = [req reqId];
    NSAssert([reqId isKindOfClass:[NSNumber class]], @"reqId in addRequest not an NSNumber");

    [mutex lock];

    // return if we have it already
    if ([byIdDict objectForKey:reqId])
    {
        [mutex unlock];
        return;
    }

    // add if we don't have yet
    [requests addObject:req];
    
    // update the byId dictionary
    byIdDict[reqId] = req;
    
    // update the byFile dictionary. Note that we could have multiple requests for the same file
    NSMutableArray* byFileArr = [byFileDict objectForKey:[req requested_file]];
    if (!byFileArr)
    {
        byFileArr = [[NSMutableArray alloc] init];
    }
    [byFileArr addObject:req];
    byFileDict[[req requested_file]] = byFileArr;
    
    // update the highestSeqCount
    if ([req party_seq] > _highestSeqNo)
        _highestSeqNo = [req party_seq];
    
    // check consistency
    NSAssert([requests count] == [byIdDict count], @"number of requests in requests and byIdDict doesn't match");
    NSUInteger x = 0;
    for(NSArray* arr in [byFileDict allValues]) {
        x += [arr count];
    }
    NSAssert(x == [requests count], @"number of requests in requests and byFileDict doesn't match");
    
    [mutex unlock];
}

// we can't immediate remove it, we need a mark-for-deletion-thing. If the ID has been handed out in the orderedRequests, we need to show it. The next time around, we don't include the ID anymore. If we have only one caller of the orderedRequests, we can clean it up before running the next ordering (because there we know that nobody has the ID still).

-(void)removeRequest:(Request*)req
{
    [mutex lock];
    
    NSNumber* reqId = [req reqId];
    NSAssert([reqId isKindOfClass:[NSNumber class]], @"reqId in addRequest not an NSNumber");
    NSAssert(byIdDict[reqId], @"request to remove not found");
    NSAssert(byFileDict[[req requested_file]], @"file of request to remove not found");

    [byIdDict removeObjectForKey:reqId];
    
    NSMutableArray *arr = byFileDict[[req requested_file]];

    for (Request* req in arr) {
        if ([[req reqId] isEqual:reqId]) {
            [arr removeObject:req];
            break;
        }
    }

    for (Request* req in requests) {
        if ([[req reqId] isEqual:reqId]) {
            [requests removeObject:req];
            break;
        }
    }
    
    // check consistency
    NSAssert([requests count] == [byIdDict count], @"number of requests in requests and byIdDict doesn't match");
    NSUInteger x = 0;
    for(NSArray* arr in [byFileDict allValues]) {
        x += [arr count];
    }
    NSAssert(x == [requests count], @"number of requests in requests and byFileDict doesn't match");

    [mutex unlock];
}
-(Request*)byId:(NSNumber *)reqId
{
    [mutex lock];
    NSAssert([reqId isKindOfClass:[NSNumber class]], @"reqId in byId has no NSNumber id");
    Request *req = byIdDict[reqId];
    [mutex unlock];
    return req;
}
-(NSArray*)byFile:(NSString*)file
{
    [mutex lock];
    NSArray* arr = [byFileDict[file] copy];
    [mutex unlock];

    if (!arr)
        arr = [[NSArray alloc] init];
    return arr;
}
-(NSArray*)getOpenRequestsForFile:(NSString*)file
{
    NSArray* requestsForFile = [self byFile:file];
    [mutex lock];
    NSAssert(requestsForFile, @"RequestsCollection::byFile returned nil");
    NSMutableArray *openRequests = [[NSMutableArray alloc] init];
    for (Request* req in requestsForFile)
    {
        if (![req complete])
        {
            [openRequests addObject:req];
        }
    }
    [mutex unlock];
    return openRequests;
}
-(NSArray*)orderedByDate
{
    NSMutableArray* canCleanup = [[NSMutableArray alloc] init];

    [mutex lock];
    
    // sort by time ascending so we have the newest request last
    NSSortDescriptor *dateDesc = [NSSortDescriptor
                                  sortDescriptorWithKey:@"time_requested"
                                  ascending:YES];
    NSArray *sortDescs = [NSArray arrayWithObject:dateDesc];
    NSArray *reqs = [requests sortedArrayUsingDescriptors:sortDescs];
    
    NSMutableArray *reqIds = [[NSMutableArray alloc] init];
    for (Request* req in reqs) {
        if ([req visible])
            [reqIds addObject:[req reqId]];
        else
            [canCleanup addObject:req];
    }

    [mutex unlock];

    // they're now no longer referenced and we can clean them up
    // this only holds as long as we have exactly one client that uses this function we're in now
    for (Request* req in canCleanup) {
        [self removeRequest:req];
    }

    return reqIds;
}
@end

@implementation MessageCollection
{
    NSMutableArray* messages;
    NSMutableDictionary* byIdDict;
    NSMutableDictionary* byCustDict;
    NSMutableDictionary* byReqDict;
    CustomerCollection* customers;
    CommunicationCenter* commCtr;
    NSLock* mutex;
}
-(instancetype)init
{
    return [self initWithCommCenter:nil];
}
-(instancetype)initWithCommCenter:(CommunicationCenter *)XcommCtr
{
    if (self = [super init]) {
        customers = [[CustomerCollection alloc] init];
        messages = [[NSMutableArray alloc] init];
        byIdDict = [[NSMutableDictionary alloc] init];
        byCustDict = [[NSMutableDictionary alloc] init];
        byReqDict = [[NSMutableDictionary alloc] init];
        commCtr = XcommCtr;
        mutex = [[NSLock alloc] init];
    }
    return self;
}
-(void)reset
{
    [mutex lock];
    [messages removeAllObjects];
    [byIdDict removeAllObjects];
    [byCustDict removeAllObjects];
    [byReqDict removeAllObjects];
    [customers reset];
    _highestSeqNo = 0;
    [mutex unlock];
}
-(NSUInteger)count
{
    [mutex lock];
    NSUInteger c = [messages count];
    [mutex unlock];
    return c;
}
-(void) addMessage:(Message *)msg
{
    NSNumber* msgId = [msg msgId];
    NSAssert([msgId isKindOfClass:[NSNumber class]], @"msgId in addMessage not an NSNumber");

    [mutex lock];
    
    // return if we have it already
    if ([byIdDict objectForKey:msgId])
    {
        [mutex unlock];
        return;
    }
    
    // add if we don't have yet
    [messages addObject:msg];
    
    // update the byId dictionary
    byIdDict[msgId] = msg;

    // update the byCustId dictionary for non-request related messages
    if (![msg isRequestRelated])
    {
        NSNumber* custId = [msg custId];
        NSAssert([custId isKindOfClass:[NSNumber class]], @"custId in addMessage not an NSNumber");
        NSMutableArray* byCust = byCustDict[custId];
        if (!byCust)
        {
            byCust = [[NSMutableArray alloc] init];
            byCustDict[custId] = byCust;
        }
        [byCust addObject:msg];
    }

    // add the customer
    Customer *cust = [msg customer];
    [customers addCustomer:cust];

    // if request related, add to byReqDict
    if ([msg isRequestRelated]) {
        NSMutableArray* msgsForRequest = byReqDict[[msg reqId]];
        if (!msgsForRequest) {
            msgsForRequest = [[NSMutableArray alloc] init];
            byReqDict[[msg reqId]] = msgsForRequest;
        }
        [msgsForRequest addObject:msg];
    }

    // update the highestSeqCount
    // this should actually always hold
    NSAssert([msg party_seq] > _highestSeqNo, @"Adding an older message");
    if ([msg party_seq] > _highestSeqNo)
        _highestSeqNo = [msg party_seq];

    // check consistency
    NSAssert([messages count] == [byIdDict count], @"number of messages in messages and byIdDict doesn't match");
    NSAssert(![msg seen], @"Newly added message has already been seen");

    [mutex unlock];
}
-(void)removeMessage:(Message*)msg
{
    NSNumber* msgId = [msg msgId];
    NSAssert([msgId isKindOfClass:[NSNumber class]], @"msgId in addMessage not an NSNumber");
 
    [mutex lock];

    NSAssert([messages count] == [byIdDict count], @"number of messages in messages and byIdDict doesn't match");
    
    // return if we don't have it
    if (![byIdDict objectForKey:msgId]) {
        [mutex unlock];
        return;
    }

    // that's the easiest
    [byIdDict removeObjectForKey:msgId];

    if ([msg isRequestRelated]) {
        NSMutableArray* msgsForRequest = byReqDict[[msg reqId]];
        // assert it's not nil
        NSAssert(msgsForRequest, @"msgsForRequest is nil");
        for (NSUInteger i = 0; i < [msgsForRequest count]; i++) {
            if ([[msgsForRequest[i] msgId] isEqual:[msg msgId]]) {
                [msgsForRequest removeObjectAtIndex:i];
                break;
            }
        }
    }
    else
    {
        NSNumber* custId = [msg custId];
        NSMutableArray* msgsForCust = byCustDict[custId];
        NSAssert(msgsForCust, @"msgsForCust is nil");
        for (NSUInteger i = 0; i < [msgsForCust count]; i++) {
            if ([[msgsForCust[i] msgId] isEqual:[msg msgId]]) {
                [msgsForCust removeObjectAtIndex:i];
                break;
            }
        }
    }

    for (NSUInteger i = 0; i < [messages count]; i++) {
        if (messages[i] == msg) {
            [messages removeObjectAtIndex:i];
            break;
        }
    }
    NSAssert([messages count] == [byIdDict count], @"number of messages in messages and byIdDict doesn't match");
    [mutex unlock];
}
-(void)removeMessagesRelatedToRequest:(Request*)req
{
    // need a copy here because the removeMessage function deletes from the very byRequest array and we'd get a modififed-while-enumerated error
    // byRequest has its own lock
    NSArray* msgs = [[self byRequest:req] copy];

    // removeMessage has its own lock
    for (Message* msg in msgs) {
        [self removeMessage:msg];
    }
}
-(Message*)byId:(NSNumber *)msgId
{
    NSAssert([msgId isKindOfClass:[NSNumber class]], @"msgId in byId has no NSNumber id");
    [mutex lock];
    Message* msg = byIdDict[msgId];
    [mutex unlock];
    return msg;
}
-(NSArray*)byCustomer:(Customer*)cust
{
    NSAssert([cust isKindOfClass:[Customer class]], @"cust in byCustomer is no Customer");
    NSNumber* custId = [cust custId];
    
    [mutex lock];
    NSArray* arr = byCustDict[custId];
    [mutex unlock];

    return arr ? arr : [[NSArray alloc] init];
}
-(NSArray*)byRequest:(Request*)req
{
    NSAssert([req isKindOfClass:[Request class]], @"req in byRequest is no Request");
    NSNumber* reqId = [req reqId];
    
    [mutex lock];
    NSArray* arr = byReqDict[reqId];
    [mutex unlock];

    return arr ? arr : [[NSArray alloc] init];
}
-(NSUInteger)countCustomers
{
    [mutex lock];
    NSUInteger c = [byCustDict count];
    [mutex unlock];

    return c;
}
-(Message*)newestFromCustomer:(Customer *)cust
{
    [mutex lock];
    NSArray* all = [byCustDict[[cust custId]] copy];
    [mutex unlock];

    // filter for messages "FROM" customer
    NSPredicate* pred = [NSPredicate predicateWithBlock:
                         ^BOOL(Message* msg, NSDictionary *bindings) {
        return [msg isFromCustomer];
    }];
    NSArray* arr = [all filteredArrayUsingPredicate:pred];

    if ([arr count] == 0)
        return nil;

    if ([arr count] == 1)
        return [arr firstObject];

    // sort by time descending so we have the newest message first
    NSSortDescriptor *dateDesc = [NSSortDescriptor
                                  sortDescriptorWithKey:@"time_sent"
                                  ascending:NO];
    NSArray *sortDescs = [NSArray arrayWithObject:dateDesc];
    NSArray *sarr = [arr sortedArrayUsingDescriptors:sortDescs];
    
    // as the array is always sorted, the newest should be the last one anyway
    NSAssert([sarr firstObject] == [arr lastObject], @"inconsistend order of messages");

    return [sarr firstObject];
}
-(Message*)newestFromOrToCustomer:(Customer *)cust
{
    [mutex lock];
    NSArray* arr = [byCustDict[[cust custId]] copy];
    [mutex unlock];

    if ([arr count] == 0)
        return nil;
    
    if ([arr count] == 1)
        return [arr firstObject];

    // sort by time descending so we have the newest message first
    NSSortDescriptor *dateDesc = [NSSortDescriptor
                                  sortDescriptorWithKey:@"time_sent"
                                  ascending:NO];
    NSArray *sortDescs = [NSArray arrayWithObject:dateDesc];
    NSArray *sarr = [arr sortedArrayUsingDescriptors:sortDescs];

    // as the array is always sorted, the newest should be the last one anyway
    NSAssert([sarr firstObject] == [arr lastObject], @"inconsistend order of messages");

    return [sarr firstObject];
}
-(NSArray*)orderedCustomers
{
    [mutex lock];
    NSArray* custIds = [byCustDict allKeys];
    NSMutableArray* custs = [[NSMutableArray alloc] init];
    for (NSNumber* custId in custIds) {
        Customer *c = [customers byId:custId];
        NSAssert(c, @"Customer not found with id %@", custId);
        [custs addObject:c];
    }
    [mutex unlock];

    NSArray *sortedArray = [custs sortedArrayUsingComparator:^NSComparisonResult(Customer *c1, Customer *c2){
        Message* newestC1 = [self newestFromCustomer:c1];
        Message* newestC2 = [self newestFromCustomer:c2];

        NSAssert(newestC1, @"msg 1 is NULL");
        NSAssert(newestC2, @"msg 2 is NULL");
        
        return [[newestC2 time_sent] compare:[newestC1 time_sent]];
    }];
    
    return sortedArray;
}
-(BOOL)haveSeenAllFromCustomer:(Customer *)cust
{
    [mutex lock];
    NSArray* all = byCustDict[[cust custId]];
    
    // filter for UNSEEN messages FROM this customer that are NOT request-related
    NSPredicate* pred = [NSPredicate predicateWithBlock:
                         ^BOOL(Message* msg, NSDictionary *bindings) {
                             return [msg isFromCustomer] && ![msg isRequestRelated] && ![msg seen];
                         }];
    NSArray* arr = [all filteredArrayUsingPredicate:pred];
    [mutex unlock];

    return [arr count] == 0;
}
-(void)setSeenAllFromCustomer:(Customer *)cust
{
    [mutex lock];
    NSArray* all = byCustDict[[cust custId]];
    
    // filter for UNSEEN messages FROM this customer that are NOT request-related
    NSPredicate* pred = [NSPredicate predicateWithBlock:
                         ^BOOL(Message* msg, NSDictionary *bindings) {
                             return [msg isFromCustomer] && ![msg isRequestRelated] && ![msg seen];
                         }];
    NSArray* arr = [all filteredArrayUsingPredicate:pred];

    for (Message* msg in arr) {
        [msg setSeen:YES];
    }
    [mutex unlock];
}
-(BOOL)haveSeenAllMessagesForRequest:(Request *)req
{
    BOOL seenAll = YES;
    // byRequest has its own lock
    NSArray* msgs = [self byRequest:req];
    for (Message* msg in msgs) {
        if (![msg seen]) {
            seenAll = NO;
            break;
        }
    }
    return seenAll;
}
-(void)setSeenAllMessagesForRequest:(Request *)req
{
    // byRequest has its own lock
    NSArray* msgs = [self byRequest:req];
    for (Message* msg in msgs) {
        [msg setSeen:YES];
    }
}
@end

@implementation CommunicationCenter
{
    CustomerCollection *customers;
    MessageCollection *messages;
    RequestCollection *requests;
}
-(instancetype)init
{
    self = [super init];
    gCommCenter = self;
    [self reset];
    return self;
}
-(void)reset
{
    customers = [[CustomerCollection alloc] init];
    messages = [[MessageCollection alloc] init];
    requests = [[RequestCollection alloc] init];
}
-(void)updateMessages:(NSString*)partyId
{
    if (![partyId isEqualToString:_partyId]) {
        // looks like there was a change in parties
        [self reset];
        _partyId = [partyId copy];
        _highestSeqNo = 0;
    }

    std::string sequencesJSON = gCurlHelper->sequencesJSON([_partyId UTF8String], _highestSeqNo);

    NSError *error = nil;
    NSData* jsonData = [NSData dataWithBytes:sequencesJSON.c_str() length:sequencesJSON.length()];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    NSArray* msgs = jsonDictionary[@"messages"];
    NSArray* reqs = jsonDictionary[@"requests"];
    NSArray* plst = jsonDictionary[@"playlist"];
    
    // XXX they should be sorted already
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"party_seq"  ascending:YES];
    msgs = (NSArray*)[msgs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    reqs = (NSArray*)[reqs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    plst = (NSArray*)[plst sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];

    NSUInteger highestMsgSeqNo = [self parseMessages:msgs];
    _highestSeqNo = MAX(_highestSeqNo, highestMsgSeqNo);

    NSUInteger highestReqSeqNo = [self parseRequests:reqs];
    _highestSeqNo = MAX(_highestSeqNo, highestReqSeqNo);

    [gArtistAndTitleTableViewController addNewVotes:plst];
    NSUInteger highestPlstSeqNo = [[plst lastObject][@"party_seq"]integerValue];
    _highestSeqNo = MAX(_highestSeqNo, highestPlstSeqNo);
}
-(NSUInteger)parseRequests:(NSArray*)all_requests
{
    MessageCollection *msgColl = [gCommCenter messageCollection];
    RequestCollection *reqColl = [gCommCenter requestCollection];

    for (NSDictionary* item in all_requests)
    {
        Request* req = [[Request alloc] initWithDictionary:item andMessageCollection:msgColl];
        [reqColl addRequest:req];
    }
    return [reqColl highestSeqNo];
}
-(NSUInteger)parseMessages:(NSArray*)newMessages
{
    MessageCollection* msgColl = [gCommCenter messageCollection];
    for (NSDictionary* item in newMessages)
    {
        Message *msg = [[Message alloc] initWithDictionary:item];

        // do nothing with the broadcasts
        if ([msg isBroadcast])
            continue;

        [msgColl addMessage:msg];
    }
    //NSLog(@"msgColl has now %ld messages", [msgColl count]);
    return [msgColl highestSeqNo];
}
+(NSDate*)parseTimestamp:(NSString*)timestamp
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ"];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    return [dateFormatter dateFromString: timestamp];
}

+(NSString*)relativeTimestampStringForDate:(NSDate*)date
{
    NSDate* currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit units =  NSCalendarUnitMinute;
    NSDateComponents *components = [calendar components:units
                                               fromDate:date
                                                 toDate:currentDate
                                                options:0];
    return [NSString stringWithFormat:@"%ld minutes ago", (long)[components minute]];
}
-(MessageCollection*)messageCollection
{
    return self->messages;
}
-(RequestCollection*)requestCollection
{
    return self->requests;
}
@end
