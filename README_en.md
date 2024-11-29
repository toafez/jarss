English | [Deutsch](README.md)

# jarss (just another rsync shell script)
**jarss** uses **rsync** to transfer data between local paths or paths accessible over the network using **SSH public key authentication**. In addition to **synchronised** backups, jarss also supports **incremental** backups. 

## This is how jarss works
- ### Synchronised backup
    The first time a synchronised backup is run, all source data is transferred to the target directory. For all subsequent runs, only the source data that has been changed, added or deleted in the meantime is compared with the target directory and transferred accordingly. To prevent possible data loss, all deleted data from the source(s) in the target can be moved to a recycle bin with the directory name @recycle for a pre-defined period of time. The data will only be irrevocably deleted after this period has elapsed.

- ### Incremental backup
    The first time an incremental backup is run, all the source data in a subdirectory named after the date and time of the current backup is transferred to the desired destination directory. Immediately afterwards, an image of the current backup is created using symlinks to the usually invisible ~latest folder, which is also in the destination directory.

    During the next and all subsequent runs, the source data is always compared with the most recent image (~latest) of the previous backup. A new subdirectory is then created in the destination directory with the name of the current backup date and time, but this time only any source data that has been changed or added in the meantime is transferred; source data that has been deleted in the meantime is not taken into account. Unchanged source data is only given a reference (known as a hard link) in the target to the data already present in the image and is therefore not transferred again. This gives the impression that each newly created version contains the entire current dataset and the associated storage space, although the actual storage space requirement is limited to the changes since the last backup.

    To limit the number of versions, they can be automatically deleted after a pre-defined number of days.

## Other features of jarss
- CLI-based shell script, therefore probably (after individual testing) executable on most unix-like operating systems.
- Although jarss should preferably be run as root or via sudo, it is also possible to run it as a user, albeit with certain limitations.
- In addition to backing up local paths, paths to or from remote servers can also be backed up using pre-configured SSH public key authentication.
- The optional speed limit of rsync is disabled once the ionice program has been localised by jarss. ionice is able to optimise the high read and write load normally caused by the rsync process in such a way that the availability of the local system and the remote servers involved in this process is guaranteed at all times.
- JARSS uses both synchronous and incremental backups supported by rsync, with incremental backups using a combination of hardlinks and symlinks to link files and directories across file system boundaries.
- JARSS displays detailed information about the current progress of the backup via the terminal during execution, while also creating a detailed log for later review.

## Installation instructions
Download the [ZIP file](https://github.com/toafez/jarss/archive/refs/heads/main.zip) and unzip it. Copy the /scripts directory to a location of your choice, renaming the directory if necessary. If you have not already done so, open a terminal window, change to the directory mentioned above and give the script file jarss.sh execute permissions with

`chmod +x jarss.sh` or `sudo chmod +x jarss.sh`.

Then open one of the two configuration files jarss_Konfiguration_GER (in German) or jarss_Configuration_ENU (in English) in an editor of your choice and fill in the values according to the enclosed help instructions. When you are finished, save the configuration file and, if necessary, give it a unique name, ideally one that allows you to identify the type of backup. A file extension is not required, but can be used if desired. Invalid characters for file and directory names are ~ ' # % & * : < > ? / \ { | }

## Calling the execution script and the configuration file
jarss obtains its information for performing a backup from a separately created configuration file, the name of which is arbitrary and has no defined extension. In this way it is possible to create and run several different configurations for different tasks. It is only necessary to ensure that the jarss execution script and the configuration file(s) are in the same directory. The script is best invoked with the absolute path prefixed, although the relative path will suffice if you are in the same directory as the script and the configuration file(s).

```bash /[ABSOLUTE-PATH-TO-SCRIPT]/jarss.sh --job-name="[FILENAME]" [--info=progress2] [--dry-run] [-v] [-vv] [-vvv]```

```
--job-name="[FILENAME]"     Enter the filename of this job to run the backup.
                            Example: --job-name="[jarss_Configuration_ENU]"
                            
Optional functions
    --info=progress2        Displays information about the overall progress of the file transfer.
    --dry-run               Rsync only simulates what would happen if no data were copied or synchronised.
    -v                      Short rsync protocol, which files will be transferred.
    -vv                     Extended rsync protocol, which files are skipped.
    -vvv                    Very long rsync log for debugging.
```

## Licence
This is free software. You can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation; either version 3** of the licence, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**, even **without the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE**. See the [GNU General Public Licence](LICENSE) file for details.
