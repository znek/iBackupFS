//
//  Keybag.m
//  iBackupFS
//
//  Created by znek on 03.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import "Keybag.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation Keybag

static NSArray *classKeyTags = nil;
static NSArray *keybagTypes  = nil;
static NSArray *keyTypes = nil;
static NSDictionary *protectionClasses = nil;

+ (void)initialize {
	static BOOL didInit = NO;
	if (didInit) return;
	didInit = YES;

	classKeyTags = @[ @"CLAS", @"WRAP", @"WPKY", @"KTYP", @"PBKY" ]; // UUID
	keybagTypes  = @[ @"System", @"Backup", @"Escrow", @"OTA (icloud)" ];
	keyTypes = @[ @"AES", @"Curve25519" ];
	protectionClasses = @{
		 @1 : @"NSFileProtectionComplete",
		 @2 : @"NSFileProtectionCompleteUnlessOpen",
		 @3 : @"NSFileProtectionCompleteUntilFirstUserAuthentication",
		 @4 : @"NSFileProtectionNone",
		 @5 : @"NSFileProtectionRecovery?",
		 @6 : @"kSecAttrAccessibleWhenUnlocked",
		 @7 : @"kSecAttrAccessibleAfterFirstUnlock",
		 @8 : @"kSecAttrAccessibleAlways",
		 @9 : @"kSecAttrAccessibleWhenUnlockedThisDeviceOnly",
		@10 : @"kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly",
		@11 : @"kSecAttrAccessibleAlwaysThisDeviceOnly"
	};
}

- (id)initWithData:(NSData *)_data {
	self = [self init];
	if (!_data || [_data length] == 0)
		return nil;

	self->attrs     = [[NSMutableDictionary alloc] init];
	self->classKeys = [[NSMutableDictionary alloc] init];

	[self parseData:_data];
	return self;
}

- (void)dealloc {
	[super dealloc];
	[self->uuid release];
	[self->wrap release];
	[self->deviceKey release];
	[self->attrs release];
	[self->classKeys release];
}

- (void)parseData:(NSData *)_data {
	char * data = (char *)[_data bytes];
	NSUInteger total = [_data length];
	NSUInteger i   = 0;
	char tag[5];
	tag[4] = '\0';

	while (i + 8 <= total) {
		tag[0] = data[i + 0];
		tag[1] = data[i + 1];
		tag[2] = data[i + 2];
		tag[3] = data[i + 3];

		UInt32 value = *(UInt32 *)(data + 4 + i);
		UInt32 length = NSSwapBigIntToHost(value);
		id obj;
		if (length == 4) {
			value = *(UInt32 *)(data + 8 + i);
			UInt32 num = NSSwapBigIntToHost(value);
			obj = [NSNumber numberWithUnsignedInt:num];
		}
		else {
			obj = [NSData dataWithBytes:data + 8 + i length:length];
		}
		[self handleTag:[NSString stringWithCString:tag encoding:NSASCIIStringEncoding]
			  withObject:obj];
		i += (8 + length);
	}
	if (self->currentClassKey) {
		[self->classKeys setObject:self->currentClassKey
						 forKey:[self->currentClassKey objectForKey:@"CLAS"]];
		self->currentClassKey = nil;
	}

#if 0
	NSLog(@"classKeys:%@", self->classKeys);
#endif
#if 1
	NSLog(@"KeybagType: #%lu (%@)", self->type, [keybagTypes objectAtIndex:self->type]);
#endif
}

- (void)handleTag:(NSString *)_tag withObject:(id)_obj {
#if 0
	NSLog(@"handleTag:%@", _tag);
#endif

	if ([_tag isEqualToString:@"TYPE"]) {
		self->type = [(NSNumber *)_obj unsignedIntegerValue];
		if (self->type > 3)
			NSLog(@"ERROR: keybag type > 3 : %lu", self->type);
	}
	else if ([_tag isEqualToString:@"UUID"] && !self->uuid)
		self->uuid = [_obj retain];
	else if ([_tag isEqualToString:@"WRAP"] && !self->wrap)
		self->wrap = [(NSNumber *)_obj retain];
	else if ([_tag isEqualToString:@"UUID"]) {
		if (self->currentClassKey) {
			[self->classKeys setObject:self->currentClassKey
							 forKey:[self->currentClassKey objectForKey:@"CLAS"]];
		}
		self->currentClassKey = [NSMutableDictionary dictionaryWithObjectsAndKeys:_obj, @"UUID", nil];

	}
	else if ([classKeyTags containsObject:_tag]) {
		[self->currentClassKey setObject:_obj forKey:_tag];
	}
	else {
		[self->attrs setObject:_obj forKey:_tag];
	}
}

#define WRAP_PASSCODE 2

- (BOOL)unlockWithPassword:(NSString *)_password {
	if (!_password || [_password length] == 0)
		return NO;
#if 1
	NSLog(@"unlock with password '%@'!", _password);
#endif

	NSData *salt = self->attrs[@"DPSL"];
	NSNumber *rounds = self->attrs[@"DPIC"];
	NSMutableData *passcode1 = [NSMutableData dataWithLength:32];

	int result = CCKeyDerivationPBKDF(
				   kCCPBKDF2,
				   [_password cString], [_password length],
				   [salt bytes], [salt length],
				   kCCPRFHmacAlgSHA256,
				   [rounds unsignedIntValue],
				   [passcode1 mutableBytes], [passcode1 length]);
	if (result != kCCSuccess) {
		NSLog(@"CCKeyDerivationPBKDF for passcode1 failed with code %d", result);
		return NO;
	}

	salt   = self->attrs[@"SALT"];
	rounds = self->attrs[@"ITER"];
	NSMutableData *passcode_key = [NSMutableData dataWithLength:32];
	result = CCKeyDerivationPBKDF(
			   kCCPBKDF2,
			   [passcode1 bytes], [passcode1 length],
			   [salt bytes], [salt length],
			   kCCPRFHmacAlgSHA1,
			   [rounds unsignedIntValue],
			   [passcode_key mutableBytes], [passcode_key length]);
	if (result != kCCSuccess) {
		NSLog(@"CCKeyDerivationPBKDF for passcode_key failed with code %d", result);
		return NO;
	}

	for (NSMutableDictionary *classKey in [self->classKeys allValues]) {
		NSData *wrappedKey = classKey[@"WPKY"];
		if (!wrappedKey)
			continue;
		NSNumber *classWrap = classKey[@"WRAP"];
		if ([classWrap unsignedIntegerValue] & WRAP_PASSCODE) {
#if 0
			NSLog(@"unwrap class %@", protectionClasses[classKey[@"CLAS"]]);
#endif
			NSUInteger rawKeyLength = CCSymmetricUnwrappedSize(kCCWRAPAES, [wrappedKey length]);
			NSMutableData *rawKey = [NSMutableData dataWithLength:rawKeyLength];
			result = CCSymmetricKeyUnwrap(
					   kCCWRAPAES,
					   CCrfc3394_iv, CCrfc3394_ivLen,
					   [passcode_key bytes], [passcode_key length],
					   [wrappedKey bytes], [wrappedKey length],
					   [rawKey mutableBytes], &rawKeyLength);
			if (result != kCCSuccess) {
				NSLog(@"CCSymmetricKeyUnwrap failed with code %d", result);
				return NO;
			}
			classKey[@"KEY"] = rawKey;
		}
	}
	self->isUnlocked = YES;
	return self->isUnlocked;
}

- (BOOL)isUnlocked {
	return self->isUnlocked;
}

- (NSData *)unwrapKey:(NSData *)_key forClass:(NSNumber *)_protectionClass {
	if (!_key || [_key length] != 40) {
		NSLog(@"Invalid key");
		return nil;
	}
	NSData *classKey = self->classKeys[_protectionClass][@"KEY"];
	NSUInteger rawKeyLength = CCSymmetricUnwrappedSize(kCCWRAPAES, [_key length]);
	NSMutableData *rawKey = [NSMutableData dataWithLength:rawKeyLength];
	int result = CCSymmetricKeyUnwrap(
				   kCCWRAPAES,
				   CCrfc3394_iv, CCrfc3394_ivLen,
				   [classKey bytes], [classKey length],
				   [_key bytes], [_key length],
				   [rawKey mutableBytes], &rawKeyLength);
	if (result != kCCSuccess) {
		NSLog(@"CCSymmetricKeyUnwrap failed with code %d", result);
		return nil;
	}
	return rawKey;
}

- (NSData *)unwrapManifestKey:(NSData *)_manifestKey {
	// manifestKey has its protectionClass prepended!

	UInt32 value = *(UInt32 *)([_manifestKey bytes]);
	UInt32 num = NSSwapLittleIntToHost(value);
	NSNumber *protectionClass = [NSNumber numberWithUnsignedInt:num];
	NSData *key = [_manifestKey subdataWithRange:NSMakeRange(4, [_manifestKey length] - 4)];

	return [self unwrapKey:key forClass:protectionClass];
}

- (NSData *)decryptData:(NSData *)_data withKey:(NSData *)_key {
	CCCryptorRef cryptor;
	int result = CCCryptorCreate(kCCDecrypt,
								 kCCAlgorithmAES,
								 0, /* no padding */
								 [_key bytes], [_key length],
								 NULL, /* IV - use default */
								 &cryptor);
	if (result != kCCSuccess) {
		NSLog(@"CCCryptorCreate failed with code %d", result);
		return nil;
	}
	NSUInteger length = CCCryptorGetOutputLength(cryptor,
												 [_data length],
												 YES);
	NSMutableData *decrypted = [NSMutableData dataWithLength:length];
	result = CCCryptorUpdate(cryptor,
							 [_data bytes], [_data length],
							 [decrypted mutableBytes], [decrypted length],
							 NULL);
	if (result != kCCSuccess) {
		NSLog(@"CCCryptorUpdate failed with code %d", result);
		CCCryptorRelease(cryptor);
		return nil;
	}
	result = CCCryptorFinal(cryptor,
							[decrypted mutableBytes], [decrypted length],
							NULL);
	if (result != kCCSuccess) {
		NSLog(@"CCCryptorFinal failed with code %d", result);
		CCCryptorRelease(cryptor);
		return nil;
	}
	CCCryptorRelease(cryptor);
	return decrypted;
}

- (NSData *)keyForClass:(NSNumber *)_protectionClass {
	return self->classKeys[_protectionClass][@"KEY"];
}

- (NSData *)decryptData:(NSData *)_data ofClass:(NSNumber *)_protectionClass {
	NSData *classKey = [self keyForClass:_protectionClass];
	if (!classKey) {
		NSLog(@"No key for protectionClass:%@ (%@)!",
			  _protectionClass, protectionClasses[_protectionClass]);
		return nil;
	}
	return [self decryptData:_data withKey:classKey];
}

@end
