//
//  Configuration.h
//  Slider
//
//  Created by Joachim Wieland on 6/10/16.
//  Copyright © 2016 JoJo Systems. All rights reserved.
//

#ifndef Configuration_h
#define Configuration_h

@interface Configuration : NSObject 
@property NSArray* bpmRange; // the selected bpm range
@end

extern Configuration *gConfiguration;

#endif /* Configuration_h */
