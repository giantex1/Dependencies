//
//  SDFriendfeedTask.m
//  SDNet
//
//  Created by Steven Degutis on 6/2/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

#import "SDFriendfeedTask.h"

#import "SDFriendfeedTaskManager.h"

#import "SDNetTask+Subclassing.h"

@implementation SDFriendfeedTask

@synthesize username;

- (BOOL) validateType {
	return (type > SDFriendfeedTaskDoNothing && type < SDFriendfeedTaskMAX);
}

- (BOOL) shouldUseBasicHTTPAuthentication {
	return YES;
}

- (void) setUniqueApplicationIdentifiersForRequest:(NSMutableURLRequest*)request {
}

- (void) handleHTTPResponse:(NSHTTPURLResponse*)response {
}

- (SDParseFormat) parseFormatBasedOnTaskType {
	return SDParseFormatNone;
}

- (BOOL) isMultiPartDataBasedOnTaskType {
	return NO;
}

- (SDHTTPMethod) methodBasedOnTaskType {
	return SDHTTPMethodGet;
}

- (NSString*) URLStringBasedOnTaskType {
	NSString *URLStrings[SDFriendfeedTaskMAX]; // is this a bad convention? no seriously, i dont know...
	
	URLStrings[SDFriendfeedTaskGetPublicTimeline] = @"http://friendfeed.com/api/feed/home";
	URLStrings[SDFriendfeedTaskGetUserPicture] = [NSString stringWithFormat:@"http://friendfeed.com/%@/picture", self.username];
	
	return URLStrings[type];
}

- (void) addParametersToDictionary:(NSMutableDictionary*)parameters {
	if (type == SDFriendfeedTaskGetUserPicture) {
		[parameters setObject:@"medium" forKey:@"size"];
	}
}

@end
