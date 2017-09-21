//
//  Created by Brian Ganninger on 11/25/16.
//  Copyright © 2016 Atlassian. All rights reserved.
//

#import "NSString+PRGHashing.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (PRGHashing)

- (NSString *)prg_SHA1Hash
{
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
	
	// Need to convert the digest (binary) into a hex string
	NSMutableString *ret = [NSMutableString string];
	if (CC_SHA1([d bytes], (unsigned int)[d length], digest))
	{
		for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		{
			[ret appendFormat:@"%02x", digest[i]];
		}
	}
	
	return [NSString stringWithString:ret]; // return an immutable object
}

@end
