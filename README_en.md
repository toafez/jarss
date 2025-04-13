English | [Deutsch](README.md)

# jarss (just another rsync shell script)

**jarss** is a CLI-based shell script that uses **rsync** to transfer data between local paths or paths accessible over the network using **SSH public key authentication**. In addition to **synchronised** backups, jarss also supports **incremental** backups.

## This is how jarss works
- ### Synchronised backup
    The first time a synchronised backup is run, all source data is transferred to the target directory. For all subsequent runs, only the source data that has been changed, added or deleted in the meantime is compared with the target directory and transferred accordingly. To prevent possible data loss, all deleted data from the source(s) in the target can be moved to a recycle bin with the directory name @recycle for a pre-defined period of time. The data will only be irrevocably deleted after this period has elapsed.

- ### Incremental backup
    The first time an incremental backup is run, all the source data in a subdirectory named after the date and time of the current backup is transferred to the desired destination directory. Immediately afterwards, an image of the current backup is created using symlinks to the usually invisible ~latest folder, which is also in the destination directory.

    During the next and all subsequent runs, the source data is always compared with the most recent image (~latest) of the previous backup. A new subdirectory is then created in the destination directory with the name of the current backup date and time, but this time only any source data that has been changed or added in the meantime is transferred; source data that has been deleted in the meantime is not taken into account. Unchanged source data is only given a reference (known as a hard link) in the target to the data already present in the image and is therefore not transferred again. This gives the impression that each newly created version contains the entire current dataset and the associated storage space, although the actual storage space requirement is limited to the changes since the last backup.

    To limit the number of versions, they can be automatically deleted after a pre-defined number of days.

## Installation instructions
Using the command line tool `curl`, you can easily download the shell script file **jarss.sh** and the associated configuration files **jarss_Configuration_GER** and **jarss_Configuration_ENU** using a terminal program of your choice. First create a new (sub)directory and change to the directory where the shell script file and the configuration file(s) are to be stored. Then execute the following commands to download the script file and the configuration file to the selected directory.

**Download the shell script file jarss.sh**

	curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss.sh


**Download the German configuration file**

    curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss_Konfiguration_GER

**Download the English configuration file**

    curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss_Configuration_ENU  

Then execute the following command in the same (sub)directory to give the shell script file **jarss.sh** execution rights. Make sure to execute the command as system user root (recognisable by the preceding sudo command).

	sudo chmod +x jarss.sh

## Creating configuration file(s)
Since **jarss** can be used to create several different configurations, and thus several different tasks, it makes sense to create an image of the original configuration file **jarss_Configuration_GER** or **jarss_Configuration_ENU** beforehand, and to give this image a unique name which, in the best case, allows conclusions to be drawn about the task to be performed. The easiest way to do this is to use the `mv` command, making sure that the file image is placed in the same directory as the shell script file **jarss.sh**. 

**Syntax:**

	mv [OIGINAL-FILE] [FILE-IMAGE]

**Example:**

	mv jarss_Configuration_ENU jarss_Backup_to_USB_hard_disk

## Customise the contents of the configuration file
Now open the configuration file you have just copied and renamed with a text editor of your choice. In this example, we will use the 'nano' text editor.

**Example:**

	nano jarss_Backup_to_USB_hard_disk

It is normal to feel a little overwhelmed by the amount of text at first. On closer inspection, however, you will find that most of the text is information explaining the steps. These texts can be identified by the **#** character (double cross, pound or hash) at the start of each line, which indicates a comment line.

All lines that are not preceded by a # character are called **key/value values**, colloquially known as **variables**. The notation is always the same. The equal sign is preceded by a fixed variable name (key) that cannot be changed. Values can be entered by the user **in quotes** after the equal sign. The values are usually described by the preceding information.

- **An example**

  As the heading indicates, this section defines the destination directory, i.e. the location where the backed up data will be stored. Below the heading, the syntax pattern or notation of the variables is first explained using an example. This is followed by further information describing the procedure in more detail. At the end is the actual variable, identified by the missing # character at the beginning of the line.

		# Backup target
		#---------------------------------------------------------------------
		# Syntax pattern: target="/[VOLUME]/[SHARE]/[FOLDER]"
		#---------------------------------------------------------------------
		# The full path to the destination directory must be specified; if the
		# destination directory does not exist, it will be created during the
		# first backup. Invalid characters in file and directory names
		# are ~ " # % & * : < > ? / \ { | }
		#---------------------------------------------------------------------
		target=""

  In this case there is no value inside the quotes of the target='' variable. Some variables already contain default values that can be deleted or changed depending on the task. In this case, you will be asked to enter a directory path (the target directory), which could look like this: 
  
		target="/volumeUSB1/Backup/Backup_Home_Directories'

  In this way, you work through the configuration file from top to bottom, assigning or changing values, deleting content and leaving fields blank, as required. The configuration will be saved at the end.

## Executing the configuration file
Running the configuration file As mentioned above, several different configurations can be created for different tasks and run with jarss. It is important to ensure that the jarss shell script file and the configuration file(s) are always in the same directory.

The jarss shell script file should preferably be run with root privileges (i.e. preceded by the sudo command), as otherwise there may be some restrictions, e.g. directories cannot be created, files cannot be saved due to lack of privileges, or other commands cannot be executed correctly.

The call itself is best made by prefixing the absolute path, i.e. the directory path where the shell script file jarss.sh is located, although the relative path will suffice if you are in the same directory as the shell script and the configuration file(s). Other mandatory and optional options follow, which are described below.

#### _Note: Text in capital letters within square brackets is a placeholder and must be replaced with your own information, including the square brackets.

	sudo bash /[ABSOLUTE-PATH]/jarss.sh --job-name="[FILENAME]’ [--info=progress2] [--dry-run] [-v] [-vvv] [-vvv]

```
/[ABSOLUTE-PATH]/jarss.sh   Instead of the placeholder [ABSOLUTER-PFAD], the absolute path to the directory in which the jarss.sh script is located must be specified here.
                            Example: /volume1/backups/jarss.sh

--job-name="[FILENAME]’     The file name of the job to be executed or the configuration file to be executed must be entered here instead of the placeholder [FILENAME]. 
                            Example: --job-name="jarss_Configuration_ENU’

Optional functions
--info=progress2            Displays information about the overall progress of the file transfer.
--dry-run                   Rsync only simulates what would happen without data being copied or synchronised.
                            or synchronised.
-v                          Short rsync log of which files are being transferred.
-vv                         Extended rsync protocol, which files are skipped. 
-vvv                        Very extensive rsync log for debugging.
```

- **An example** 

		bash /volume1/backups/jarss.sh --job-name='jarss_Backup_to_USB_hard_disk' --dry-run
	
  It is recommended that you do a test run of the job before running it for the first time to ensure that everything is working correctly. This can be done using the `--dry-run' option. This only simulates what would happen if no data were copied. Only when the simulation has run successfully and satisfactorily can the `--dry-run' option be removed. During execution, all relevant information is displayed in the terminal window and a log is written to the same location as the jarss.sh shell script file and the executed configuration file. The log can be identified by the name of the executed configuration file and the extension .log. Following the example, the file name of the log is: jarss_Backup_to_USB_hard_disk.log.