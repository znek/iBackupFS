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
#import "ManifestReader.h"
#import "iBackupFileObject.h"
#import "Keybag.h"
#import <FMDB/FMDB.h>

@interface iBackup (Private)
- (void)_setupOnce;
- (void)_setup;
- (void)_setupVersion2;
- (void)_setupVersion3;
@end

@implementation iBackup

static NSDictionary *replaceMap = nil;
static BOOL showFileID = NO;

+ (void)initialize {
	static BOOL didInit = NO;
	if (didInit) return;
	didInit = YES;

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	showFileID = [ud boolForKey:@"ShowFileID"];
	replaceMap = [[ud dictionaryForKey:@"ReplaceMap"] retain];
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
		self->path       = [_path copy];
		self->info       = [[NSDictionary dictionaryWithContentsOfFile:[_path stringByAppendingPathComponent:@"Info.plist"]] copy];
		self->contentMap = [[NSMutableDictionary alloc] init];
		self->isCurrent  = [_path rangeOfString:@"-"].location == NSNotFound;
		self->needsSetup = YES;
	}
	return self;
}

- (void)dealloc {
	[self cleanup];
	[self->path release];
	[self->info release];
	[self->contentMap release];

	[self->keybag release];
	[self->dbPath release];

	[super dealloc];
}

- (void)cleanup {
	if (self->dbPath && self->keybag) {
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm removeItemAtPath:self->dbPath error:NULL];
		[fm removeItemAtPath:[self->dbPath stringByAppendingString:@"-shm"]
			error:NULL];
		[fm removeItemAtPath:[self->dbPath stringByAppendingString:@"-wal"]
			error:NULL];
	}
}

- (void)_setupOnce {
	if (!self->needsSetup) return;
	[self _setup];
	self->needsSetup = NO;
}

- (void)_setup {
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[self->path stringByAppendingPathComponent:@"Manifest.db"]]) {
		[self _setupVersion4];
	}
	else
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
				metaInfo = [NSPropertyListSerialization propertyListWithData:metaData
														options:NSPropertyListImmutable
														format:NULL
														error:NULL];
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
	NSString   *dbPath = [self->path stringByAppendingPathComponent:@"Manifest.mbdb"];
	MBDBReader *reader = [[MBDBReader alloc] initWithPath:dbPath];
	[self->contentMap addEntriesFromDictionary:[reader contentMap]];
	[reader release];
}

- (void)addFileObject:(iBackupFileObject *)_obj path:(NSString *)_path {
	if (showFileID) {
		NSString *suffix = [_path lastPathComponent];
		_path = [_path stringByDeletingLastPathComponent];
		_path = [_path stringByAppendingFormat:@"/[%@] %@",
											    [_obj fileID], suffix, nil];
	}
	[self->contentMap addContentObject:_obj path:_path];
}

- (void)_setupVersion4 {
	NSString *plistPath = [self->path stringByAppendingPathComponent:@"Manifest.plist"];
	ManifestReader *reader = [[ManifestReader alloc] initWithPath:plistPath];

	self->dbPath = [[reader dbPath] retain];
	if ([reader isEncrypted]) {
		self->keybag = [[reader keybag] retain];
	}

	if (self->dbPath && (!self->keybag ||
						 (self->keybag && [self->keybag isUnlocked])))
	{
		FMDatabase *db = [FMDatabase databaseWithPath:self->dbPath];
		if (![db open]) {
			NSLog(@"Couldn't open DB at '%@'?!", self->dbPath);
			[reader release];
			return;
		}

		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		if ([ud boolForKey:@"UseGroups"] ||
			[ud boolForKey:@"UseGroupsOnly"])
		{
			NSDictionary *specialGroups = [ud dictionaryForKey:@"Groups"];
			for (NSString *groupPath in [specialGroups allKeys]) {
				NSArray *fileIDs = [specialGroups objectForKey:groupPath];
				for (NSString *fileID in fileIDs) {
					FMResultSet *results = [db executeQuery:@"SELECT relativePath, file FROM Files WHERE fileID=?", fileID, nil];
					while([results next]) {
						NSString *relPath = [results stringForColumnIndex:0];
						NSData *fileData  = [results dataNoCopyForColumnIndex:1];
						iBackupFileObject *obj = [[iBackupFileObject alloc]
																	  initWithFileID:fileID
																	  fileData:fileData
																	  fromBackup:self];
						NSString *path = [groupPath stringByAppendingPathComponent:[relPath lastPathComponent]];
						[self addFileObject:obj path:path];
					}
				}
			}
		}
		if (![ud boolForKey:@"UseGroupsOnly"]) {
			// flags: 1 == Files
			FMResultSet *results = [db executeQuery:@"SELECT domain, relativePath, fileID, file FROM Files WHERE flags = 1", nil];
			while ([results next]) {
				NSString *domain  = [results stringForColumnIndex:0];
				NSString *relPath = [results stringForColumnIndex:1];
				NSString *fileID  = [results stringForColumnIndex:2];
				NSData *fileData  = [results dataNoCopyForColumnIndex:3];
				iBackupFileObject *obj = [[iBackupFileObject alloc]
															  initWithFileID:fileID
															  fileData:fileData
															  fromBackup:self];
				NSString *path = [[self class]
										properPathFromDomain:domain
										relativePath:relPath];
				[self addFileObject:obj path:path];
			}
		}
		[db close];
	}

	// just in case
	[self->contentMap addEntriesFromDictionary:[reader contentMap]];
	[reader release];
}

- (NSString *)displayName {
	NSString *name = [self->info valueForKey:@"Display Name"];
	if (name)
		return name;
	NSDate *d = [self->info valueForKey:@"Last Backup Date"];
	NSCalendarDate *date = [d dateWithCalendarFormat:@"%Y%m%d-%H%M%S"
							  timeZone:[NSTimeZone localTimeZone]];
	return [date description];
}

- (NSData *)contentsOfHashedObject:(iBackupFileObject *)_obj {
	NSMutableString *objPath = [self->path mutableCopy];
	[objPath appendString:@"/"];
	[objPath appendString:[[_obj fileID] substringToIndex:2]];
	[objPath appendString:@"/"];
	[objPath appendString:[_obj fileID]];
	NSData *data = [NSData dataWithContentsOfFile:objPath];
	[objPath release];

	if (self->keybag) {
		NSData *key = [self->keybag unwrapTypedKey:[_obj wrappedKey]];
		data = [self->keybag decryptData:data withKey:key];
	}
	return data;
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

- (NSDictionary *)finderAttributes {
	if (!self->isCurrent)
		return [super finderAttributes];

	enum {
		kFinderLabelColorGrey   = 0x02,
		kFinderLabelColorGreen  = 0x04,
		kFinderLabelColorPurple = 0x06,
		kFinderLabelColorBlue   = 0x08,
		kFinderLabelColorYellow = 0x0A,
		kFinderLabelColorRed    = 0x0C,
		kFinderLabelColorOrange = 0x0E
	};

	NSNumber *finderFlags = [NSNumber numberWithShort:kFinderLabelColorGreen];
	return [NSDictionary dictionaryWithObject:finderFlags
						 forKey:kGMUserFileSystemFinderFlagsKey];
}

@end
