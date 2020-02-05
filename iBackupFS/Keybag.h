//
//  Keybag.h
//  iBackupFS
//
//  Created by znek on 03.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//
// This is a pretty straightforward port from Python to ObjC
// according to the article posted at:
// https://stackoverflow.com/questions/1498342/how-to-decrypt-an-encrypted-apple-itunes-iphone-backup

#import <Foundation/Foundation.h>

@interface Keybag : NSObject
{
	BOOL isUnlocked;
	NSUInteger type;
	NSData *uuid;
	NSNumber *wrap;
	NSData *deviceKey;
	NSMutableDictionary *attrs;
	NSMutableDictionary *classKeys;
	NSMutableDictionary *currentClassKey; // transient
}

- (id)initWithData:(NSData *)_data;

- (BOOL)unlockWithPassword:(NSString *)_password;
- (BOOL)isUnlocked;

- (NSData *)unwrapManifestKey:(NSData *)_manifestKey;
- (NSData *)keyForClass:(NSNumber *)_protectionClass;

- (NSData *)decryptData:(NSData *)_data ofClass:(NSNumber *)_protectionClass;
- (NSData *)decryptData:(NSData *)_data withKey:(NSData *)_key;

@end
