//
//  SDTwitterEngine.h
//  SDNet
//
//  Created by Steven Degutis on 5/28/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

@import Cocoa;

#import "SDNetTask.h"

@interface SDNetTaskManager : NSObject {
	NSOperationQueue *queue;
	
	id <NSObject> __weak delegate;
	SEL successSelector;
	SEL failSelector;
	
	NSString *username;
	NSString *password;
}

// set these properties

@property (weak) id <NSObject> delegate;

// both of the following selectors need to return (void) and have two
// arguments, SDNetManager and SDNetTask, in that order. for example:

// - (void) twitterManager:(SDTwitterManager*)manager resultsReadyForTask:(SDTwitterTask*)task;
// - (void) twitterManager:(SDTwitterManager*)manager failedForTask:(SDTwitterTask*)task;

@property SEL successSelector;
@property SEL failSelector;

@property (copy) NSString *username;
@property (copy) NSString *password;

@property NSInteger maxConcurrentTasks;

+ (instancetype) manager; // designated convenience initializer
- (instancetype) init; // designated initializer

- (void) runTask:(SDNetTask*)taskToRun;

- (void) cancelAllTasks;
- (void) cancelTask:(SDNetTask*)taskToCancel;

@end
