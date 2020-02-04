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
	[super dealloc];
}

- (NSString *)displayName {
	return [self->info valueForKey:@"Display Name"];
}

- (BOOL)isEncrypted {
	return [[self->manifest valueForKey:@"IsEncrypted"] boolValue];
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
		[self->keybag unlockWithPassword:pw];
	}
}

/* accessors */

- (NSDictionary *)contentMap {
	return (NSDictionary *)self->contentMap;
}

@end
