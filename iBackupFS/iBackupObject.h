//
//  iBackupObject.h
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iBackupObject : NSObject
{
	NSString *path;
	BOOL isContainer;
}

- (id)initWithPath:(NSString *)_path;

@end
