//
//  iBackupFileObject.m
//  iBackupFS
//
//  Created by znek on 05.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import "iBackupFileObject.h"
#import "iBackup.h"

@implementation iBackupFileObject

- (id)initWithFileID:(NSString *)_fileID fromBackup:(iBackup *)_backup {
	self = [self init];
	if (self) {
		self->backup = _backup; // weak ref
		self->fileID = [_fileID retain];
	}
	return self;
}

- (void)dealloc {
	[self->fileID release];
	[self->wrappedKey release];
	[super dealloc];
}

- (NSString *)fileID {
	return self->fileID;
}

- (void)setWrappedKey:(NSData *)_wrappedKey {
	if (self->wrappedKey != _wrappedKey) {
		[self->wrappedKey release];
		self->wrappedKey = [_wrappedKey retain];
	}
}
- (NSData *)wrappedKey {
	return self->wrappedKey;
}

/* FUSEOFS */

- (BOOL)isContainer {
  return NO;
}
- (BOOL)isMutable {
  return NO;
}

- (NSData *)fileContents {
	return [self->backup contentsOfHashedObject:self];
}

@end
