//
//  Keybag.m
//  iBackupFS
//
//  Created by znek on 03.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import "Keybag.h"

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
	if (self->currentClassKey)
		[self->classKeys setObject:self->currentClassKey
						 forKey:[self->currentClassKey objectForKey:@"CLAS"]];

#if 0
	NSLog(@"attrs:%@", self->attrs);
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
		self->uuid = _obj;
	else if ([_tag isEqualToString:@"WRAP"] && !self->wrap)
		self->wrap = (NSNumber *)_obj;
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

- (BOOL)unlockWithPassword:(NSString *)_password {
	if (!_password || [_password length] == 0)
		return NO;
#if 1
	NSLog(@"unlock with password '%@'!", _password);
#endif
	return NO;
}

@end