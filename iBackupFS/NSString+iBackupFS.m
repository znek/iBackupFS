//
//  NSString+iBackupFS.m
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "NSString+iBackupFS.h"
#include <CommonCrypto/CommonCrypto.h>

@implementation NSString (iBackupFS)

- (NSString *)getSHA1HashedFilename {
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	
	NSMutableString *digest = [[[NSMutableString alloc]
								                 initWithCapacity:CC_SHA1_DIGEST_LENGTH * 2]
							                     autorelease];
	CC_SHA1([self cString], (CC_LONG)[self cStringLength], result);

	for (NSUInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[digest appendFormat:@"%02x", *(result + i)];
	}
	return digest;
}
@end
