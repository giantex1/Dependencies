//
//  Created by Brian Ganninger on 11/25/16.
//  Copyright © 2016 Atlassian. All rights reserved.
//

@import Foundation;

@interface NSString (PRGHashing)

/*!
 * @discussion Generate a SHA1 hash for this string.
 * @return NSString SHA1 hash, in a new string, based on the current string.
 */
- (nonnull NSString *)prg_SHA1Hash;

@end
