//
//  NSMutableDictionary+iBackupFS.h
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (iBackupFS)

- (void)addContentObject:(id)_obj path:(NSString *)_path;

@end
