//
//  iBackupFileObject.m
//  iBackupFS
//
//  Created by znek on 05.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import "iBackupFileObject.h"
#import "iBackup.h"

// hack: we know this exists in CoreFoundation
uint32_t _CFKeyedArchiverUIDGetValue(id uid);

@implementation iBackupFileObject

- (id)initWithFileID:(NSString *)_fileID
  fileData:(NSData *)_fileData
  fromBackup:(iBackup *)_backup
{
	self = [self init];
	if (self) {
		self->backup = _backup; // weak ref
		self->fileID = [_fileID retain];

		NSDictionary *fileData =
		  [NSPropertyListSerialization propertyListWithData:_fileData
										options:NSPropertyListImmutable
										format:NULL
									    error:NULL];
		NSUInteger objDictIdx =
		  _CFKeyedArchiverUIDGetValue(fileData[@"$top"][@"root"]);
		NSDictionary *objDict = fileData[@"$objects"][objDictIdx];

		id encryptionKeyUID = objDict[@"EncryptionKey"];
		if (encryptionKeyUID) {
			NSUInteger wrappedKeyDictIdx = _CFKeyedArchiverUIDGetValue(encryptionKeyUID);
			self->wrappedKey = [fileData[@"$objects"][wrappedKeyDictIdx][@"NS.data"] retain];
		}

		self->attrs = [[NSMutableDictionary alloc] initWithCapacity:3];
		NSNumber *timestamp = objDict[@"Birth"];
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
		[self->attrs setObject:date forKey:NSFileCreationDate];
		timestamp = objDict[@"LastModified"];
		date = [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
		[self->attrs setObject:date forKey:NSFileModificationDate];
		[self->attrs setObject:objDict[@"Size"] forKey:NSFileSize];
	}
	return self;
}

- (void)dealloc {
	[self->fileID release];
	[self->wrappedKey release];
	[self->attrs release];
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
- (NSDictionary *)fileAttributes {
	return self->attrs;
}

@end
