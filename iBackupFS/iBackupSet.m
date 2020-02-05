//
//  iBackupSet.m
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "iBackupSet.h"
#import "NSObject+FUSEOFS.h"
#import "iBackup.h"

@implementation iBackupSet

- (id)initWithPath:(NSString *)_path {
	self = [self init];
	if (self) {
		self->info       = [[NSDictionary dictionaryWithContentsOfFile:[_path stringByAppendingPathComponent:@"Info.plist"]] copy];
		if (self->info == nil)
			return nil; // no backup set
		self->identifier = [[_path lastPathComponent] copy];
		self->backupMap  = [[NSMutableDictionary alloc] init];
		
		
		NSString      *path  = [_path stringByDeletingLastPathComponent];
		NSFileManager *fm    = [NSFileManager defaultManager];
		NSError *err = nil;
		NSArray       *names = [fm contentsOfDirectoryAtPath:path error:&err];
		if (!names) {
			NSLog(@"ERROR: %@", err);
		}
		NSMutableArray *backups = [NSMutableArray array];
		for (NSString *name in names) {
			if ([name rangeOfString:self->identifier].length != 0) {
				NSString *backupPath = [path stringByAppendingPathComponent:name];
				iBackup  *backup     = [[iBackup alloc] initWithPath:backupPath];

				if (backup != nil) {
					[backups addObject:backup];
				}
				else {
					NSLog(@"Ignoring backup '%@'", backupPath);
				}
				[backup release];
			}
		}
		if ([backups count] > 1) {
			for (iBackup *backup in backups) {
				NSString *displayName = [backup displayName];
				[self->backupMap setObject:backup
								 forKey:[displayName properlyEscapedFSRepresentation]];
			}
		}
		else if ([backups count] == 1) {
			self->backup = [backups[0] retain];
			for (NSString *name in [self->backup containerContents]) {
				NSObject *obj = [self->backup lookupPathComponent:name inContext:nil];
				[self->backupMap setObject:obj
								 forKey:[name properlyEscapedFSRepresentation]];
			}
		}
	}
	return self;
}

- (void)dealloc {
	[self->identifier release];
	[self->info       release];
	[self->backupMap  release];
	[self->backup release];
	[super dealloc];
}

- (NSString *)displayName {
	return [self->info valueForKey:@"Display Name"];
}

/* FUSEOFS */

- (id)lookupPathComponent:(NSString *)_pc inContext:(id)_ctx {
	return [self->backupMap lookupPathComponent:_pc inContext:_ctx];
}

- (NSArray *)containerContents {
	return [self->backupMap allKeys];
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

@end
