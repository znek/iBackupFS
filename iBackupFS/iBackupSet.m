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
		for (NSString *name in names) {
			if ([name rangeOfString:self->identifier].length != 0) {
				NSString *backupPath = [path stringByAppendingPathComponent:name];
				iBackup  *backup     = [[iBackup alloc] initWithPath:backupPath];

				NSUInteger i = [name rangeOfString:@"-"].location;
				NSString *key = (i == NSNotFound) ? [backup displayName]
				                                  : [name substringFromIndex:i + 1];

				if (key != nil) {
					NSLog(@"Adding backup '%@'", key);
					[self->backupMap setObject:backup
									forKey:[key properlyEscapedFSRepresentation]];
				}
				else {
					NSLog(@"Ignoring backup '%@'", backupPath);
				}
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
