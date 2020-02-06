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
	NSMutableDictionary *attrs;
}

- (id)initWithFileID:(NSString *)_fileID fileData:(NSData *)_file fromBackup:(iBackup *)_backup;

- (NSString *)fileID;
- (NSData *)wrappedKey;

@end

