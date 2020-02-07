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

- Xcode
  - I used Xcode 11.3.1, but earlier versions might also work
- [Carthage](https://github.com/Carthage/Carthage)
  - Once installed, everything should work out-of-the-box as Carthage is
    integrated into the build process via a script phase
- [macFUSE](http://osxfuse.github.com/)

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
user defaults.

### Builtin customization via user defaults

  Default         | Type           | Purpose
| --------------- | ---------------| -------
| `BackupPath`    | `BOOL`         | Complete path to the `Backup` directory. Useful for testing purposes (if you don't want to deal with _Full Disk Access Security_ all the time).
| `ReplaceMap`    | `NSDictionary` | Used to map device specific "domains" to folders. See [iBackupFS-Info.plist](iBackupFS/iBackupFS-Info.plist) for examples.
| `ShowFileID`    | `BOOL`         | Prepends file names with their corresponding `fileID`. Useful if you need these for inclusion in a smart group.
| `UseGroups`     | `BOOL`         | Decide whether to use smart groups at all.
| `UseGroupsOnly` | `BOOL`         | Decide whether to use only smart groups.
| `Groups`        | `NSDictionary` | See below.

### Groups

Groups are a dictionary of _virtual_ paths, whose contents are either mapped
from lists of `fileID` or from database _WHERE CLAUSES_ (according to the
scheme of the underlying `Manifest.db` [SQLite](https://www.sqlite.org/)
database). See [iBackupFS-Info.plist](iBackupFS/iBackupFS-Info.plist) for
examples.

# References

- [macFUSE](http://osxfuse.github.com/)
- [Filesystem in Userspace (FUSE)](https://en.wikipedia.org/wiki/Filesystem_in_Userspace)
- [SQLite](https://www.sqlite.org/)
- [Carthage](https://github.com/Carthage/Carthage)
- [FMDB](https://github.com/ccgus/fmdb)
