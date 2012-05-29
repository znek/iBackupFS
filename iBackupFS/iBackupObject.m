//
//  iBackupObject.m
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "iBackupObject.h"
#import "NSObject+FUSEOFS.h"
#import "FUSEOFSFileProxy.h"

@interface iBackupObject (Private)
- (NSFileManager *)fileManager;
- (NSString *)getRelativePath:(NSString *)_pc;
@end

@implementation iBackupObject

- (id)initWithPath:(NSString *)_path {
	self = [self init];
	if (self) {
		self->path = [_path copy];
		
		BOOL isDir;
		BOOL exists = [[self fileManager] fileExistsAtPath:self->path
										  isDirectory:&isDir];
		if (!exists)
			self->isContainer = NO;
		else
			self->isContainer = isDir;
	}
	return self;
}

- (void)dealloc {
	[self->path release];
	[super dealloc];
}

/* private */

- (NSFileManager *)fileManager {
	return [NSFileManager defaultManager];
}

- (NSString *)getRelativePath:(NSString *)_pc {
	return [self->path stringByAppendingPathComponent:_pc];
}


/* FUSEOFS */

- (id)lookupPathComponent:(NSString *)_pc inContext:(id)_ctx {
	if ([self isContainer]) {
		if ([[self containerContents] containsObject:_pc]) {
			NSString *pcPath = [self getRelativePath:_pc];
			return [[[FUSEOFSFileProxy alloc] initWithPath:pcPath] autorelease];
		}
	}
	return nil;
}

/* reflection */

- (BOOL)isContainer {
	return self->isContainer;
}

/* read */

- (NSData *)fileContents {
	if (![self isContainer])
		return [[self fileManager] contentsAtPath:self->path];
	return nil;
}

- (NSArray *)containerContents {
	if ([self isContainer])
#if ! GNUSTEP_BASE_LIBRARY
		return [[self fileManager] contentsOfDirectoryAtPath:self->path error:NULL];
#else
	return [[self fileManager] directoryContentsAtPath:self->path];
#endif
	return nil;
}

@end
