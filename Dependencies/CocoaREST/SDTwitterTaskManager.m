//
//  SDTwitterManager.m
//  SDNet
//
//  Created by Steven Degutis on 5/29/09.
//  Copyright 2009 Thoughtful Tree Software. All rights reserved.
//

#import "SDTwitterTaskManager.h"


@implementation SDTwitterTaskManager

@synthesize appName;
@synthesize appVersion;
@synthesize appWebsite;

@synthesize limitMaxAmount;
@synthesize limitRemainingAmount;
@synthesize limitResetEpochDate;

- (void) dealloc {
	[appName release], appName = nil;
	[appVersion release], appVersion = nil;
	[appWebsite release], appWebsite = nil;
	
	[super dealloc];
}

@end
