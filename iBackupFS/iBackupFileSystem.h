//
//  iBackupFileSystem.h
//  iBackupFS
//
//  Created by Marcus Müller on 29.05.12.
//  Copyright (c) 2012 Mulle kybernetiK. All rights reserved.
//

#import "FUSEObjectFileSystem.h"


@interface iBackupFileSystem : FUSEObjectFileSystem
{
	NSMutableDictionary *backupSetMap;
}

@end /* iBackupFileSystem */
