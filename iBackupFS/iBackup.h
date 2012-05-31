//
//  iBackup.h
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iBackup : NSObject
{
	NSString *path;
	NSDictionary *info;
	NSMutableDictionary *contentMap;
	BOOL isCurrent;
	BOOL needsSetup;
}

+ (NSString *)properPathFromDomain:(NSString *)_domain relativePath:(NSString *)_path;

- (id)initWithPath:(NSString *)_path;

- (NSString *)displayName;

@end
