//
//  SSToolbarItem.h
//  SelectableToolbarHelper
//
//  Created by Steven Streeting on 19/06/2011.
//  Copyright 2011 Atlassian. All rights reserved.
//

@import Cocoa;


@interface SSSelectableToolbarItem : NSToolbarItem 
{
	NSView* linkedView;
}

@property (nonatomic, strong) IBOutlet NSView* linkedView;

@end
