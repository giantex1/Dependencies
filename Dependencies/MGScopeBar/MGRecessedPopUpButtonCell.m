//
//  MGRecessedPopUpButtonCell.m
//  MGScopeBar
//
//  Created by Matt Gemmell on 20/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGRecessedPopUpButtonCell.h"

@implementation MGRecessedPopUpButtonCell

- (instancetype)initTextCell:(NSString *)title pullsDown:(BOOL)pullsDown
{
	if ((self = [super initTextCell:title pullsDown:pullsDown]))
	{
		recessedButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 30, 20)]; // arbitrary frame.
		recessedButton.title = @"";
		recessedButton.bezelStyle = NSBezelStyleRounded;
		[recessedButton setButtonType:NSButtonTypeMomentaryPushIn];
		[recessedButton setShowsBorderOnlyWhileMouseInside:NO];
		recessedButton.bordered = NO;
	}
	
	return self;
}

@end
