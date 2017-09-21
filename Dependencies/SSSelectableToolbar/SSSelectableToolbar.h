//
//  SSToolbar.h
//  SelectableToolbarHelper
//
//  Created by Steven Streeting on 19/06/2011.
//  Copyright 2011 Atlassian. All rights reserved.
//

@import Cocoa;

#define SSST_SELECTION_CHANGED_NOTIFICATION @"ToolbarItemSelected"

@interface SSSelectableToolbar : NSToolbar 
{
    // Need to use __unsafe_unretained as can't use __weak on NSWindow in 10.7
	__unsafe_unretained NSWindow* window;
	NSView* blankView;
	NSInteger defaultItemIndex;
}

@property (nullable, nonatomic, assign) IBOutlet NSWindow* window;
@property (nonatomic, assign) NSInteger defaultItemIndex;

- (nullable NSToolbarItem*)itemWithIdentifier:(nonnull NSString*)identifier;

// select the item with the given index, ordered as per the palette and ignoring 
// all types of buttons except SSSelectableToolbarItem
- (void)selectItemWithIndex:(NSInteger)idx;

// Convert a selectable item index (ignoring all except selectable items in palette)
// to a main index which can be used for other purposes
- (NSInteger)selectableItemIndexToMainIndex:(NSInteger)idx;

- (NSUInteger)indexOfSelectedItem;

@end
