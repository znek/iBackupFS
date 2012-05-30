//
//  iBackup.m
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "iBackup.h"
#import "NSObject+FUSEOFS.h"
#import "NSMutableDictionary+iBackupFS.h"
#import "iBackupObject.h"
#import "MBDBReader.h"

@interface iBackup (Private)
- (void)_setupOnce;
- (void)_setup;
- (void)_setupVersion2;
- (void)_setupVersion3;
@end

@implementation iBackup

static NSMutableDictionary *replaceMap = nil;

+ (void)initialize {
	static BOOL didInit = NO;
	if (didInit) return;
	didInit = YES;

	replaceMap = [[NSMutableDictionary alloc] init];
	[replaceMap setObject:@"Applications/" forKey:@"AppDomain-"];
	[replaceMap setObject:@"Camera" forKey:@"CameraRollDomain"];
	[replaceMap setObject:@"Home" forKey:@"HomeDomain"];
	[replaceMap setObject:@"Keychains" forKey:@"KeychainDomain"];
	[replaceMap setObject:@"Media" forKey:@"MediaDomain"];
	[replaceMap setObject:@"Mobile Device" forKey:@"MobileDeviceDomain"];
	[replaceMap setObject:@"Root" forKey:@"RootDomain"];
	[replaceMap setObject:@"Preferences" forKey:@"SystemPreferencesDomain"];
	[replaceMap setObject:@"Wireless" forKey:@"WirelessDomain"];
}

+ (NSString *)properPathFromDomain:(NSString *)_domain relativePath:(NSString *)_path {
	NSString *path = nil;

	if (_domain) {
		path = [[_domain copy] autorelease];
	
		for (NSString *key in [replaceMap allKeys]) {
			NSRange r = [_domain rangeOfString:key];
			if (r.location != NSNotFound) {
				path = [replaceMap objectForKey:key];
				path = [path stringByAppendingString:[_domain substringFromIndex:NSMaxRange(r)]];
				break;
			}
		}
		if (_path)
			path = [path stringByAppendingPathComponent:_path];
	}
	else {
		path = [[_path copy] autorelease];
	}
	return path;
}

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
	if ([fm fileExistsAtPath:[self->path stringByAppendingPathComponent:@"Manifest.mbdb"]]) {
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
				NSString *objPath = [self->path stringByAppendingPathComponent:
									            [[name stringByDeletingPathExtension]
												       stringByAppendingPathExtension:@"mddata"]];
				iBackupObject *obj = [[iBackupObject alloc] initWithPath:objPath];
				
				NSString *domain = [metaInfo objectForKey:@"Domain"];

				[self->contentMap addContentObject:obj
								  path:[[self class] properPathFromDomain:domain
													 relativePath:contentPath]];
				[obj release];
			}
		}
		else if ([name hasSuffix:@"mdbackup"]) {
			NSString     *metaPath    = [self->path stringByAppendingPathComponent:name];
			NSDictionary *metaInfo    = [NSDictionary dictionaryWithContentsOfFile:metaPath];
			NSString     *contentPath = [metaInfo objectForKey:@"Path"];
			if (contentPath) {
				NSString *domain = [metaInfo objectForKey:@"Domain"];
				
				[self->contentMap addContentObject:[metaInfo objectForKey:@"Data"]
					              path:[[self class] properPathFromDomain:domain
													 relativePath:contentPath]];
			}
		}
	}
}

- (void)_setupVersion3 {
	NSString   *mbdbPath   = [self->path stringByAppendingPathComponent:@"Manifest.mbdb"];
	MBDBReader *mbdbReader = [[MBDBReader alloc] initWithPath:mbdbPath];
	[self->contentMap addEntriesFromDictionary:[mbdbReader contentMap]];
	[MBDBReader release];
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
