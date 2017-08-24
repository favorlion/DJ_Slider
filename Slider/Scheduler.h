//
//  Scheduler.h
//  Slider
//
//  Created by Joachim Wieland on 6/10/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#ifndef Scheduler_h
#define Scheduler_h

@interface Scheduler : NSObject
@property (readonly) dispatch_queue_t serialAudioAnalysisQueue;
@property (readonly) dispatch_queue_t serialWebRequestQueue;
@end

extern Scheduler* gScheduler;

#endif /* Scheduler_h */
