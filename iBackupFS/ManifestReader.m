//
//  ManifestReader.m
//  iBackupFS
//
//  Created by Marcus Müller on 03.02.20.
//  Copyright (c) 2020 Mulle kybernetiK. All rights reserved.
//

#import "ManifestReader.h"
#import "NSMutableDictionary+iBackupFS.h"
#import "NSString+iBackupFS.h"
#import "iBackup.h"
#import "iBackupObject.h"
#import "Keybag.h"
#import "FUSEOFSFileProxy.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation ManifestReader

- (id)initWithPath:(NSString *)_path {
	self = [self init];
	if (self) {
		self->manifest = [[NSDictionary dictionaryWithContentsOfFile:_path] copy];
		self->path = [[_path stringByDeletingLastPathComponent] copy];
		self->info = [[NSDictionary dictionaryWithContentsOfFile:
					                [self->path stringByAppendingPathComponent:@"Info.plist"]] copy];
		if (!self->manifest || !self->info) {
			[self release];
			return nil;
		}
		self->keybag = [[Keybag alloc] initWithData:[self->manifest objectForKey:@"BackupKeyBag"]];
		self->contentMap = [[NSMutableDictionary alloc] init];

		[self setup];
	}
	return self;
}

- (void)dealloc {
	[self->manifest release];
	[self->info release];
	[self->path release];
	[self->keybag release];
	[self->contentMap release];
	[self->dbPath release];
	[super dealloc];
}

- (BOOL)isEncrypted {
	return [[self->manifest valueForKey:@"IsEncrypted"] boolValue];
}

- (NSString *)dbPath {
	return self->dbPath;
}
- (Keybag *)keybag {
	return self->keybag;
}

- (NSString *)displayName {
	return [self->info valueForKey:@"Display Name"];
}

- (NSString *)password {
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *key = [NSString stringWithFormat:@"%@_Password", [self displayName]];
	return [ud stringForKey:key];
}

- (void)setup {
	if ([self isEncrypted]) {
		NSString *pw = [self password];
		if (!(pw && [pw length] != 0) ||
			![self->keybag unlockWithPassword:pw])
		{
			NSString *infoEncryptedFilePath = [[NSBundle mainBundle] pathForResource:@"Encrypted" ofType:@"md" inDirectory:nil];
			FUSEOFSFileProxy *proxy = [[FUSEOFSFileProxy alloc] initWithPath:infoEncryptedFilePath];
			[self->contentMap addContentObject:proxy path:@"ENCRYPTED BACKUP.md"];
			[proxy release];
			return;
		}

		// unlocked
		NSData *wrappedManifestKey = [self->manifest valueForKey:@"ManifestKey"];
		NSData *manifestKey = [self->keybag unwrapTypedKey:wrappedManifestKey];

		// decrypt Manifest.db
		NSString *dbPath = [self->path stringByAppendingPathComponent:@"Manifest.db"];
		NSData *encDBData = [NSData dataWithContentsOfFile:dbPath];
		NSData *decDBData = [self->keybag decryptData:encDBData withKey:manifestKey];
		self->dbPath = [[self tmpDBPath] retain];
		if (self->dbPath)
			[decDBData writeToFile:self->dbPath atomically:YES];
	}
	else {
		self->dbPath = [[self->path stringByAppendingPathComponent:@"Manifest.db"] retain];
	}

	// open DB etc.
}

- (NSString *)tmpDBPath {
	char secureTmp[] = "/tmp/ibackupfsXXXXXXXXXXXX";
	int  fd = mkstemp(secureTmp);
	if (fd == -1) {
		NSLog(@"Failed to create safe temporary file!");
		return nil;
	}
	close(fd);
	return [NSString stringWithCString:secureTmp
					  encoding:NSASCIIStringEncoding];
}

/* accessors */

- (NSDictionary *)contentMap {
	return (NSDictionary *)self->contentMap;
}

@end
