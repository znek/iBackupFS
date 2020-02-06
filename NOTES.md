# Formats

## New Format

- [iTunes Backup](https://www.theiphonewiki.com/wiki/ITunes_Backup)
  - good overview
- [How to decrypt and *encrypted* iPhone backup](https://stackoverflow.com/questions/1498342/how-to-decrypt-an-encrypted-apple-itunes-iphone-backup)
  - *Excellent* HOWTO / explanation
  - Python code can be copied (almost verbatim!)
- https://www.iphonebackupextractor.com/blog/iphone-backup-location-all-files-extension/
  - excellent reference, can use these to create artificial
    "interesting files" folders
    - via defaults like so?:
	  ```
	  "Groups" = {
	    "Interesting Files" = (
		  "3d0d7e5fb2ce288813306e4d4636395e047a3d28", …
		);
	  };
	  ```
- [Objective-C literals](https://clang.llvm.org/docs/ObjectiveCLiterals.html)
- https://blog.erratasec.com/2020/01/how-to-decrypt-whatsapp-end-to-end.html
  - not sure that's required here, we do have access to the most recent
	unencrypted files in this backup?


### SQLite3

- [FMDB - SQLite3 in ObjC](https://github.com/ccgus/fmdb)
  - Include in build via [Carthage](https://github.com/Carthage/Carthage#installing-carthage)
- [SQLite Database Browser](http://sqlitebrowser.sourceforge.net/)
- [DB Open Flags](http://sqlite.org/c3ref/c_open_autoproxy.html)
  - `#define SQLITE_OPEN_READONLY         0x00000001  /* Ok for sqlite3_open_v2() */`


## MbdbMbdxFormat

- [MbdbMbdxFormat](http://code.google.com/p/iphonebackupbrowser/wiki/MbdbMbdxFormat)
  - Important : all numbers are big endian.

```
MBDB
header
  uint8[6]    'mbdb\5\0'

record (variable size)
  string     Domain
  string     Path
  string     LinkTarget          absolute path
  string     DataHash            SHA.1 (some files only)
  string     unknown             always N/A
  uint16     Mode                same as mbdx.Mode
  uint32     unknown             always 0
  uint32     unknown             
  uint32     UserId
  uint32     GroupId             mostly 501 for apps
  uint32     Time1               relative to unix epoch (e.g time_t)
  uint32     Time2               Time1 or Time2 is the former ModificationTime
  uint32     Time3
  uint64     FileLength          always 0 for link or directory
  uint8      Flag                0 if special (link, directory), otherwise unknown
  uint8      PropertyCount       number of properties following
Property is a couple of strings:

  string      name
  string      value               can be a string or a binary content

A string is composed of a uint16 that contains the length in bytes or 0xFFFF (for null or N/A) then the characters, in UTF-8 with canonical decomposition (Unicode normalization form D).


Mode:
                 Axxx  symbolic link
                 4xxx  directory
                 8xxx  regular file
```

