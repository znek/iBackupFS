//
//  MBDBReader.h
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBDBReader : NSObject
{
	NSString     *path;
	NSFileHandle *fh;
	unsigned long long size;
	NSMutableDictionary *contentMap;
}

- (id)initWithPath:(NSString *)_path;

- (NSDictionary *)contentMap;

@end
