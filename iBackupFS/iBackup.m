//
//  iBackup.m
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "iBackup.h"
#import "NSObject+FUSEOFS.h"
#import "iBackupObject.h"

@interface iBackup (Private)
- (void)_setupOnce;
- (void)_setup;
- (void)_setupVersion2;
- (void)_setupVersion3;
- (void)_addContentObject:(id)_obj path:(NSString *)_path;
@end

@implementation iBackup

- (id)initWithPath:(NSString *)_path {
	self = [self init];
	if (self) {
		self->needsSetup = YES;
		self->path       = [_path copy];
		self->info       = [[NSDictionary dictionaryWithContentsOfFile:[_path stringByAppendingPathComponent:@"Info.plist"]] copy];
		self->contentMap = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self->path release];
	[self->info release];
	[self->contentMap release];
	[super dealloc];
}

- (void)_setupOnce {
	if (!self->needsSetup) return;
	[self _setup];
	self->needsSetup = NO;
}

- (void)_setup {
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[self->path stringByAppendingPathComponent:@"Manifest.mdbd"]]) {
		[self _setupVersion3];
	}
	else {
		[self _setupVersion2];
	}
}

- (void)_setupVersion2 {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray       *names = [fm contentsOfDirectoryAtPath:self->path error:NULL];
	for (NSString *name in names) {
		if ([name hasSuffix:@"mdinfo"]) {
			NSString     *metaPath = [self->path stringByAppendingPathComponent:name];
			NSDictionary *metaInfo = [NSDictionary dictionaryWithContentsOfFile:metaPath];
			NSData       *metaData = [metaInfo objectForKey:@"Metadata"];
			if (metaData) {
				metaInfo = [NSPropertyListSerialization propertyListFromData:metaData
														mutabilityOption:NSPropertyListImmutable
														format:NULL
														errorDescription:NULL]; 
			}
			
			NSString *contentPath = [metaInfo objectForKey:@"Path"];
			if (contentPath) {
				// old format
				NSString *objPath = [self->path stringByAppendingPathComponent:
									            [[name stringByDeletingPathExtension]
												       stringByAppendingPathExtension:@"mddata"]];
				iBackupObject *obj = [[iBackupObject alloc] initWithPath:objPath];
				[self _addContentObject:obj path:contentPath];
				[obj release];
			}
		}
		else if ([name hasSuffix:@"mdbackup"]) {
			NSString     *metaPath    = [self->path stringByAppendingPathComponent:name];
			NSDictionary *metaInfo    = [NSDictionary dictionaryWithContentsOfFile:metaPath];
			NSString     *contentPath = [metaInfo objectForKey:@"Path"];
			if (contentPath) {
				[self _addContentObject:[metaInfo objectForKey:@"Data"]
					  path:contentPath];
			}
		}
	}
}

- (void)_setupVersion3 {
}

- (void)_addContentObject:(id)_obj path:(NSString *)_path {
	NSArray *components = [_path componentsSeparatedByString:@"/"];
	NSUInteger i, count = [components count];
	NSMutableDictionary *current = self->contentMap;

	for (i = 0; i < (count - 1); i++) {
		NSString *pc = [components objectAtIndex:i];
		NSMutableDictionary *next = [current objectForKey:pc];
		if (!next) {
			next = [[NSMutableDictionary alloc] init];
			[current setObject:next forKey:pc];
			[next release];
		}
		current = next;
	}
	[current setObject:_obj forKey:[components lastObject]];
}

- (NSString *)displayName {
	return [[self->info valueForKey:@"Last Backup Date"] description];
}

/* FUSEOFS */

- (id)lookupPathComponent:(NSString *)_pc inContext:(id)_ctx {
	[self _setupOnce];
	return [self->contentMap lookupPathComponent:_pc inContext:_ctx];
}

- (NSArray *)containerContents {
	[self _setupOnce];
	return [self->contentMap allKeys];
}

- (BOOL)isContainer {
	return YES;
}

@end
