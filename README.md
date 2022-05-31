# iBackupFS

iBackupFS is a [FUSEOFS](FUSEOFS/README.md) based filesystem representation
of your
[iTunes device backups](https://support.apple.com/en-us/HT203977#computer).
As a filesystem it can provide alternative views on the backuped data
including on-the-fly decryption, alternative directory graphs and
"smart folders", aggregating special files of interest into groups.

You can use it to backup otherwise unreachable content like your
[WhatsApp chats](https://www.heise.de/newsticker/meldung/Kein-Chatverlauf-Export-mehr-bei-WhatsApp-4627621.html)
or to inspect the contents of files you normally don't get to see on your
device(s).

## Building Requirements

- [Xcode](https://developer.apple.com/xcode/)
  - I used [Xcode 11.3.1](https://developer.apple.com/documentation/xcode_release_notes/xcode_11_3_1_release_notes?language=objc),
    but earlier versions might also work
- [Carthage](https://github.com/Carthage/Carthage)
  - Once installed, everything should work out-of-the-box as Carthage is
    integrated into the build process via a script phase
- [macFUSE](http://osxfuse.github.io/)

## First Run

In order to access the backups, on macOS 10.14 and later iBackupFS needs to be
granted [Full Disk Access](https://support.apple.com/guide/mac-help/change-privacy-preferences-on-mac-mh32356/mac) permission.
As a convenience, iBackupFS will open the appropriate preference pane for you
in case it's necessary.

## Encrypted Backups

Encrypted backups need a password for decryption. The password has to be put
in a user default formed from the device's name and the string `_Password`.
Example: if your device is named "iPhone", then the default key for its
password is `iPhone_Password`.

## Customization

Customization can be achieved, apart from modifying the code, by providing
[user defaults](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/AboutPreferenceDomains/AboutPreferenceDomains.html).

### Builtin customization via user defaults

  Default         | Type         | Purpose
| --------------- | -------------| -------
| `BackupPath`    | `String`     | Complete path to the `Backup` directory. Useful for testing purposes (if you don't want to deal with _Full Disk Access Security_ all the time).
| `ReplaceMap`    | `Dictionary` | Used to map device specific "domains" to folders. See [iBackupFS-Info.plist](iBackupFS/iBackupFS-Info.plist) for examples.
| `ShowFileID`    | `BOOL`       | Prepends file names with their corresponding `fileID`. Useful if you need these for inclusion in a smart group.
| `UseGroups`     | `BOOL`       | Decide whether to use smart groups at all.
| `UseGroupsOnly` | `BOOL`       | Decide whether to use only smart groups.
| `Groups`        | `Dictionary` | See below.

### Groups

Groups are a dictionary of _virtual_ paths, whose contents are either mapped
from lists of `fileID` or from database _WHERE CLAUSES_ (according to the
scheme of the underlying `Manifest.db` [SQLite](https://www.sqlite.org/)
database). See [iBackupFS-Info.plist](iBackupFS/iBackupFS-Info.plist) for
examples.

## Thanks

Of course, thanks go to Benjamin Fleischer of
[macFUSE](http://osxfuse.github.io/) for still investing time into this
great project.
Thanks must also go to the maintainers of
[The iPhone Wiki](https://www.theiphonewiki.com), specifially to the
[iTunes Backup](https://www.theiphonewiki.com/wiki/ITunes_Backup) page.
The most valuable resource, once again (like often times) was
[Stackoverflow](https://stackoverflow.com/) - specifically the post by
[Andrew Neitsch](https://stackoverflow.com/users/14558/andrewdotn) at
[How to decrypt an *encrypted* iPhone backup](https://stackoverflow.com/questions/1498342/how-to-decrypt-an-encrypted-apple-itunes-iphone-backup).
Almost all the code in [Keybag](iBackupFS/Keybag.m) is a direct port
from the posted Python code to Objective-C.
[Carthage](https://github.com/Carthage/Carthage) is really helpful and
without [FMDB](https://github.com/ccgus/fmdb) I'd have to write a
[SQLite](https://www.sqlite.org/) wrapper myself, so thanks for saving me
some time! ;-)

## References

- [User Defaults](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/AboutPreferenceDomains/AboutPreferenceDomains.html)
- [macFUSE](http://osxfuse.github.io/)
- [Filesystem in Userspace (FUSE)](https://en.wikipedia.org/wiki/Filesystem_in_Userspace)
- [Carthage](https://github.com/Carthage/Carthage)
- [FMDB](https://github.com/ccgus/fmdb)
- [SQLite](https://www.sqlite.org/)
