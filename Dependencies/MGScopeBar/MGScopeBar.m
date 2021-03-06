//
//  MGScopeBar.m
//  MGScopeBar
//
//  Created by Matt Gemmell on 15/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGScopeBar.h"
#import "MGRecessedPopUpButtonCell.h"


#define SCOPE_BAR_H_INSET				8.0																		// inset on left and right
#define SCOPE_BAR_HEIGHT				25.0																	// used in -sizeToFit
#define SCOPE_BAR_START_COLOR_GRAY		[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]						// bottom color of gray gradient
#define SCOPE_BAR_END_COLOR_GRAY		[NSColor colorWithCalibratedWhite:0.90 alpha:1.0]						// top color of gray gradient
#define SCOPE_BAR_START_COLOR_BLUE		[NSColor colorWithCalibratedRed:0.71 green:0.75 blue:0.81 alpha:1.0]	// bottom color of blue gradient
#define SCOPE_BAR_END_COLOR_BLUE		[NSColor colorWithCalibratedRed:0.80 green:0.82 blue:0.87 alpha:1.0]	// top color of blue gradient
#define SCOPE_BAR_BORDER_COLOR			[NSColor colorWithCalibratedWhite:0.69 alpha:1.0]						// bottom line's color
#define SCOPE_BAR_BORDER_WIDTH			1.0																		// bottom line's width

#define SCOPE_BAR_SEPARATOR_COLOR		[NSColor colorWithCalibratedWhite:0.52 alpha:1.0]	// color of vertical-line separators between groups
#define SCOPE_BAR_SEPARATOR_WIDTH		1.0													// width of vertical-line separators between groups
#define SCOPE_BAR_SEPARATOR_HEIGHT		16.0												// separators are vertically centered in the bar

#define SCOPE_BAR_LABEL_COLOR			[NSColor colorWithCalibratedWhite:0.45 alpha:1.0]	// color of groups' labels
#define SCOPE_BAR_FONTSIZE				11.0												// font-size of labels and buttons
#define SCOPE_BAR_ITEM_SPACING			6.0													// spacing between buttons/separators/labels
#define SCOPE_BAR_BUTTON_IMAGE_SIZE		16.0												// size of buttons' images (width and height)

#define SCOPE_BAR_HIDE_POPUP_BG			YES	// whether the bezel background of an NSPopUpButton is hidden when none of its menu-items are selected.

// Appearance metrics. These were chosen to mimic the Finder's "Find" (Spotlight / Smart Group / etc) window's scope-bar.
#define MENU_PADDING					25.0					// how much wider a popup-button is than a regular button with the same title.
#define MENU_MIN_WIDTH					60.0					// minimum width a popup-button can be narrowed to.

// NSPopUpButton titles used for groups which allow multiple selection.
#define POPUP_TITLE_EMPTY_SELECTION		NSLocalizedString(@"(None)", nil)		// title used when no items in the popup are selected.
#define POPUP_TITLE_MULTIPLE_SELECTION	NSLocalizedString(@"(Multiple)", nil)	// title used when multiple items in the popup are selected.


// ---- end of configurable settings ---- //


// Keys for internal use.
#define GROUP_IDENTIFIERS				@"Identifiers"			// NSMutableArray of identifier strings.
#define GROUP_BUTTONS					@"Buttons"				// NSMutableArray of either NSButtons or NSMenuItems, one per item.
#define GROUP_SELECTION_MODE			@"SelectionMode"		// MGScopeBarGroupSelectionMode (int) as NSNumber.
#define GROUP_MENU_MODE					@"MenuMode"				// BOOL, YES if group is collected in a popup-menu, else NO.
#define GROUP_POPUP_BUTTON				@"PopupButton"			// NSPopUpButton (only present if group is in menu-mode).
#define GROUP_TITLE                     @"GroupTitle"           // Instead of the default group title (POPUP_TITLE_EMPTY_SELECTION) you can specify your own using this key
#define GROUP_HAS_SEPARATOR				@"HasSeparator"			// BOOL, YES if group has a separator before it.
#define GROUP_HAS_LABEL					@"HasLabel"				// BOOL, YES if group has a label.
#define GROUP_LABEL_FIELD				@"LabelField"			// NSTextField for the label (optional; only if group has a label)
#define GROUP_TOTAL_BUTTONS_WIDTH		@"TotalButtonsWidth"	// Width of all buttons in a group plus spacings between them (doesn't include label etc)
#define GROUP_WIDEST_BUTTON_WIDTH		@"WidestButtonWidth"	// Width of widest button, used when making popup-menus.
#define GROUP_CUMULATIVE_WIDTH			@"CumulativeWidth"		// Width from left of leftmost group to right of this group (all groups fully expanded).


@interface MGScopeBar (MGPrivateMethods)

- (IBAction)scopeButtonClicked:(id)sender;
- (NSButton *)getButtonForItem:(NSString *)identifier inGroup:(int)groupNumber; // returns relevant button/menu-item
- (void)updateSelectedState:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber informDelegate:(BOOL)inform;
- (NSButton *)buttonForItem:(NSString *)identifier inGroup:(int)groupNumber 
				  withTitle:(NSString *)title image:(NSImage *)image; // creates a new NSButton
- (NSMenuItem *)menuItemForItem:(NSString *)identifier inGroup:(int)groupNumber 
					  withTitle:(NSString *)title image:(NSImage *)image; // creates a new NSMenuitem
- (NSPopUpButton *)popupButtonForGroup:(NSDictionary *)group;
- (void)setControl:(NSObject *)control forIdentifier:(NSString *)identifier inGroup:(int)groupNumber;
- (void)updateMenuTitleForGroupAtIndex:(int)groupNumber;

@end


@implementation MGScopeBar


#pragma mark Setup and teardown


- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _smartResizeEnabled = YES;
		_notifyDefaultSelections = YES;
		// Everything else is reset in -reloadData.
    }
    return self;
}


- (void)dealloc
{
	delegate = nil;
	if (_accessoryView) {
		[_accessoryView removeFromSuperview];
		_accessoryView = nil; // weak ref
	}
	
}


#pragma mark Data management


- (void)reloadData
{
	// Resize if necessary.
	[self sizeToFit];
	
	// Remove any old objects.
	if (_accessoryView) {
		[_accessoryView removeFromSuperview];
		_accessoryView = nil; // weak ref
	}
	
	NSArray *subviews = [self.subviews copy]; // so we don't mutate the collection we're iterating over.
	[subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	 // because copies are retained.
	
	_separatorPositions = nil;
	_groups = nil;
	_identifiers = nil;
	_selectedItems = nil;
	_firstCollapsedGroup = NSNotFound;
	_lastWidth = NSNotFound;
	_totalGroupsWidth = 0;
	_totalGroupsWidthForPopups = 0;
	
	// Configure contents via delegate.
	if (self.delegate && [delegate conformsToProtocol:@protocol(MGScopeBarDelegate)]) {
		int numGroups = [delegate numberOfGroupsInScopeBar:self];
		
		if (numGroups > 0) {
			_separatorPositions = [[NSMutableArray alloc] initWithCapacity:numGroups];
			_groups = [[NSMutableArray alloc] initWithCapacity:numGroups];
			_identifiers = [[NSMutableDictionary alloc] initWithCapacity:0];
			_selectedItems = [[NSMutableArray alloc] initWithCapacity:numGroups];
			
			int xCoord = SCOPE_BAR_H_INSET;
			NSRect ctrlRect = NSZeroRect;
			BOOL providesImages = [delegate respondsToSelector:@selector(scopeBar:imageForItem:inGroup:)];
			
			for (int groupNum = 0; groupNum < numGroups; groupNum++) {
				// Add separator if appropriate.
				BOOL addSeparator = (groupNum > 0); // default behavior.
				if ([delegate respondsToSelector:@selector(scopeBar:showSeparatorBeforeGroup:)]) {
					addSeparator = [delegate scopeBar:self showSeparatorBeforeGroup:groupNum];
				}
				if (addSeparator) {
					[_separatorPositions addObject:@(xCoord)];
					xCoord += SCOPE_BAR_SEPARATOR_WIDTH + SCOPE_BAR_ITEM_SPACING;
					
					_totalGroupsWidth += SCOPE_BAR_SEPARATOR_WIDTH + SCOPE_BAR_ITEM_SPACING;
					_totalGroupsWidthForPopups += SCOPE_BAR_SEPARATOR_WIDTH + SCOPE_BAR_ITEM_SPACING;
				} else {
					[_separatorPositions addObject:[NSNull null]];
				}
				
				// Add label if appropriate.
				NSString *groupLabel = [delegate scopeBar:self labelForGroup:groupNum];
				NSTextField *labelField = nil;
				BOOL hasLabel = NO;
				if (groupLabel && groupLabel.length > 0) {
					hasLabel = YES;
					ctrlRect = NSMakeRect(xCoord, 6, 15, 50);
					labelField = [[NSTextField alloc] initWithFrame:ctrlRect];
					labelField.stringValue = groupLabel;
					[labelField setEditable:NO];
					[labelField setBordered:NO];
					[labelField setDrawsBackground:NO];
					[labelField setTextColor:SCOPE_BAR_LABEL_COLOR];
					labelField.font = [NSFont systemFontOfSize:SCOPE_BAR_FONTSIZE];
					[labelField sizeToFit];
					ctrlRect.size = labelField.frame.size;
					labelField.frame = ctrlRect;
					[self addSubview:labelField];
					
					xCoord += ctrlRect.size.width + SCOPE_BAR_ITEM_SPACING;
					
					_totalGroupsWidth += ctrlRect.size.width + SCOPE_BAR_ITEM_SPACING;
					_totalGroupsWidthForPopups += ctrlRect.size.width + SCOPE_BAR_ITEM_SPACING;
				}
                
                NSString *groupTitle = [delegate scopeBar:self titleForGroup:groupNum];
                BOOL hasGroupTitle = NO;
                if(groupTitle && groupTitle.length > 0)
                {
                    hasGroupTitle = YES;
                }
                
				
				// Create group information for use during interaction.
				NSArray *identifiers = [delegate scopeBar:self itemIdentifiersForGroup:groupNum];
				NSMutableArray *usedIdentifiers = [NSMutableArray arrayWithCapacity:identifiers.count];
				NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:identifiers.count];
				MGScopeBarGroupSelectionMode selMode = [delegate scopeBar:self selectionModeForGroup:groupNum];
				if (selMode != MGRadioSelectionMode && selMode != MGMultipleSelectionMode) {
					// Sanity check, since this is just an int.
					selMode = MGRadioSelectionMode;
				}
				NSMutableDictionary *groupInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												  usedIdentifiers, GROUP_IDENTIFIERS, 
												  buttons, GROUP_BUTTONS, 
												  @(selMode), GROUP_SELECTION_MODE,
												  @(NO), GROUP_MENU_MODE, 
												  @(hasLabel), GROUP_HAS_LABEL,
												  @(addSeparator), GROUP_HAS_SEPARATOR,
												  nil];
				if (hasLabel) {
					groupInfo[GROUP_LABEL_FIELD] = labelField;
				}
                if(hasGroupTitle) {
                    groupInfo[GROUP_TITLE] = groupTitle;
                }
				[_groups addObject:groupInfo];
				[_selectedItems addObject:[NSMutableArray arrayWithCapacity:0]];
				
				// Add buttons for this group.
				float widestButtonWidth = 0;
				float totalButtonsWidth = 0;
				for (NSString *itemID in identifiers) {
					if (![usedIdentifiers containsObject:itemID]) {
						[usedIdentifiers addObject:itemID];
					} else {
						// Identifier already used for this group; skip it.
						continue;
					}
					
					NSString *title = [delegate scopeBar:self titleOfItem:itemID inGroup:groupNum];
					NSImage *image = nil;
					if (providesImages) {
						image = [delegate scopeBar:self imageForItem:itemID inGroup:groupNum];
					}
					NSButton *button = [self buttonForItem:itemID inGroup:groupNum withTitle:title image:image];
					
					ctrlRect = button.frame;
					ctrlRect.origin.x = xCoord;
					button.frame = ctrlRect;
					[self addSubview:button];
					[buttons addObject:button];
					
					// Adjust x-coordinate for next item in the bar.
					xCoord += ctrlRect.size.width + SCOPE_BAR_ITEM_SPACING;
					
					// Update total and widest button widths.
					if (totalButtonsWidth > 0) {
						// Add spacing before this item, since it's not the first in the group.
						totalButtonsWidth += SCOPE_BAR_ITEM_SPACING;
					}
					totalButtonsWidth += ctrlRect.size.width;
					if (ctrlRect.size.width > widestButtonWidth) {
						widestButtonWidth = ctrlRect.size.width;
					}
				}
				
				// Add the accumulated buttons' width and the widest button's width to groupInfo.
				groupInfo[GROUP_TOTAL_BUTTONS_WIDTH] = @(totalButtonsWidth);
				groupInfo[GROUP_WIDEST_BUTTON_WIDTH] = @(widestButtonWidth);
				
				_totalGroupsWidth += totalButtonsWidth;
				_totalGroupsWidthForPopups += widestButtonWidth + MENU_PADDING;
				
				float cumulativeWidth = _totalGroupsWidth + (groupNum * SCOPE_BAR_ITEM_SPACING);
				groupInfo[GROUP_CUMULATIVE_WIDTH] = @(cumulativeWidth);
				
				// If this is a radio-mode group, select the first item automatically.
				if (selMode == MGRadioSelectionMode) {
					[self updateSelectedState:YES forItem:identifiers[0] inGroup:groupNum informDelegate:_notifyDefaultSelections];
				}
			}
			
			_totalGroupsWidth += ((numGroups - 1) * SCOPE_BAR_ITEM_SPACING);
			_totalGroupsWidthForPopups += ((numGroups - 1) * SCOPE_BAR_ITEM_SPACING);
		}
		
		// Add accessoryView, if provided.
		if ([delegate respondsToSelector:@selector(accessoryViewForScopeBar:)]) {
			_accessoryView = [delegate accessoryViewForScopeBar:self];
			if (_accessoryView) {
				// Remove NSViewMaxXMargin flag from resizing mask, if present.
				NSUInteger mask = _accessoryView.autoresizingMask;
				if (mask & NSViewMaxXMargin) {
					mask &= ~NSViewMaxXMargin;
				}
				
				// Add NSViewMinXMargin flag to resizing mask, if not present.
				if (!(mask & NSViewMinXMargin)) {
					mask = (mask | NSViewMinXMargin);
				}
				
				// Update view sizing mask.
				_accessoryView.autoresizingMask = mask;
				
				// Adjust frame appropriately.
				NSRect frame = _accessoryView.frame;
				frame.origin.x = round(NSMaxX(self.bounds) - (frame.size.width + SCOPE_BAR_H_INSET));
				frame.origin.y = round(((SCOPE_BAR_HEIGHT - frame.size.height) / 2.0));
				_accessoryView.frame = frame;
				
				// Add as subview.
				[self addSubview:_accessoryView];
			}
		}
		
		// Layout subviews appropriately.
		[self adjustSubviews];
	}
	
	[self setNeedsDisplay:YES];
}


#pragma mark Utility methods


- (void)sizeToFit
{
	NSRect frame = self.frame;
	if (frame.size.height != SCOPE_BAR_HEIGHT) {
		float delta = SCOPE_BAR_HEIGHT - frame.size.height;
		frame.size.height += delta;
		frame.origin.y -= delta;
		self.frame = frame;
	}
}


- (void)adjustSubviews
{
	
	/*
	 We need to work out which groups we can show fully expanded, and which must be collapsed into popup-buttons.
	 Any kind of frame-change may have happened, so we need to take care to create or remove buttons or popup-buttons as needed.
	*/
	
	// Bail out if we have nothing to do.
	if (!_groups || _groups.count == 0) {
		return;
	}
	
	// Obtain current width of view.
	float viewWidth = self.bounds.size.width;
    
    // Force all groups to be collapsed
    if (!_smartResizeEnabled && viewWidth > _totalGroupsWidthForPopups)
        viewWidth = _totalGroupsWidthForPopups;
	
	// Abort if there hasn't been any genuine change in width.
	if ((viewWidth == _lastWidth) && (_lastWidth != NSNotFound)) {
		return;
	}
	
	// Determine whether we got narrower or wider.
	float narrower = ((_lastWidth == NSNotFound) || (viewWidth < _lastWidth));
	
	// Find width available for showing groups.
	float availableWidth = viewWidth - (SCOPE_BAR_H_INSET * 2.0);
	if (_accessoryView) {
		// Account for _accessoryView, leaving a normal amount of spacing to the left of it.
		availableWidth -= (_accessoryView.frame.size.width + SCOPE_BAR_ITEM_SPACING);
	}
	
	// Will need to adjust popup size if we've compressed them, or used to compress them
	BOOL shouldAdjustPopups = (availableWidth < _totalGroupsWidthForPopups) || _popupsShrunk;
	NSInteger oldFirstCollapsedGroup = _firstCollapsedGroup;
	
	// Work out which groups we should now check for collapsibility/expandability.
	NSEnumerator *groupsEnumerator = nil;
	NSRange enumRange;
	BOOL proceed = YES;
	
	if (narrower) {
		// Got narrower, so work backwards from oldFirstCollapsedGroup (excluding that group, since it's already collapsed),
		// checking to see if we need to collapse any more groups to the left.
		enumRange = NSMakeRange(0, oldFirstCollapsedGroup);
		// If no groups were previously collapsed, work backwards from the last group (including that group).
		if (oldFirstCollapsedGroup == NSNotFound) {
			enumRange.length = _groups.count;
		}
		groupsEnumerator = [[_groups subarrayWithRange:enumRange] reverseObjectEnumerator];
		
	} else {
		// Got wider, so work forwards from oldFirstCollapsedGroup (including that group) checking to see if we can 
		// expand any groups into full buttons.
		enumRange = NSMakeRange(oldFirstCollapsedGroup, _groups.count - oldFirstCollapsedGroup);
		// If no groups were previously collapsed, we have nothing to do here.
		if (oldFirstCollapsedGroup == NSNotFound) {
			proceed = NO;
		}
		if (proceed) {
			groupsEnumerator = [[_groups subarrayWithRange:enumRange] objectEnumerator];
		}
	}
	
	// Get the current occupied width within this view.
	float currentOccupiedWidth = 0;
	NSDictionary *group = _groups[0];
	BOOL menuMode = [group[GROUP_MENU_MODE] boolValue];
	NSButton *firstButton = nil;
	if (menuMode) {
		firstButton = group[GROUP_POPUP_BUTTON];
	} else {
		firstButton = group[GROUP_BUTTONS][0];
	}
	float leftLimit = NSMinX(firstButton.frame);
	// Account for label in first group, if present.
	if ([group[GROUP_HAS_LABEL] boolValue]) {
		NSTextField *label = (NSTextField *)group[GROUP_LABEL_FIELD];
		leftLimit -= (SCOPE_BAR_ITEM_SPACING + label.frame.size.width);
	}
	
	group = _groups.lastObject;
	menuMode = [group[GROUP_MENU_MODE] boolValue];
	NSButton *lastButton = nil;
	if (menuMode) {
		lastButton = group[GROUP_POPUP_BUTTON];
	} else {
		lastButton = [group[GROUP_BUTTONS] lastObject];
	}
	float rightLimit = NSMaxX(lastButton.frame);
	currentOccupiedWidth = rightLimit - leftLimit;
	
	// Work out whether we need to try collapsing groups at all, if we're narrowing.
	// We have already handled the case of not requiring to expand groups if we're widening, above.
	if (proceed && narrower) {
		if (availableWidth >= currentOccupiedWidth) {
			// We still have enough room for what we're showing; no change needed.
			proceed = NO;
		}
	}
	
	if (proceed) {
		// Disable screen updates.
		NSDisableScreenUpdates();
		
		// See how many further groups we can expand or contract.
		float theoreticalOccupiedWidth = currentOccupiedWidth;
		for (NSDictionary *groupInfo in groupsEnumerator) {
			BOOL complete = NO;
			float expandedWidth = [groupInfo[GROUP_TOTAL_BUTTONS_WIDTH] floatValue];
			float contractedWidth = [groupInfo[GROUP_WIDEST_BUTTON_WIDTH] floatValue] + MENU_PADDING;
			
			if (narrower) {
				// We're narrowing. See if collapsing this group brings us within availableWidth.
				if (((theoreticalOccupiedWidth - expandedWidth) + contractedWidth) <= availableWidth) {
					// We're now within width constraints, so we're done iterating.
					complete = YES;
				} // else, continue trying to to collapse groups.
				theoreticalOccupiedWidth = ((theoreticalOccupiedWidth - expandedWidth) + contractedWidth);
				
			} else {
				// We're widening. See if we can expand this group and still be within availableWidth.
				// We need the *current* width to subtract in calc, not the widest popup could be
				if ([groupInfo[GROUP_MENU_MODE] boolValue])
				{
					float currentWidth = NSWidth([groupInfo[GROUP_POPUP_BUTTON] frame]);					
					
					if (((theoreticalOccupiedWidth - currentWidth) + expandedWidth) > availableWidth) {
						// We'd be too wide if we expanded this group. Terminate iteration without updating _firstCollapsedGroup.
						break;
					} // else, continue trying to expand groups.
					theoreticalOccupiedWidth = ((theoreticalOccupiedWidth - currentWidth) + expandedWidth);
				}
			}
			
			// Update _firstCollapsedGroup appropriately.
			if (_firstCollapsedGroup == NSNotFound) {
				_firstCollapsedGroup = ((narrower) ? _groups.count : -1);
				oldFirstCollapsedGroup = _firstCollapsedGroup;
			}
			_firstCollapsedGroup += ((narrower) ? -1 : 1);
			
			// Terminate if we now fit the available space as best we can.
			if (complete) {
				break;
			}
		}
		
		// Work out how many groups we need to actually change.
		NSRange changedRange = NSMakeRange(0, _groups.count);
		BOOL adjusting = YES;
		if (_firstCollapsedGroup != oldFirstCollapsedGroup) {
			if (narrower) {
				// Narrower. _firstCollapsedGroup will be less (earlier) than oldFirstCollapsedGroup.
				changedRange.location = _firstCollapsedGroup;
				changedRange.length = (oldFirstCollapsedGroup - _firstCollapsedGroup);
			} else {
				// Wider. _firstCollapsedGroup will be greater (later) than oldFirstCollapsedGroup.
				changedRange.location = oldFirstCollapsedGroup;
				changedRange.length = (_firstCollapsedGroup - oldFirstCollapsedGroup);
			}
		} else {
			// _firstCollapsedGroup and oldFirstCollapsedGroup are the same; nothing needs changed.
			adjusting = NO;
		}
		
		// If a change is required, ensure that each group is expanded or contracted as appropriate.
		if (adjusting || shouldAdjustPopups) {
			NSInteger nextXCoord = NSNotFound;
			if (adjusting) {
				for (int i = changedRange.location; i < NSMaxRange(changedRange); i++) {
					NSMutableDictionary *groupInfo = _groups[i];
					
					if (nextXCoord == NSNotFound) {
						BOOL menuMode = [groupInfo[GROUP_MENU_MODE] boolValue];
						NSButton *firstButton = nil;
						if (!menuMode) {
							firstButton = groupInfo[GROUP_BUTTONS][0];
						} else {
							firstButton = groupInfo[GROUP_POPUP_BUTTON];
						}
						nextXCoord = firstButton.frame.origin.x;
					} else {
						// Add group-spacing, separator and label as appropriate.
						nextXCoord += SCOPE_BAR_ITEM_SPACING;
						if ([groupInfo[GROUP_HAS_SEPARATOR] boolValue]) {
							nextXCoord += (SCOPE_BAR_SEPARATOR_WIDTH + SCOPE_BAR_ITEM_SPACING);
						}
						if ([groupInfo[GROUP_HAS_LABEL] boolValue]) {
							NSTextField *labelField = (NSTextField *)groupInfo[GROUP_LABEL_FIELD];
							float labelWidth = labelField.frame.size.width;
							nextXCoord += (labelWidth + SCOPE_BAR_ITEM_SPACING);
						}
					}
					
					NSPopUpButton *popup = nil;
					if (narrower) {
						// Remove buttons.
						NSArray *buttons = groupInfo[GROUP_BUTTONS];
						[buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
						
						// Create popup and add it to this view.
						popup = [self popupButtonForGroup:groupInfo];
						NSRect popupFrame = popup.frame;
						popupFrame.origin.x = nextXCoord;
						popup.frame = popupFrame;
						groupInfo[GROUP_POPUP_BUTTON] = popup;
						[self addSubview:popup positioned:NSWindowBelow relativeTo:_accessoryView];
						nextXCoord += popupFrame.size.width;
						
						// Ensure popup has appropriate title.
						[self updateMenuTitleForGroupAtIndex:i];
						
					} else {
						// Remove and release popup.
						popup = groupInfo[GROUP_POPUP_BUTTON];
						[popup removeFromSuperview];
						[groupInfo removeObjectForKey:GROUP_POPUP_BUTTON];
						
						// Replace menuItems with buttons.
						float buttonX = nextXCoord;
						NSMutableArray *menuItems = groupInfo[GROUP_BUTTONS];
						NSArray *selectedItems = _selectedItems[i];
						for (int i = 0; i < menuItems.count; i++) {
							NSMenuItem *menuItem = menuItems[i];
							NSString *itemIdentifier = menuItem.representedObject;
							NSButton *button = [self buttonForItem:itemIdentifier 
														   inGroup:menuItem.tag 
														 withTitle:menuItem.title 
															 image:menuItem.image];
							NSRect buttonFrame = button.frame;
							buttonFrame.origin.x = buttonX;
							button.frame = buttonFrame;
							if ([selectedItems containsObject:itemIdentifier]) {
								button.state = NSOnState;
							}
							[self addSubview:button positioned:NSWindowBelow relativeTo:_accessoryView];
							menuItems[i] = button;
							buttonX += button.frame.size.width + SCOPE_BAR_ITEM_SPACING;
						}
						nextXCoord = (buttonX - SCOPE_BAR_ITEM_SPACING);
					}
					
					// Update GROUP_MENU_MODE for this group.
					groupInfo[GROUP_MENU_MODE] = @(narrower);
				}
			}
			
			// Modify positions/sizes of groups and separators as required.
			float startIndex = MIN(changedRange.location, _firstCollapsedGroup);
			float xCoord = 0;
			float perGroupDelta = 0;
			_popupsShrunk = NO;
			if (shouldAdjustPopups) {
				perGroupDelta = ((_totalGroupsWidthForPopups - availableWidth) / _groups.count);
			}
			for (int i = startIndex; i < _groups.count; i++) {
				NSDictionary *groupInfo = _groups[i];
				BOOL menuMode = [groupInfo[GROUP_MENU_MODE] boolValue];
				
				// Further contract or expand popups if appropriate.
				if (shouldAdjustPopups) {
					float fullPopupWidth = [groupInfo[GROUP_WIDEST_BUTTON_WIDTH] floatValue] + MENU_PADDING;
					float popupWidth = fullPopupWidth - perGroupDelta;
					popupWidth = MAX(popupWidth, MENU_MIN_WIDTH);
					popupWidth = MIN(popupWidth, fullPopupWidth);
					
					_popupsShrunk = _popupsShrunk || (popupWidth < fullPopupWidth);
					
					NSPopUpButton *button = groupInfo[GROUP_POPUP_BUTTON];
					NSRect buttonRect = button.frame;
					buttonRect.size.width = popupWidth;
					button.frame = buttonRect;
					button.bordered = NO;
				}
				
				// Reposition groups appropriately.
				if (i > startIndex) {
					// Reposition separator if present.
					if ([groupInfo[GROUP_HAS_SEPARATOR] boolValue]) {
						_separatorPositions[i] = @(xCoord);
						xCoord += (SCOPE_BAR_SEPARATOR_WIDTH + SCOPE_BAR_ITEM_SPACING);
					}
					
					// Reposition label if present.
					if ([groupInfo[GROUP_HAS_LABEL] boolValue]) {
						NSTextField *label = groupInfo[GROUP_LABEL_FIELD];
						NSRect labelFrame = label.frame;
						labelFrame.origin.x = xCoord;
						label.frame = labelFrame;
						xCoord = NSMaxX(labelFrame) + SCOPE_BAR_ITEM_SPACING;
					}
					
					// Reposition buttons or popup.
					if (menuMode) {
						NSPopUpButton *button = groupInfo[GROUP_POPUP_BUTTON];
						NSRect buttonRect = button.frame;
						buttonRect.origin.x = xCoord;
						button.frame = buttonRect;
						button.bordered = NO;
						xCoord = NSMaxX(buttonRect) + SCOPE_BAR_ITEM_SPACING;
						
					} else {
						NSArray *buttons = groupInfo[GROUP_BUTTONS];
						for (NSButton *button in buttons) {
							NSRect buttonRect = button.frame;
							buttonRect.origin.x = xCoord;
							button.frame = buttonRect;
							button.bordered = NO;
							xCoord = NSMaxX(buttonRect) + SCOPE_BAR_ITEM_SPACING;
						}
					}
					
				} else {
					// Set up initial value of xCoord.
					NSButton *button = nil;
					if (menuMode) {
						button = groupInfo[GROUP_POPUP_BUTTON];
					} else {
						button = [groupInfo[GROUP_BUTTONS] lastObject];
					}
					xCoord = NSMaxX(button.frame) + SCOPE_BAR_ITEM_SPACING;
				}
			}
			
			// May need to move the accessory view, don't allow it to overlap
			if (_accessoryView) {
				NSDictionary* lastGroup = _groups.lastObject;
				BOOL lastMenuMode = [lastGroup[GROUP_MENU_MODE] boolValue];
				NSButton *lastButton = nil;
				if (lastMenuMode) {
					lastButton = lastGroup[GROUP_POPUP_BUTTON];
				} else {
					lastButton = [lastGroup[GROUP_BUTTONS] lastObject];
				}
				float maxX = NSMaxX(lastButton.frame) + SCOPE_BAR_ITEM_SPACING;
				NSRect frame = _accessoryView.frame;
				frame.origin.x = round(NSMaxX(self.bounds) - (frame.size.width + SCOPE_BAR_H_INSET));

				if (frame.origin.x < maxX)
					frame.origin.x = maxX;
				
				_accessoryView.frame = frame;
			}
				
			
			
			// Reset _firstCollapsedGroup to NSNotFound if necessary.
			if (!narrower) {
				if (_firstCollapsedGroup >= _groups.count) {
					_firstCollapsedGroup = NSNotFound;
				}
			}
		}
		
		// Re-enable screen updates.
		NSEnableScreenUpdates();
	}
	
	// Take note of our width for comparison next time.
	_lastWidth = viewWidth;
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	[super resizeSubviewsWithOldSize:oldBoundsSize];
	[self adjustSubviews];
}


- (NSButton *)getButtonForItem:(NSString *)identifier inGroup:(int)groupNumber
{
	NSButton *button = nil;
	NSArray *group = _identifiers[identifier];
	if (group && group.count > groupNumber) {
		NSObject *element = group[groupNumber];
		if (element != [NSNull null]) {
			button = (NSButton *)element;
		}
	}
	
	return button;
}


- (NSButton *)buttonForItem:(NSString *)identifier inGroup:(int)groupNumber 
				  withTitle:(NSString *)title image:(NSImage *)image
{
	NSRect ctrlRect = NSMakeRect(0, 0, 50, 20); // arbitrary size; will be resized later.
	NSButton *button = [[NSButton alloc] initWithFrame:ctrlRect];
	button.title = title;
	button.cell.representedObject = identifier;
	button.cell.controlSize = NSSmallControlSize;
	button.tag = groupNumber;
	button.font = [NSFont systemFontOfSize:SCOPE_BAR_FONTSIZE];
	button.target = self;
	button.action = @selector(scopeButtonClicked:);
	button.bezelStyle = NSRoundRectBezelStyle;
	[button setButtonType:NSPushOnPushOffButton];
	[(NSButtonCell *)button.cell setHighlightsBy:(NSCellIsBordered | NSCellIsInsetButton)];
	[button setShowsBorderOnlyWhileMouseInside:NO];
	if (image) {
		image.size = NSMakeSize(SCOPE_BAR_BUTTON_IMAGE_SIZE, SCOPE_BAR_BUTTON_IMAGE_SIZE);
		button.imagePosition = NSImageLeft;
		button.image = image;
	}
	[button sizeToFit];
	ctrlRect = button.frame;
	ctrlRect.origin.y = floor((self.frame.size.height - ctrlRect.size.height) / 2.0);
	button.frame = ctrlRect;
	
	[self setControl:button forIdentifier:identifier inGroup:groupNumber];
	
	return button;
}


- (NSMenuItem *)menuItemForItem:(NSString *)identifier inGroup:(int)groupNumber 
					  withTitle:(NSString *)title image:(NSImage *)image
{
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(scopeButtonClicked:) keyEquivalent:@""];
	menuItem.target = self;
	menuItem.image = image;
	menuItem.representedObject = identifier;
	menuItem.tag = groupNumber;
	
	[self setControl:menuItem forIdentifier:identifier inGroup:groupNumber];
	
	return menuItem;
}


- (NSPopUpButton *)popupButtonForGroup:(NSDictionary *)group
{
	float popWidth = floor([group[GROUP_WIDEST_BUTTON_WIDTH] floatValue] + MENU_PADDING);
	NSRect popFrame = NSMakeRect(0, 0, popWidth, 20); // arbitrary height.
	NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:popFrame pullsDown:NO];
	
	// Since we're not using the selected item's title, we need to specify a NSMenuItem for the title.
	BOOL multiSelect = ([group[GROUP_SELECTION_MODE] intValue] == MGMultipleSelectionMode);
	if (multiSelect) {
		MGRecessedPopUpButtonCell *cell = [[MGRecessedPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
		popup.cell = cell;
		
		[popup.cell setUsesItemFromMenu:NO];
		NSMenuItem *titleItem = [[NSMenuItem alloc] init];
		[(NSPopUpButtonCell *)popup.cell setMenuItem:titleItem];
	}
	
	// Configure appearance and behaviour.
	popup.font = [NSFont systemFontOfSize:SCOPE_BAR_FONTSIZE];
	popup.bezelStyle = NSBezelStyleRounded;
	[popup setButtonType:NSButtonTypeMomentaryPushIn];
	popup.cell.controlSize = NSSmallControlSize;
	[popup.cell setAltersStateOfSelectedItem:NO];
	[(MGRecessedPopUpButtonCell *)popup.cell setArrowPosition:NSPopUpArrowAtBottom];
	[(MGRecessedPopUpButtonCell *)popup.cell setBordered:NO];
	popup.preferredEdge = NSMinYEdge;
	
	// Add appropriate items.
	[popup removeAllItems];
	NSMutableArray *buttons = group[GROUP_BUTTONS];
	for (int i = 0; i < buttons.count; i++) {
		NSButton *button = (NSButton *)buttons[i];
		NSMenuItem *menuItem = [self menuItemForItem:button.cell.representedObject 
											 inGroup:button.tag 
										   withTitle:button.title 
											   image:button.image];
		menuItem.state = button.state;
		buttons[i] = menuItem;
		[popup.menu addItem:menuItem];
	}
	
	// Vertically center the popup within our frame.
	if (!multiSelect) {
		[popup sizeToFit];
	}
	popFrame = popup.frame;
	popFrame.origin.y = ceil((self.frame.size.height - popFrame.size.height) / 2.0);
	popup.frame = popFrame;
	popup.bordered = NO;
	
	return popup;
}


- (void)setControl:(NSObject *)control forIdentifier:(NSString *)identifier inGroup:(int)groupNumber
{
	if (!_identifiers) {
		_identifiers = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	
	NSMutableArray *identArray = _identifiers[identifier];
	if (!identArray) {
		identArray = [[NSMutableArray alloc] initWithCapacity:groupNumber + 1];
		_identifiers[identifier] = identArray;
	}
	
	int count = identArray.count;
	if (groupNumber >= count) {
		// Pad identArray with nulls if appropriate, so this control lies at index groupNumber.
		for (int i = count; i < groupNumber; i++) {
			[identArray addObject:[NSNull null]];
		}
		[identArray addObject:control];
	} else {
		identArray[groupNumber] = control;
	}
}


- (void)updateMenuTitleForGroupAtIndex:(int)groupNumber
{
	// Ensure that this group's popup (if present) has the correct title,
	// accounting for the group's selection-mode and selected item(s).
	
	if (groupNumber < 0 || groupNumber >= _groups.count) {
		return;
	}
	
	NSDictionary *group = _groups[groupNumber];
	if (group) {
		NSPopUpButton *popup = group[GROUP_POPUP_BUTTON];
		if (popup) {
			NSArray *groupSelection = _selectedItems[groupNumber];
			int numSelected = groupSelection.count;
			if (numSelected == 0) {
				// No items selected.
                NSString* groupTitle = group[GROUP_TITLE];
                if(groupTitle)
                    [popup setTitle:groupTitle];
                else
                    [popup setTitle:POPUP_TITLE_EMPTY_SELECTION];
                
				[[popup.cell menuItem] setImage:nil];
				
			} else if (numSelected > 1) {
				// Multiple items selected.
				[popup setTitle:POPUP_TITLE_MULTIPLE_SELECTION];
				[[popup.cell menuItem] setImage:nil];
				
			} else {
				// One item selected.
				NSString *identifier = groupSelection[0];
				NSArray *items = group[GROUP_BUTTONS];
				NSMenuItem *item = nil;
				for (NSMenuItem *thisItem in items) {
					if ([thisItem.representedObject isEqualToString:identifier]) {
						item = thisItem;
						break;
					}
				}
				if (item) {
					[popup setTitle:item.title];
					[popup.cell menuItem].image = item.image;
				}
			}
			
			[popup.cell setBordered:NO];
		}
	}
}


#pragma mark Drawing


- (void)drawRect:(NSRect)rect
{
    /*
    // Draw flat background
    [[NSColor controlColor] set];
    NSRectFill([self bounds]);

    // Draw border.
	NSRect lineRect = [self bounds];
	lineRect.size.height = SCOPE_BAR_BORDER_WIDTH;
	[SCOPE_BAR_BORDER_COLOR set];
	NSRectFill(lineRect);
     */
	
	// Draw separators.
	if (_separatorPositions.count > 0) {
		[SCOPE_BAR_SEPARATOR_COLOR set];
		NSRect sepRect = NSMakeRect(0, 0, SCOPE_BAR_SEPARATOR_WIDTH, SCOPE_BAR_SEPARATOR_HEIGHT);
		sepRect.origin.y = ((self.bounds.size.height - sepRect.size.height) / 2.0);
		for (NSObject *sepPosn in _separatorPositions) {
			if (sepPosn != [NSNull null]) {
				sepRect.origin.x = ((NSNumber *)sepPosn).intValue;
				NSRectFill(sepRect);
			}
		}
	}
}


#pragma mark Interaction


- (IBAction)scopeButtonClicked:(id)sender
{
	NSButton *button = (NSButton *)sender;
	BOOL menuMode = [sender isKindOfClass:[NSMenuItem class]];
	NSString *identifier = [((menuMode) ? sender : [sender cell]) representedObject];
	int groupNumber = 0;
	BOOL nowSelected = YES;
	if (menuMode) {
		// MenuItem. Ensure item has appropriate state.
		groupNumber = ((NSMenuItem *)sender).tag;
		nowSelected = ![_selectedItems[groupNumber] containsObject:identifier];
		[sender setState:((nowSelected) ? NSOnState : NSOffState)];
	} else {
		// Button. Item will already have appropriate state.
		groupNumber = ((NSControl *)sender).tag;
		nowSelected = (button.state != NSOffState);
	}
	[self setSelected:nowSelected forItem:identifier inGroup:groupNumber];
}


#pragma mark Accessors and properties


- (void)setSelected:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber
{
	// Change state of other items in group appropriately, informing delegate if possible.
	// First we find the appropriate group-info for the item's identifier.
	if (identifier && groupNumber >= 0 && groupNumber < _groups.count) {
		NSDictionary *group = _groups[groupNumber];
		BOOL nowSelected = selected;
		BOOL informDelegate = YES;
		
		if (group) {
			NSDisableScreenUpdates();
			
			// We found the group which this item belongs to. Obtain selection-mode and identifiers.
			MGScopeBarGroupSelectionMode selMode = [group[GROUP_SELECTION_MODE] intValue];
			BOOL radioMode = (selMode == MGRadioSelectionMode);
			
			if (radioMode) {
				// This is a radio-mode group. Ensure this item isn't already selected.
				NSArray *groupSelections = [_selectedItems[groupNumber] copy];
				
				if (nowSelected) {
					// Before selecting this item, we first need to deselect any other selected items in this group.
					for (NSString *selectedIdentifier in groupSelections) {
						// Reselect the just-deselected item without informing the delegate, since nothing really changed.
						[self updateSelectedState:NO forItem:selectedIdentifier inGroup:groupNumber informDelegate:NO];
					}
				} else {
					// Prevent deselection if this item is already selected.
					if ([groupSelections containsObject:identifier]) {
						nowSelected = YES;
						informDelegate = NO;
					}
				}
			}
			
			// Change selected state of this item.
			[self updateSelectedState:nowSelected forItem:identifier inGroup:groupNumber informDelegate:informDelegate];
			
			// Update popup-menu's title if appropriate.
			if ([group[GROUP_MENU_MODE] boolValue]) {
				[self updateMenuTitleForGroupAtIndex:groupNumber];
			}
			
			NSEnableScreenUpdates();
		}
	}
}


- (void)updateSelectedState:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber informDelegate:(BOOL)inform
{
	// This method simply updates the selected state of the item's control, maintains selectedItems, and informs the delegate.
	// All management of dependencies (such as deselecting other selected items in a radio-selection-mode group) is performed 
	// in the setSelected:forItem:inGroup: method.
	
	// Determine whether we can inform the delegate about this change.
	SEL stateChangedSel = @selector(scopeBar:selectedStateChanged:forItem:inGroup:);
	BOOL responds = (delegate && [delegate respondsToSelector:stateChangedSel]);
	
	// Ensure selected status of item's control reflects desired value.
	NSButton *button = [self getButtonForItem:identifier inGroup:groupNumber];
	if (selected && button.state == NSOffState) {
		button.state = NSOnState;
	} else if (!selected && button.state != NSOffState) {
		button.state = NSOffState;
	}
	
	// Maintain _selectedItems appropriately.
	if (_selectedItems && _selectedItems.count > groupNumber) {
		NSMutableArray *groupSelections = _selectedItems[groupNumber];
		BOOL alreadySelected = [groupSelections containsObject:identifier];
		if (selected && !alreadySelected) {
			[groupSelections addObject:identifier];
		} else if (!selected && alreadySelected) {
			[groupSelections removeObject:identifier];
		}
	}
	
	// Inform delegate about this change if possible.
	if (inform && responds) {
		[delegate scopeBar:self selectedStateChanged:selected forItem:identifier inGroup:groupNumber];
	}
}


- (NSArray *)selectedItems
{
	return [_selectedItems copy];
}


- (void)setDelegate:(id)newDelegate
{
	if (delegate != newDelegate) {
		delegate = newDelegate;
		[self reloadData];
	}
}
-(id)delegate
{
    return delegate;
}


- (BOOL)smartResizeEnabled
{
	return _smartResizeEnabled;
}


- (void)setSmartResizeEnabled:(BOOL)enabled
{
	if (enabled != _smartResizeEnabled) {
		_smartResizeEnabled = enabled;
		[self reloadData];
	}
}

- (BOOL)notifyDefaultSelections
{
	return _notifyDefaultSelections;
}
- (void)setNotifyDefaultSelections:(BOOL)s
{
	_notifyDefaultSelections = s;		
}



@synthesize delegate;


@end
