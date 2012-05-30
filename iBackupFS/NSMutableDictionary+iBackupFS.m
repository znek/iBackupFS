//
//  NSMutableDictionary+iBackupFS.m
//  iBackupFS
//
//  Created by Marcus Müller on 30.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "NSMutableDictionary+iBackupFS.h"

@implementation NSMutableDictionary (iBackupFS)

- (void)addContentObject:(id)_obj path:(NSString *)_path {
	NSArray *components = [_path componentsSeparatedByString:@"/"];
	NSUInteger i, count = [components count];
	NSMutableDictionary *current = self;

	for (i = 0; i < (count - 1); i++) {
		NSString *pc = [components objectAtIndex:i];
		NSMutableDictionary *next = [current objectForKey:pc];
		if (![next isKindOfClass:[NSMutableDictionary class]])
			next = nil;
		if (!next) {
			next = [[NSMutableDictionary alloc] init];
			[current setObject:next forKey:pc];
			[next release];
		}
		current = next;
	}
	[current setObject:_obj forKey:[components lastObject]];
}

@end
