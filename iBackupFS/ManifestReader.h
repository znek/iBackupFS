//
//  ManifestReader.h
//  iBackupFS
//
//  Created by Marcus Müller on 03.02.20.
//  Copyright (c) 2020 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Keybag;

@interface ManifestReader : NSObject
{
	NSString     *path;
	NSDictionary *manifest;
	NSDictionary *info;
	Keybag *keybag;
	NSString *dbPath;
	NSMutableDictionary *contentMap;
}

- (id)initWithPath:(NSString *)_path;

- (BOOL)isEncrypted;
- (Keybag *)keybag;
- (NSString *)dbPath;

- (NSDictionary *)contentMap;

@end
