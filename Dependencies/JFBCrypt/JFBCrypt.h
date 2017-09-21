//
// JFBCrypt.h
// JFCommon
//
// Created by Jason Fuerstenberg on 11/07/03.
// Copyright (c) 2011 Jason Fuerstenberg. All rights reserved.
//
// http://www.jayfuerstenberg.com
// jay@jayfuerstenberg.com
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// This objective C port is based on the original Java implementation by Damien Miller
// found here: http://www.mindrot.org/projects/jBCrypt/
// In accordance with the Damien Miller's request, his original copyright covering
// his Java implementation is included in the accompanying BCrypt-java-copyright.txt file.

//Further modified to extend the algorithm to perform iterative hashing for use at Atlassian Inc.
//For details on usage contact Manjunath - mbasaralusrinivasa@atlassian.com

@import Foundation;

#import "JFGC.h"		// For GC related macros
#import "JFRandom.h"	// For generating random salts


/*
 * The JFBCrypt utility class.
 * This class has been tested to work on iOS 4.2.
 */
@interface JFBCrypt : NSObject {

@private
	SInt32 *_p;
	SInt32 *_s;
}
/**
 Commented to extend this algorithm to perform iterative hashing.
 */
//+ (NSString *) hashPassword: (NSString *) password withSalt: (NSString *) salt;

/**
 Hashes the given string with the salt value provided and the algorithm as per the the minor and complexity specified in rounds.
 Original public API as commented above modified by Manjunath for use at Atlassian Inc.
 @param password    The string value to be hashed.
 @param salt        The string value of the salt to be used for hashing.
 @param inMinor     The character which determines which algorithm is used, as read from the public file for hashing algorithm ("a/b". "b" in our case as on 09/30/2015.
 @param inRounds    The complexity value as read from the public file for hashing algorithm.
 
 @return Hashed value of the given string.
 */
+ (NSString *)hashPassword:(NSString *)password withSalt:(NSString *)salt minor:(unichar)inMinor andRounds:(SInt32)inRounds;

@end
