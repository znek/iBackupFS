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
	NSMutableDictionary *contentMap;
}

- (id)initWithPath:(NSString *)_path;

- (NSDictionary *)contentMap;

@end
