//
//  Created by Brian Ganninger on 9/30/16.
//  Copyright © 2016 Atlassian. All rights reserved.
//

#import "PRGUpdateHelper.h"
#import "NSString+PRGHashing.h"

NSString* const PRGUpdateGroupDefaultsKey = @"UpdateGroup";
NSString* const PRGUpdateVersionDefaultsKey = @"VersionCheckUpdateGroup";
NSString* const PRGUpdateExemptionDefaultsKey = @"UpdateExemptionsRemaining";

@interface PRGUpdateHelper()
// Redeclare properties readwrite for internal use
@property (readwrite, nullable, nonatomic, copy) NSDate* lastCheckedForUpdates;
@property (readwrite, nullable, nonatomic, copy) NSString* latestAvailableVersion;
@end

@implementation PRGUpdateHelper

- (id)init
{
	self = [super init];
	
	if (self)
		self.canUpdate = YES;
	
	return self;
}

#pragma mark - Helpers -

+ (BOOL)isAlpha
{
	NSString *finalFeedURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUFeedURL"];
	return ([finalFeedURL rangeOfString:@"Alpha.xml"].location != NSNotFound);
}

+ (BOOL)isBeta
{
	NSString *finalFeedURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUFeedURL"];
	return ([finalFeedURL rangeOfString:@"Beta.xml"].location != NSNotFound);
}

#pragma mark - Public API -

+ (void)resetUpdateGrouping
{
	if (![self isAlpha] && ![self isBeta])
	{
		BOOL shouldResetGrouping = NO;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *priorVersion = [defaults stringForKey:PRGUpdateVersionDefaultsKey];
		NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
		
		if (![defaults objectForKey:PRGUpdateGroupDefaultsKey] || !priorVersion)
		{
			shouldResetGrouping = YES;
		}
		else if (![priorVersion isEqualToString:bundleVersion])
		{
			if (![defaults objectForKey:PRGUpdateExemptionDefaultsKey])
			{
				shouldResetGrouping = YES;
			}
			else
			{
				NSInteger currentValue = [defaults integerForKey:PRGUpdateExemptionDefaultsKey];
				
				if (currentValue == 1)
					shouldResetGrouping = YES;
				else
				{
					[defaults setInteger:1 forKey:PRGUpdateExemptionDefaultsKey];
					[defaults setObject:bundleVersion forKey:PRGUpdateVersionDefaultsKey];
				}
			}
		}
		
		if (shouldResetGrouping)
		{
			NSUInteger groupNum = [self groupForUUID:[NSUUID UUID]];
			[defaults setInteger:groupNum forKey:PRGUpdateGroupDefaultsKey];
			[defaults setObject:bundleVersion forKey:PRGUpdateVersionDefaultsKey];
			[defaults setInteger:2 forKey:PRGUpdateExemptionDefaultsKey];
		}
	}
}

+ (NSUInteger)groupForUUID:(NSUUID *)uuid
{
	NSString* fullSHA = [[uuid UUIDString] prg_SHA1Hash];
	NSUInteger finalGroup = 5;
	
	if (fullSHA.length >= 40)
	{
		NSString* last8 = [fullSHA substringWithRange:NSMakeRange(32, 8)];
		
		// Last 8 characters == 32-bit, digest is base 16
		unsigned long num = strtoul((const char*)[last8 UTF8String], NULL, 16);
		unsigned long percent = num % 100;
		
		if (percent <= 5)
			finalGroup = 0;
		else if (percent <= 15)
			finalGroup = 1;
		else if (percent <= 25)
			finalGroup = 2;
		else if (percent <= 50)
			finalGroup = 3;
		else if (percent <= 75)
			finalGroup = 4;
	}
	
	return finalGroup;
}

- (NSString *)feedURLForGroup:(NSInteger)groupNum
{
	NSString *finalFeedURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUFeedURL"];
	NSString *appcastSlug = @"Appcast.xml";
	
	if (![[self class] isAlpha] && ![[self class] isBeta])
	{
		switch (groupNum)
		{
			case 0:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup0.xml"];
				break;
			case 1:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup1.xml"];
				break;
			case 2:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup2.xml"];
				break;
			case 3:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup3.xml"];
				break;
			case 4:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup4.xml"];
				break;
			case 5:
				finalFeedURL = [finalFeedURL stringByReplacingOccurrencesOfString:appcastSlug withString:@"AppcastGroup5.xml"];
				break;
			default:
				// do nothing, stick with original URL
				break;
		}
	}
	
	return finalFeedURL;
}

- (SUUpdater *)newSparkleUpdater
{
	SUUpdater *updater = [[SUUpdater alloc] init];
	updater.delegate = self;
	return updater;
}

+ (NSInteger)currentUpdateGroup
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:PRGUpdateGroupDefaultsKey];
}

#pragma mark - Sparkle Delegate -

- (NSString *)feedURLStringForUpdater:(SUUpdater *)updater
{
	NSInteger feedGroup = [[self class] currentUpdateGroup];
	return [self feedURLForGroup:feedGroup];
}

- (BOOL)updaterMayCheckForUpdates:(SUUpdater *)updater
{
	return self.canUpdate;
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)item
{
	self.lastCheckedForUpdates = [NSDate date];
	self.latestAvailableVersion = item.displayVersionString;
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)updater
{
	_lastCheckedForUpdates = [NSDate date];
	_latestAvailableVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end
