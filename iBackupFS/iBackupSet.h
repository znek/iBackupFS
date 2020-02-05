//
//  iBackupSet.h
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class iBackup;

@interface iBackupSet : NSObject
{
	NSString *identifier;
	NSDictionary *info;
	NSMutableDictionary *backupMap;
	iBackup *backup; // just if single backup exists
}

- (id)initWithPath:(NSString *)_path;

- (NSString *)displayName;

@end
