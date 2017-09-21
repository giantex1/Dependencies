//
//  Created by Brian Ganninger on 1/22/17.
//  Copyright © 2017 Atlassian. All rights reserved.
//

#import "PRGGroupPercentageTransformer.h"

@implementation PRGGroupPercentageTransformer

+ (Class)transformedValueClass
{
	return [NSNumber self];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)beforeObject
{
	NSInteger finalPercentage = 0;
	NSInteger currentPercentage = [beforeObject integerValue];
	
	if (currentPercentage < 0 || currentPercentage > 5)
		finalPercentage = -1;
	
	switch (currentPercentage)
	{
		case 0:
			finalPercentage = 5;
			break;
		case 1:
			finalPercentage = 15;
			break;
		case 2:
			finalPercentage = 25;
			break;
		case 3:
			finalPercentage = 50;
			break;
		case 4:
			finalPercentage = 75;
			break;
		case 5:
			finalPercentage = 100;
			break;
		default:
			break;
	}
	
	return @(finalPercentage);
}

@end
