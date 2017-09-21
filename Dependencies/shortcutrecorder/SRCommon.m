//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2011 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"

#pragma mark -
#pragma mark dummy class 

@implementation SRDummyClass @end

#pragma mark -

//---------------------------------------------------------- 
// SRStringForKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForKeyCode( NSInteger keyCode )
{
    static SRKeyCodeTransformer *keyCodeTransformer = nil;
    if ( !keyCodeTransformer )
        keyCodeTransformer = [[SRKeyCodeTransformer alloc] init];
    return [keyCodeTransformer transformedValue:@(keyCode)];
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlags( NSUInteger flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & controlKey ? [NSString stringWithFormat:@"%C", (ushort)KeyboardControlGlyph] : @"" ),
		( flags & optionKey ? [NSString stringWithFormat:@"%C", (ushort)KeyboardOptionGlyph] : @"" ),
		( flags & shiftKey ? [NSString stringWithFormat:@"%C", (ushort)KeyboardShiftGlyph] : @"" ),
		( flags & cmdKey ? [NSString stringWithFormat:@"%C", (ushort)KeyboardCommandGlyph] : @"" )];
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCarbonModifierFlags( flags ), 
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlags( NSUInteger flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & NSControlKeyMask ? [NSString stringWithFormat:@"%C", (ushort)KeyboardControlGlyph] : @"" ),
		( flags & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", (ushort)KeyboardOptionGlyph] : @"" ),
		( flags & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", (ushort)KeyboardShiftGlyph] : @"" ),
		( flags & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", (ushort)KeyboardCommandGlyph] : @"" )];
	
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCocoaModifierFlags( flags ),
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRReadableStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		( flags & cmdKey ? SRLoc(@"Command + ") : @""),
		( flags & optionKey ? SRLoc(@"Option + ") : @""),
		( flags & controlKey ? SRLoc(@"Control + ") : @""),
		( flags & shiftKey ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;    
}

//---------------------------------------------------------- 
// SRReadableStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & NSCommandKeyMask ? SRLoc(@"Command + ") : @""),
		(flags & NSAlternateKeyMask ? SRLoc(@"Option + ") : @""),
		(flags & NSControlKeyMask ? SRLoc(@"Control + ") : @""),
		(flags & NSShiftKeyMask ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
NSUInteger SRCarbonToCocoaFlags( NSUInteger carbonFlags )
{
	NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags |= NSCommandKeyMask;
	if (carbonFlags & optionKey) cocoaFlags |= NSAlternateKeyMask;
	if (carbonFlags & controlKey) cocoaFlags |= NSControlKeyMask;
	if (carbonFlags & shiftKey) cocoaFlags |= NSShiftKeyMask;
	if (carbonFlags & NSFunctionKeyMask) cocoaFlags += NSFunctionKeyMask;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
NSUInteger SRCocoaToCarbonFlags( NSUInteger cocoaFlags )
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (cocoaFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (cocoaFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (cocoaFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	if (cocoaFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCarbonFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCarbonFlags(NSInteger keyCode, NSUInteger carbonFlags) {
	return SRCharacterForKeyCodeAndCocoaFlags(keyCode, SRCarbonToCocoaFlags(carbonFlags));
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCocoaFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCocoaFlags(NSInteger keyCode, NSUInteger cocoaFlags) {
	// Fall back to string based on key code:
#define	FailWithNaiveString SRStringForKeyCode(keyCode)
	
	UInt32              deadKeyState;
    OSStatus err = noErr;
    CFLocaleRef locale = CFLocaleCopyCurrent();
	
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if(!tisSource)
	{
		if (locale)
			CFRelease(locale);
		
		return FailWithNaiveString;
	}
	
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    if (!layoutData)
	{
		if (locale)
			CFRelease(locale);
		
		return FailWithNaiveString;
	}
	
	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    if (!keyLayout)
	{
		if (locale)
			CFRelease(locale);

		return FailWithNaiveString;
	}
	
	EventModifiers modifiers = 0;
	if (cocoaFlags & NSAlternateKeyMask)	modifiers |= optionKey;
	if (cocoaFlags & NSShiftKeyMask)		modifiers |= shiftKey;
	UniCharCount maxStringLength = 4, actualStringLength;
	UniChar unicodeString[4];
	err = UCKeyTranslate( keyLayout, (UInt16)keyCode, kUCKeyActionDisplay, modifiers, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString );
	if(err != noErr)
	{
		if (locale)
			CFRelease(locale);

		return FailWithNaiveString;
	}

	CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, unicodeString, 1);
	CFMutableStringRef mutableTemp = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, temp);

	CFStringCapitalize(mutableTemp, locale);

	NSString *resultString = [NSString stringWithString:(__bridge NSString *)mutableTemp];

	if (temp) CFRelease(temp);
	if (mutableTemp) CFRelease(mutableTemp);
    if (locale) CFRelease(locale);
	
	return resultString;
}

#pragma mark Animation Easing

#define CG_M_PI (CGFloat)M_PI
#define CG_M_PI_2 (CGFloat)M_PI_2

#ifdef __LP64__
#define CGSin(x) sin(x)
#else
#define CGSin(x) sinf(x)
#endif

// From: http://developer.apple.com/samplecode/AnimatedSlider/ as "easeFunction"
CGFloat SRAnimationEaseInOut(CGFloat t) {
	// This function implements a sinusoidal ease-in/ease-out for t = 0 to 1.0.  T is scaled to represent the interval of one full period of the sine function, and transposed to lie above the X axis.
	CGFloat x = (CGSin((t * CG_M_PI) - CG_M_PI_2) + 1.0f ) / 2.0f;
	return x;
} 


#pragma mark -
#pragma mark additions

@implementation NSAlert( SRAdditions )

//---------------------------------------------------------- 
// + alertWithNonRecoverableError:
//---------------------------------------------------------- 
+ (NSAlert *) alertWithNonRecoverableError:(NSError *)error;
{
	NSString *reason = error.localizedRecoverySuggestion;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = error.localizedDescription;
    alert.informativeText = [NSString stringWithFormat:@"%@", (reason ? reason : @"")];
    [alert addButtonWithTitle:error.localizedRecoveryOptions[0U]];
    
    return alert;
}

@end

static NSMutableDictionary *SRSharedImageCache = nil;

@interface SRSharedImageProvider (Private)
+ (void)_drawSRSnapback:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRSnapback;
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcut;
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutRollover;
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutPressed;

+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(CGFloat)opacity;
@end

@implementation SRSharedImageProvider
+ (NSImage *)supportingImageWithName:(NSString *)name {
	if (nil == SRSharedImageCache) {
		SRSharedImageCache = [NSMutableDictionary dictionary];
	}
	NSImage *cachedImage = nil;
	if (nil != (cachedImage = SRSharedImageCache[name])) {
		return cachedImage;
	}
	
	NSSize size;
    SEL sizeselector = NSSelectorFromString([NSString stringWithFormat:@"_size%@", name]);
    IMP sizeimp = [self methodForSelector:sizeselector];
    NSValue *sizeValue = sizeimp(self, sizeselector, name);
	size = sizeValue.sizeValue;
	
    SEL drawselector = NSSelectorFromString([NSString stringWithFormat:@"_draw%@:", name]);
	NSCustomImageRep *customImageRep = [[NSCustomImageRep alloc] initWithDrawSelector:drawselector delegate:self];
	customImageRep.size = size;
	NSImage *returnImage = [[NSImage alloc] initWithSize:size];
	[returnImage addRepresentation:customImageRep];
	SRSharedImageCache[name] = returnImage;
	
#ifdef SRCommonWriteDebugImagery
	
	NSData *tiff = [returnImage TIFFRepresentation];
	[tiff writeToURL:[NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Desktop/m_%@.tiff", name] stringByExpandingTildeInPath]] atomically:YES];

	NSSize sizeQDRPL = NSMakeSize(size.width*4.0,size.height*4.0);
	
//	sizeQDRPL = NSMakeSize(70.0,70.0);
	NSCustomImageRep *customImageRepQDRPL = [[NSCustomImageRep alloc] initWithDrawSelector:NSSelectorFromString([NSString stringWithFormat:@"_draw%@:", name]) delegate:self];
	[customImageRepQDRPL setSize:sizeQDRPL];
	NSImage *returnImageQDRPL = [[NSImage alloc] initWithSize:sizeQDRPL];
	[returnImageQDRPL addRepresentation:customImageRepQDRPL];
	[customImageRepQDRPL release];
	[returnImageQDRPL setScalesWhenResized:YES];
	[returnImageQDRPL setFlipped:YES];
	NSData *tiffQDRPL = [returnImageQDRPL TIFFRepresentation];
	[tiffQDRPL writeToURL:[NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Desktop/m_QDRPL_%@.tiff", name] stringByExpandingTildeInPath]] atomically:YES];
	
#endif

	return returnImage;
}
@end

@implementation SRSharedImageProvider (Private)

#define MakeRelativePoint(x,y)	NSMakePoint(x*hScale, y*vScale)

+ (NSValue *)_sizeSRSnapback {
	return [NSValue valueWithSize:NSMakeSize(14.0f,14.0f)];
}
+ (void)_drawSRSnapback:(id)anNSCustomImageRep {
	NSCustomImageRep *rep = anNSCustomImageRep;
	NSSize size = rep.size;
	[[NSColor whiteColor] setFill];
	CGFloat hScale = (size.width/1.0f);
	CGFloat vScale = (size.height/1.0f);
	
	NSBezierPath *bp = [[NSBezierPath alloc] init];
	bp.lineWidth = hScale;
	
	[bp moveToPoint:MakeRelativePoint(0.0489685f, 0.6181513f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.9469318f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.7226146f)];
	[bp curveToPoint:MakeRelativePoint(0.8508247f, 0.4836237f) controlPoint1:MakeRelativePoint(0.4085750f, 0.7226146f) controlPoint2:MakeRelativePoint(0.8371143f, 0.7491841f)];
	[bp curveToPoint:MakeRelativePoint(0.5507195f, 0.0530682f) controlPoint1:MakeRelativePoint(0.8677834f, 0.1545071f) controlPoint2:MakeRelativePoint(0.5507195f, 0.0530682f)];
	[bp curveToPoint:MakeRelativePoint(0.7421721f, 0.3391942f) controlPoint1:MakeRelativePoint(0.5507195f, 0.0530682f) controlPoint2:MakeRelativePoint(0.7458685f, 0.1913146f)];
	[bp curveToPoint:MakeRelativePoint(0.4085750f, 0.5154130f) controlPoint1:MakeRelativePoint(0.7383412f, 0.4930328f) controlPoint2:MakeRelativePoint(0.4085750f, 0.5154130f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.2654000f)];
	
	NSAffineTransform *flip = [[NSAffineTransform alloc] init];
//	[flip translateXBy:0.95f yBy:-1.0f];
	[flip scaleXBy:0.9f yBy:1.0f];
	[flip translateXBy:0.5f yBy:-0.5f];
	
	[bp transformUsingAffineTransform:flip];
	
	NSShadow *sh = [[NSShadow alloc] init];
	sh.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.45f];
	sh.shadowBlurRadius = 1.0f;
	sh.shadowOffset = NSMakeSize(0.0f,-1.0f);
	[sh set];
	
	[bp fill];
	
}

+ (NSValue *)_sizeSRRemoveShortcut {
	return [NSValue valueWithSize:NSMakeSize(14.0f,14.0f)];
}
+ (NSValue *)_sizeSRRemoveShortcutRollover { return [self _sizeSRRemoveShortcut]; }
+ (NSValue *)_sizeSRRemoveShortcutPressed { return [self _sizeSRRemoveShortcut]; }
+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(CGFloat)opacity {
	NSCustomImageRep *rep = anNSCustomImageRep;
	NSSize size = rep.size;
	[[NSColor colorWithCalibratedWhite:0.0f alpha:1.0f-opacity] setFill];
	CGFloat hScale = (size.width/14.0f);
	CGFloat vScale = (size.height/14.0f);
	
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0f,0.0f,size.width,size.height)] fill];
	
	[[NSColor whiteColor] setStroke];
	
	NSBezierPath *cross = [[NSBezierPath alloc] init];
	cross.lineWidth = hScale*1.2f;
	
	[cross moveToPoint:MakeRelativePoint(4.0f,4.0f)];
	[cross lineToPoint:MakeRelativePoint(10.0f,10.0f)];
	[cross moveToPoint:MakeRelativePoint(10.0f,4.0f)];
	[cross lineToPoint:MakeRelativePoint(4.0f,10.0f)];
		
	[cross stroke];
}
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep {
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.75f];
}
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep {
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.65f];
}
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep {
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.55f];
}
@end
