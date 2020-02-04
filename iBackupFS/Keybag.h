//
//  Keybag.h
//  iBackupFS
//
//  Created by znek on 03.02.20.
//  Copyright © 2020 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Keybag : NSObject
{
	NSUInteger type;
	NSData *uuid;
	NSNumber *wrap;
	NSData *deviceKey;
	NSMutableDictionary *attrs;
	NSMutableDictionary *classKeys;
	NSMutableDictionary *currentClassKey;
}

- (id)initWithData:(NSData *)_data;

- (BOOL)unlockWithPassword:(NSString *)_password;

@end
