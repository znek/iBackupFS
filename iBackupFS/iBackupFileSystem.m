//
//  iBackupFileSystem.m
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "iBackupFileSystem.h"
#import "NSObject+FUSEOFS.h"
#import "iBackupSet.h"

@implementation iBackupFileSystem

static NSString *backupPath = nil;

+ (void)initialize {
	static BOOL didInit = NO;
	if (didInit) return;
	didInit = YES;

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	backupPath = [[ud stringForKey:@"BackupPath"] copy];
	if (!backupPath) {
		backupPath = [[NSHomeDirectory() stringByAppendingString:
					   @"/Library/Application Support/MobileSync/Backup"]
					   copy];
    }
}


/* NSObject(GMUserFileSystemLifecycle) */

- (void)willMount {
	self->backupSetMap = [[NSMutableDictionary alloc] init];

	NSFileManager *fm    = [NSFileManager defaultManager];
	NSArray       *names = [fm contentsOfDirectoryAtPath:backupPath error:NULL];
	for (NSString *name in names) {
		NSString *path = [backupPath stringByAppendingPathComponent:name];
		BOOL isDir;
		if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir) {
			iBackupSet *bs = [[iBackupSet alloc] initWithPath:path];
			if (bs == nil)
				continue;
			[self->backupSetMap setObject:bs
								forKey:[[bs displayName]
											properlyEscapedFSRepresentation]];
			[bs release];
		}
	}
}

- (void)willUnmount {
	[self->backupSetMap release];
	[super willUnmount];
}


/* FUSEOFS */

- (id)lookupPathComponent:(NSString *)_pc inContext:(id)_ctx {
	return [self->backupSetMap lookupPathComponent:_pc inContext:_ctx];
}

- (NSArray *)containerContents {
	return [self->backupSetMap allKeys];
}

- (NSDictionary *)fileSystemAttributes {
	NSMutableDictionary *attrs;
	
	attrs = [[NSMutableDictionary alloc] initWithCapacity:2];
	//    [attrs setObject:defaultSize forKey:NSFileSystemSize];
	[attrs setObject:[NSNumber numberWithInt:0] forKey:NSFileSystemFreeSize];
	return [attrs autorelease];
}

- (BOOL)isContainer {
	return YES;
}


/* optional */

- (BOOL)needsLocalOption {
#ifndef NO_OSX_ADDITIONS
	NSString *osVer = [[NSProcessInfo processInfo] operatingSystemVersionString];
	
	if ([osVer rangeOfString:@"10.4"].length != 0) return NO;
	return YES;
#else
	return NO;
#endif
}

- (BOOL)wantsAllowOtherOption {
	return NO;
}

- (NSArray *)fuseOptions {
	NSMutableArray *os;
	
	os = [[[super fuseOptions] mutableCopy] autorelease];
	
#if 0
	// careful (fuse will be pretty slow when in use)!
	// NOTE: I guess this is obsolete by now, should use dtrace for the
	// purpose of debugging fuse
	[os addObject:@"debug"];
#endif
	
#if 0
	// EXP: use this only for experiments
	[os addObject:@"daemon_timeout=10"];
#endif
	
#ifndef NO_OSX_ADDITIONS
	// TODO: get this from user defaults?
	[os addObject:@"volname=iBackupFS"];
#endif
	
	if ([self wantsAllowOtherOption])
		[os addObject:@"allow_other"];
	
	if ([self needsLocalOption])
		[os addObject:@"local"];
	return os;
}

@end
