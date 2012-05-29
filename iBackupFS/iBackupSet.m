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
		self->identifier = [[_path lastPathComponent] copy];
		self->info       = [[NSDictionary dictionaryWithContentsOfFile:[_path stringByAppendingPathComponent:@"Info.plist"]] copy];
		self->backupMap  = [[NSMutableDictionary alloc] init];
		
		
		NSString      *path  = [_path stringByDeletingLastPathComponent];
		NSFileManager *fm    = [NSFileManager defaultManager];
		NSArray       *names = [fm contentsOfDirectoryAtPath:path error:NULL];
		for (NSString *name in names) {
			if ([name rangeOfString:self->identifier].length != 0) {
				NSString *backupPath = [path stringByAppendingPathComponent:name];
				iBackup  *backup     = [[iBackup alloc] initWithPath:backupPath];

				NSUInteger i = [name rangeOfString:@"-"].location;
				NSString *key = (i == NSNotFound) ? [backup displayName]
				                                  : [name substringFromIndex:i + 1];
				
				[self->backupMap setObject:backup
								 forKey:[key properlyEscapedFSRepresentation]];
				[backup release];
			}
		}
	}
	return self;
}

- (void)dealloc {
	[self->identifier release];
	[self->info       release];
	[self->backupMap  release];
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
