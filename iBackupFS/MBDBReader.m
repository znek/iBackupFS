//
//  MBDBReader.m
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "MBDBReader.h"
#import "NSMutableDictionary+iBackupFS.h"
#import "NSString+iBackupFS.h"
#import "iBackup.h"
#import "iBackupObject.h"

@interface MBDBReader (Private)
- (void)_parseDB;

- (NSData *)readDataOfLength:(NSUInteger)_length;

- (NSString *)readString;
- (UInt8)readUInt8;
- (UInt16)readUInt16;
- (UInt32)readUInt32;
- (UInt64)readUInt64;
@end

@implementation MBDBReader

- (id)initWithPath:(NSString *)_path {
	self = [self init];
	if (self) {
		NSFileManager *fm    = [NSFileManager defaultManager];
		NSDictionary  *attrs = [fm attributesOfItemAtPath:_path error:NULL];
		
		self->size = [[attrs objectForKey:NSFileSize] unsignedLongLongValue];
		self->fh   = [[NSFileHandle fileHandleForReadingAtPath:_path] retain];
		self->path = [[_path stringByDeletingLastPathComponent] copy];
		self->contentMap = [[NSMutableDictionary alloc] init];
		
		[self _parseDB];
	}
	return self;
}

- (void)dealloc {
	[self->fh   release];
	[self->path release];
	[self->contentMap release];
	[super dealloc];
}

/* reading primitives */

- (NSData *)readDataOfLength:(NSUInteger)_length {
	self->size -= _length;
	return [self->fh readDataOfLength:_length];
}

- (UInt8)readUInt8 {
	UInt8 v;
	NSData *d = [self readDataOfLength:1];
	v = *(UInt8 *)[d bytes];
	return v;
}
- (UInt16)readUInt16 {
	UInt16 v;
	NSData *d = [self readDataOfLength:2];
	v = *(UInt16 *)[d bytes];
	return NSSwapBigShortToHost(v);

}
- (UInt32)readUInt32 {
	UInt32 v;
	NSData *d = [self readDataOfLength:4];
	v = *(UInt32 *)[d bytes];
	return NSSwapBigIntToHost(v);

}
- (UInt64)readUInt64 {
	UInt64 v;
	NSData *d = [self readDataOfLength:8];
	v = *(UInt64 *)[d bytes];
	return NSSwapBigLongLongToHost(v);
}
- (NSString *)readString {
	static const char term = '\0';

	NSUInteger count = (NSUInteger)[self readUInt16];
	if (count == 0xFFFF || count == 0)
		return nil;
	NSMutableData *d = [[self readDataOfLength:count] mutableCopy];
	[d appendBytes:&term length:1];
	return [NSString stringWithUTF8String:[d bytes]];
}

/* parsing */

- (void)_parseDB {
	
	// read magic
	[self readDataOfLength:6];
	
	while(self->size) {
		NSString *domain     = [self readString];
		NSString *rPath      = [self readString];
		NSString *linkTarget = [self readString];
		NSString *dataHash   = [self readString];
		NSString *unknown1   = [self readString];
		UInt16   mode        = [self readUInt16];
		UInt32   unknown2    = [self readUInt32];
		UInt32   unknown3    = [self readUInt32];
		UInt32   userId      = [self readUInt32];
		UInt32   groupId     = [self readUInt32];
		UInt32   time1       = [self readUInt32];
		UInt32   time2       = [self readUInt32];
		UInt32   time3       = [self readUInt32];
		UInt64   fileLength  = [self readUInt64];
		UInt8    flag        = [self readUInt8];
		UInt8    propertyCount = [self readUInt8];

		for (NSUInteger i = 0; i < propertyCount; i++) {
			NSString *propName  = [self readString];
			NSString *propValue = [self readString];
		}

		// we skip links, as these point to "fancy" locations like
		// /private/var/mobile/Library/Preferences/.GlobalPreferences.plist
		if (linkTarget)
			rPath = [linkTarget substringFromIndex:1];

		if (rPath) {
			NSString *combinedPath = [domain stringByAppendingFormat:@"-%@", rPath];
			NSString *name         = [combinedPath getSHA1HashedFilename];

			NSString *objPath = [self->path stringByAppendingPathComponent:name];
			iBackupObject *obj = [[iBackupObject alloc] initWithPath:objPath];
			NSString *contentPath = [iBackup properPathFromDomain:domain relativePath:rPath];
			[self->contentMap addContentObject:obj path:contentPath];
			[obj release];
		}
	}

	[self->fh closeFile];
}



/* accessors */

- (NSDictionary *)contentMap {
	return (NSDictionary *)self->contentMap;
}

@end
