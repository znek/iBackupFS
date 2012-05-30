//
//  NSString+iBackupFS.m
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "NSString+iBackupFS.h"
#include <openssl/sha.h>

@implementation NSString (iBackupFS)

- (NSString *)getSHA1HashedFilename {
	unsigned char result[SHA_DIGEST_LENGTH];
	
	NSMutableString *digest = [[[NSMutableString alloc]
								                 initWithCapacity:SHA_DIGEST_LENGTH * 2]
							                     autorelease];
	SHA1([self cString], [self cStringLength], result);

	for (NSUInteger i = 0; i < SHA_DIGEST_LENGTH; i++) {
		[digest appendFormat:@"%02x", *(result + i)];
	}
	return digest;
}
@end
