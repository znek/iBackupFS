//
//  iBackupFileObject.h
//  iBackupFS
//
//  Created by znek on 05.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class iBackup;

@interface iBackupFileObject : NSObject
{
	iBackup *backup; // weak ref
	NSString *fileID;

	NSData *wrappedKey;
}

- (id)initWithFileID:(NSString *)_fileID fromBackup:(iBackup *)_backup;
- (NSString *)fileID;

- (void)setWrappedKey:(NSData *)_wrappedKey;
- (NSData *)wrappedKey;

@end

