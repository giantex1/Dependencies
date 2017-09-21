//
//  SDIdenticaTask.m
//  SDNet
//
//  Created by Steven Degutis on 5/29/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

#import "SDIdenticaTask.h"

#import "SDIdenticaTaskManager.h"

#import "SDNetTask+Subclassing.h"

@implementation SDIdenticaTask

- (BOOL) validateType {
	return (type > SDIdenticaTaskDoNothing && type < SDIdenticaTaskMAX);
}

- (BOOL) shouldUseBasicHTTPAuthentication {
	return NO;
}

- (void) setUniqueApplicationIdentifiersForRequest:(NSMutableURLRequest*)request {
}

- (void) handleHTTPResponse:(NSHTTPURLResponse*)response {
}

- (BOOL) isMultiPartDataBasedOnTaskType {
	return NO;
}

- (SDHTTPMethod) methodBasedOnTaskType {
	return SDHTTPMethodGet;
}

- (NSString*) URLStringBasedOnTaskType {
	NSString *URLStrings[SDIdenticaTaskMAX]; // is this a bad convention? no seriously, i dont know...
	
	URLStrings[SDIdenticaTaskGetPublicTimeline] = @"http://identi.ca/api/statuses/public_timeline.json";
	
	return URLStrings[type];
}

- (void) addParametersToDictionary:(NSMutableDictionary*)parameters {
}

@end
