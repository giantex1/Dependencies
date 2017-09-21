//
//  SDNetTask+Subclassing.h
//  SDNet
//
//  Created by Steven Degutis on 5/29/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

@import Cocoa;

#import "SDNetTask.h"

#import "NSString+UUID.h"
#import "NSColor+Hex.h"

// the rationale for not putting much of this info into SDNetTask.h is that it's not
// particularly useful or relevant to users of this library, only for subclassers.

// similarly, the top half of the category might have been a protocol, but that would require
// a separate object to be involved. plus, SDNetTask would have to be concrete,
// which complicates the fact that *Task & *Manager are a pair of subclassable classes.

typedef enum _SDHTTPMethod {
	SDHTTPMethodGet,
	SDHTTPMethodPost
} SDHTTPMethod;

typedef enum _SDParseFormat {
	SDParseFormatNone,
	SDParseFormatJSON,
	SDParseFormatXML,
	SDParseFormatImage,
} SDParseFormat;

@interface SDNetTask (Subclassing)

// NOTE: the following MUST be overridden by subclasses; superclass does NOT implement these
// (ok well it really does, but let's pretend it doesn't)

- (id) copyWithZone:(NSZone*)zone;
- (BOOL) validateType;
- (BOOL) shouldUseBasicHTTPAuthentication;
- (void) setUniqueApplicationIdentifiersForRequest:(NSMutableURLRequest*)request;
- (void) handleHTTPResponse:(NSHTTPURLResponse*)response;

- (BOOL) isMultiPartDataBasedOnTaskType;
- (SDHTTPMethod) methodBasedOnTaskType;
- (NSString*) URLStringBasedOnTaskType;
- (SDParseFormat) parseFormatBasedOnTaskType;
- (void) addParametersToDictionary:(NSMutableDictionary*)parameters;

// the following methods are implemented in the superclass, which just sends the proper
// selector to the delegate. subclasses may override either of these methods to perform
// their own specific delegate-notifying implementations, or can call super's impl. in
// order to provide custom logic for when or how to send these notifications to delegates
// (see the Facebook subclasses for an example of this custom logic).
- (void) sendResultsToDelegate;
- (void) sendErrorToDelegate;

// MISC: general helper methods, courtesy of the superclass

- (NSString*) encodeString:(NSString*)string;
- (NSString*) queryStringFromDictionary:(NSDictionary*)queryUnits;
- (NSData*) postBodyDataFromDictionary:(NSDictionary*)dictionary;
+ (NSString*) stringBoundary;
- (NSString*) errorString;

@end
