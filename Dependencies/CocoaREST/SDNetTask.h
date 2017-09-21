//
//  SDTwitterFetchTask.h
//  SDNet
//
//  Created by Steven Degutis on 5/28/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

@import Cocoa;

@class SDNetTaskManager;

typedef enum _SDNetTaskError {
	SDNetTaskErrorNone,
	SDNetTaskErrorInvalidType,
	SDNetTaskErrorManagerNotSet,
	SDNetTaskErrorConnectionDataIsNil,
	SDNetTaskErrorConnectionFailed,
	SDNetTaskErrorParserFailed,
	SDNetTaskErrorParserDataIsNil,
	SDNetTaskErrorServiceDefinedError,
	
	SDNetTaskErrorMAX // once again, don't touch.
} SDNetTaskError;

@interface SDNetTask : NSOperation <NSCopying> {
	SDNetTaskManager *manager;
	
	int type;
	void* context;
	
	NSString *taskID;
	id results;
	
	SDNetTaskError errorCode;
	NSError *error;
	NSError *underlyingError;
}

// designated convenience initializer

+ (instancetype) taskWithManager:(SDNetTaskManager*)newManager;
- (instancetype) initWithManager:(SDNetTaskManager*)newManager;

// Run asynchronously & receive results via delegate
- (void) run;
// Run synchronously and optionally skip delegate calling
- (void)runSynchronously:(BOOL)sendResponseToDelegate;
- (void) cancel;

-(void)processConnectionError:(NSError*)err;

// readable properties: use after task is complete

@property int type;

@property void* context;

@property (strong, readonly) id results;

@property (readonly) SDNetTaskError errorCode;
@property (readonly) NSError *error;

@property (readonly) NSString *taskID; // DEPRECATED; do not use unless you REALLY want to.

@property (readonly) SDNetTaskManager* manager;

@end
