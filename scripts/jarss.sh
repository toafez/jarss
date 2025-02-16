#!/bin/bash
# Filename: jarss.sh - coded in utf-8
script_version="1.0-200"

#         jarss - just another rsync shell script
#    Copyright (C) 2025 by tommes (toafez) | MIT License

hr="---------------------------------------------------------------------------------------------------"

# ------------------------------------------------------------------------
# Define Enviroment
# ------------------------------------------------------------------------
relative_path="$(echo `dirname ${0}`)"
absolute_path=$(dirname -- $(readlink -fn -- "$0"))
whoami=$(whoami)
exit_code=
unset dryrun progress verbose

# ------------------------------------------------------------------------
# Loading backup config and rsync options
# ------------------------------------------------------------------------
for i in "$@" ; do
	case $i in
		-j=*|--job-name=*)
		jobname="${i#*=}"
		scriptname=$(basename "$0")
		if [ -f "${absolute_path}/${jobname}" ] && [ -f "${absolute_path}/${scriptname}" ]; then
			source "${absolute_path}/${jobname}"
			exit_code=0
		else
			echo "Backup aborted! The job configuration could not be read!"
			exit_code=1
			exit 1
		fi
		;;
		-n|--dry-run)
		dryrun="--dry-run"
		shift
		;;
		--info=progress2)
		progress="--info=progress2"
		shift
		;;
		-v|-vv|-vvv)
		verbose="${i#*=}"
		shift
		;;
		*)
		echo "Error! Unknown option $i"
		exit
		;;
	esac
done

# ------------------------------------------------------------------------
#  Set language
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	if [ -z "${language}" ] || [[ "${language}" == "enu" ]]; then
		# English language variables
		txt_env_root_line_0="The backup will be performed by the user [ ${whoami} ]!"
		txt_env_root_line_1=" - If problems occur, the task should preferably be performed by the"
		txt_env_root_line_2="   system user root to avoid possible backup problems!"
		txt_env_load_config="The job configuration [ ${jobname} ] is being loaded"
		txt_ssh_set_local=" - A local backup will be performed."
		txt_ssh_set_pull=" - Performing a pull backup from a remote server. The connection is being checked..."
		txt_ssh_set_push=" - Doing a push backup to a remote server. Checking the connection..."
		txt_ssh_set_failed=" - Configuration error: Either a pull OR a push backup can be performed."
		txt_ssh_test_success=" - The SSH connection test to the remote server was successful. Connecting..."
		txt_ssh_test_push_line_1=" - Note: During a push backup to a remote server, the permissions in the"
		txt_ssh_test_push_line_2="   backup target will be set to 755 for directories and 644 for files."
		txt_ssh_test_failed_line_1=" - The SSH connection test failed. Please check your SSH connection."
		txt_ssh_test_failed_line_2="The backup job will be cancelled!"
		txt_rsync_start_backup="Starting the rsync backup..."
		txt_rsync_target_success=" - The backup target has been found."
		txt_rsync_target_failed=" - Warning: The target folder could not be created."
		txt_rsync_write_log="Write rsync log..."
		txt_rsync_write_log_source=" - Source directory :"
		txt_rsync_write_log_target=" - Target directory :"
		txt_rsync_progress="Current progress..."
		txt_rsync_error_line_1="Warning: Rsync reports error code"
		txt_rsync_error_line_2="Check the log for more information."
		txt_speed_limited=" - The read and write speed of the rsync process has been limited to"
		txt_speed_unlimited_line_1=" - The rsync process is using the maximum read and write speed, which is limited to"
		txt_speed_unlimited_line_2="   System availability may be severely limited for the duration of the backup!"
		txt_speed_ionice_line_1=" - The [ ionice ] program optimises the read and write speed of the rsync process"
		txt_speed_ionice_line_2="  to ensure system availability during the backup!"
		txt_rsync_job_executed="The job has been completed..."
		txt_recycle_note_num_1=" - Data from the backup source(s) that has been deleted in the meantime will be moved to the /@recycle folder"
		txt_recycle_note_num_2="   of the backup destination. Data older than ${recycle} days in the /@recycle folder has been deleted."
		txt_recycle_note_true_1=" - Data from the backup source(s) that has been deleted in the meantime will be moved to the /@recycle folder"
		txt_recycle_note_true_2="    of the backup destination. The data in the /@recycle folder is not automatically deleted."
		txt_recycle_note_false=" - Any data from the backup source(s) that has since been deleted will also be irrevocably deleted from the backup destination."
		txt_incremental_new_entry=" - Another incremental version folder has been added to the destination folder."
		txt_incremental_add_failed=" - Warning: Adding an incremental version folder to the destination folder failed"
		txt_incremental_del_success=" - Data older than ${versions} days was deleted from the incremental version folder."
		txt_script_exit_success=" - The backup job [ ${jobname} ] was successfully executed."
		txt_script_exit_failed=" - Warning: The backup job [ ${jobname} ] failed or was cancelled."
	elif [[ "${language}" == "ger" ]]; then
		# Deutsche Sprachvariablen
		txt_env_root_line_0="Die Datensicherung erfolgt durch den Benutzer [ ${whoami} ]!"
		txt_env_root_line_1=" - Falls Probleme auftreten, sollte der Auftrag vorzugsweise vom Systembenutzer root"
		txt_env_root_line_2="   ausgeführt werden, um mögliche Probleme bei der Datensicherung zu vermeiden!"
		txt_env_load_config="Die Auftragskonfiguration [ ${jobname} ] wird geladen"
		txt_ssh_set_local=" - Eine lokale Sicherung wird durchgeführt."
		txt_ssh_set_pull=" - Ein (Pull)-Backup von einem Remote Server wird durchgeführt. Die Verbindung wird überprüft..."
		txt_ssh_set_push=" - Ein (Push)-Backup auf einen Remote Server wird durchgeführt. Die Verbindung wird überprüft..."
		txt_ssh_set_failed=" - Konfigurationsfehler: Es kann entweder ein Pull- ODER ein Push-Backup durchgeführt werden."
		txt_ssh_test_success=" - Der SSH-Verbindungstest zum Remote-Server war erfolgreich. Verbinde..."
		txt_ssh_test_push_line_1=" - Hinweis: Während eines (Push)-Backups auf einem Remote Server werden die Berechtigungen"
		txt_ssh_test_push_line_2="   im Sicherungsziel auf 755 für Verzeichnisse und 644 für Dateien gesetzt."
		txt_ssh_test_failed_line_1=" - Der SSH-Verbindungstest ist fehlgeschlagen. Bitte überprüfe die SSH-Verbindung."
		txt_ssh_test_failed_line_2="Der Datensicherungsauftrag wird abgebrochen!"
		txt_rsync_start_backup="Starte die rsync-Datensicherung..."
		txt_rsync_target_success=" - Das Sicherungsziel wurde gefunden."
		txt_rsync_target_failed=" - Warnung: Der Zielordner konnte nicht erstellt werden."
		txt_rsync_write_log="Schreibe rsync-Protokoll..."
		txt_rsync_write_log_source=" - Quellverzeichnis:"
		txt_rsync_write_log_target=" - Zielverzeichnis :"
		txt_rsync_progress="Aktueller Fortschritt..."
		txt_rsync_error_line_1="Warnung: Rsync meldet Fehlercode"
		txt_rsync_error_line_2=" - Prüfe das Protokoll für weitere Informationen."
		txt_speed_limited=" - Die Lese- und Schreibgeschwindigkeit des rsync-Prozesses wurde begrenzt auf"
		txt_speed_unlimited_line_1=" - Der rsync-Prozess verwendet die maximale Lese- und Schreibgeschwindigkeit, was die"
		txt_speed_unlimited_line_2="   Verfügbarkeit des Systems für die Dauer der Datensicherung stark einschränken kann!"
		txt_speed_ionice_line_1=" - Das Programm [ ionice ] optimiert die Lese- und Schreibgeschwindigkeit des rsync-Prozesses"
		txt_speed_ionice_line_2="   um die Verfügbarkeit des Systems während der Datensicherung zu gewährleisten!"
		txt_rsync_job_executed="Der Auftrag wird abgeschlossen..."
		txt_recycle_note_num_1=" - Zwischenzeitlich gelöschten Daten der Sicherungsquelle(n) werden in den Ordner /@recycle, des Sicherungsziels"
		txt_recycle_note_num_2="   verschoben. Daten aus dem Ordner /@recycle, die älter als ${recycle} Tage waren, wurden gelöscht."
		txt_recycle_note_true_1=" - Zwischenzeitlich gelöschte Daten der Sicherungsquelle(n) werden in den Ordner /@recycle des"
		txt_recycle_note_true_2="   Sicherungsziels verschoben. Die Daten im Ordner /@recycle werden nicht automatisch gelöscht."
		txt_recycle_note_false=" - Zwischenzeitlich gelöschten Daten der Sicherungsquelle(n) werden auch im Sicherungsziel unwiderruflich gelöscht."
		txt_incremental_new_entry=" - Ein weiterer inkrementeller Versionsordner wurde dem Sicherungsziel hinzugefügt."
		txt_incremental_add_failed=" - Warnung: Das Hinzufügen eines inkrementellen Versionsordners zum Sicherungsziel ist fehlgeschlagen."
		txt_incremental_del_success=" - Daten aus dem inkrementellen Versionsordner, die älter als ${versions} Tage sind, wurden gelöscht."
		txt_script_exit_success=" - Der Sicherungsauftrag [ ${jobname} ] wurde erfolgreich ausgeführt."
		txt_script_exit_failed=" - Warnung: Der Sicherungsauftrag [ ${jobname} ] ist fehlgeschlagen oder wurde abgebrochen."
	fi
fi

# ------------------------------------------------------------------------
#  Set environment variables and provide system information
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then

	# Securing the Internal Field Separator (IFS) as well as the separation
	if [ -z "${backupIFS}" ]; then
		backupIFS="${IFS}"
		readonly backupIFS
	fi

	# Set timestamp
	timestamp() {
		date +"%Y-%m-%d %H:%M:%S"
	}

	# Create logfile
	logfile="${absolute_path}/${jobname}.log"
	[ -f "${logfile}" ] && rm -f "${logfile}"
	[ ! -f "${logfile}" ] && install -m 777 /dev/null "${logfile}"

	# Notification that backup job starts
	echo "${hr}" | tee -a "${logfile}"
	echo "jarrs (just another rsync shell script)" | tee -a "${logfile}"
	echo " - Config Script Version : ${jobconfig_version}" | tee -a "${logfile}"
	echo " - Rsync Script Version: ${script_version}" | tee -a "${logfile}"
	echo "${hr}" | tee -a "${logfile}"

	# Check if the script is running as root or user
	if [[ "${whoami}" != "root" ]]; then
		echo "" | tee -a "${logfile}"
		echo "${txt_env_root_line_0}" | tee -a "${logfile}"
		echo "${txt_env_root_line_1}" | tee -a "${logfile}"
		echo "${txt_env_root_line_2}" | tee -a "${logfile}"
	fi

	echo "" | tee -a "${logfile}"
	echo "${txt_env_load_config}" | tee -a "${logfile}"
	exit_code=0
fi

# ------------------------------------------------------------------------
# Connection type settings
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then

	# Local settings
	if [ -z "${sshpush}" ] && [ -z "${sshpull}" ]; then
		echo "${txt_ssh_set_local}" | tee -a "${logfile}"
		connectiontype="local"
	fi

	# Pull settings
	if [ -z "${sshpush}" ] && [ -n "${sshpull}" ]; then
		echo "${txt_ssh_set_pull}" | tee -a "${logfile}"
		ssh="ssh -p ${sshport} -i ~/.ssh/${privatekey} ${sshuser}@${sshpull}"
		connectiontype="sshpull"
	fi

	# Push settings
	if [ -n "${sshpush}" ] && [ -z "${sshpull}" ]; then
		echo "${txt_ssh_set_push}" | tee -a "${logfile}"
		ssh="ssh -p ${sshport} -i ~/.ssh/${privatekey} ${sshuser}@${sshpush}"
		connectiontype="sshpush"
	fi

	# If pull and push settings have been selected 
	if [ -n "${sshpush}" ] && [ -n "${sshpull}" ]; then
		echo "${txt_ssh_set_failed}" | tee -a "${logfile}"
		echo "${hr}" | tee -a "${logfile}"
		echo "$(timestamp) ${txt_rsync_job_executed}" | tee -a "${logfile}"
		exit_code=1
	fi
fi

# ------------------------------------------------------------------------
# Establish SSH connection
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then

	if [[ "${connectiontype}" == "sshpush" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
		${ssh} -q -o BatchMode=yes -o ConnectTimeout=2 "echo -n 2>&1"
		if [ ${?} -eq 0 ]; then
			echo "${txt_ssh_test_success}" | tee -a "${logfile}"
			if [[ "${connectiontype}" == "sshpush" ]]; then
				echo "${txt_ssh_test_push_line_1}" | tee -a "${logfile}"
				echo "${txt_ssh_test_push_line_2}" | tee -a "${logfile}"
			fi
			if [ -n "${verbose}" ]; then
				${ssh} ${verbose} logout > >(tee -a "${logfile}") 2>&1
			fi
			exit_code=0
		else
			echo "${txt_ssh_test_failed_line_1}" | tee -a "${logfile}"
			echo "" | tee -a "${logfile}"
			echo "${hr}" | tee -a "${logfile}"
			echo "$(timestamp) ${txt_ssh_test_failed_line_2}" | tee -a "${logfile}"
			exit_code=1
		fi
	fi
fi

# ------------------------------------------------------------------------
# Create a target or version folder on the local machine or a remote server
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then

	# Set the current date and time
	datetime=$(date "+%Y-%m-%d_%Hh-%Mm-%Ss")

	# Escape white spaces with backslash from ${target} and rename variable
	target=$(echo ${target} | sed -e 's/ /\ /g')

	# Make sure that the target path ends with a slash
	if [[ "${target:${#target}-1:1}" != "/" ]]; then
		target="${target}/"
	fi

	#---------------------------------------------------------------------
	# Switch on @recycle bin without incremental and set target path
	#---------------------------------------------------------------------
	if [ -z "${incremental}" ] || [[ "${incremental}" == "false" ]]; then

		# If the connectiontype is local or sshpull
		if [[ "${connectiontype}" == "local" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
			if [ ! -d "${target}" ]; then
				mkdir -p "${target}"
				exit_mkdir=${?}
			fi
		fi

		# If the connectiontype is sshpush
		if [[ "${connectiontype}" == "sshpush" ]]; then
			if ${ssh} test ! -d "'${target}'"; then
				${ssh} "mkdir -p -m u+X '${target}'"
				exit_mkdir=${?}
			fi
		fi

		# If the number of days in the recycle bin is a number and not 0 or true, create a restore point.
		is_number="^[0-9]+$"
		if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then
			backup="--backup --backup-dir=@recycle/${datetime}"
		elif [ -n "${recycle}" ] && [[ "${recycle}" == "true" ]]; then
			backup="--backup --backup-dir=@recycle/${datetime}"
		fi
	fi

	#---------------------------------------------------------------------
	# Switch on incremental without @recycle and set target path
	# --------------------------------------------------------------------
	if [ -n "${incremental}" ] && [[ "${incremental}" == "true" ]]; then

		# Rewrite target folder and temporarily linked folder
		init_target="${target}"
		target="${init_target}${datetime}"
		latest_link="${init_target}latest"
		link_dest="--link-dest=${latest_link}"

		# If the connectiontype is local or sshpull
		if [[ "${connectiontype}" == "local" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
			if [ ! -d "${init_target}latest" ]; then
				mkdir -p "${latest_link}"
				exit_mkdir=${?}
			fi
		fi
		
		# If the connectiontype is sshpush
		if [[ "${connectiontype}" == "sshpush" ]]; then
			if ${ssh} test ! -d "'${init_target}'latest"; then
				${ssh} "mkdir -p -m u+X '${latest_link}'"
				exit_mkdir=${?}
			fi
		fi
	fi

	# If the target folder could not be created
	if [[ "${exit_mkdir}" -ne 0 ]]; then
		echo "" | tee -a "${logfile}"
		echo "${txt_rsync_start_backup}" | tee -a "${logfile}"
		echo "${txt_rsync_target_failed}" | tee -a "${logfile}"
		echo "" | tee -a "${logfile}"
		echo "${hr}" | tee -a "${logfile}"
		exit_code=1
	fi
	unset exit_mkdir
fi

# ------------------------------------------------------------------------
# Start rsync data backup...
# ------------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then

	# Notification that rsync data backup starts...
	echo "" | tee -a "${logfile}"
	echo "${txt_rsync_start_backup}" | tee -a "${logfile}"
	echo "${txt_rsync_target_success}" | tee -a "${logfile}"

	# If the ionice program is installed, use it, otherwise use the rsync bandwidth limitation
	if command -v ionice 2>&1 >/dev/null; then
		echo "${txt_speed_ionice_line_1}" | tee -a "${logfile}"
		echo "${txt_speed_ionice_line_2}" | tee -a "${logfile}"
		ionice="ionice -c 3"
	elif [ -n "${speedlimit}" ] && [[ "${speedlimit}" -gt 0 ]]; then
		echo "${txt_speed_limited} ${speedlimit} kB/s" | tee -a "${logfile}"
		bandwidth="--bwlimit=${speedlimit}"
	else
		echo "${txt_speed_unlimited_line_1}" | tee -a "${logfile}"
		echo "${txt_speed_unlimited_line_2}" | tee -a "${logfile}"
	fi
	
	#---------------------------------------------------------------------
	# Read in the sources and pass them to the rsync script
	# --------------------------------------------------------------------
	IFS='&'
	read -r -a all_sources <<< "${sources}"
	IFS="${backupIFS}"
	for source in "${all_sources[@]}"; do
		source=$(echo "${source}" | sed 's/^[ \t]*//;s/[ \t]*$//')

		#-----------------------------------------------------------------
		# Beginn rsync loop
		# ----------------------------------------------------------------
		echo "" | tee -a "${logfile}"
		echo "${hr}" | tee -a "${logfile}"
		echo "$(timestamp) ${txt_rsync_write_log}" | tee -a "${logfile}"
		echo "${txt_rsync_write_log_source} ${source}" | tee -a "${logfile}"
		echo "${txt_rsync_write_log_target} ${target}${source##*/}" | tee -a "${logfile}"
		echo "${hr}" | tee -a "${logfile}"
		if [ -n "${progress}" ]; then
			echo "${txt_rsync_progress}" | tee -a "${logfile}"
			echo "" | tee -a "${logfile}"
		fi

		# If the connectiontype is local
		if [[ "${connectiontype}" == "local" ]]; then
			# Local to Local:  rsync [option]... [source]... target
			${ionice} \
			rsync \
			${syncopt} \
			${progress} \
			${bandwidth} \
			${dryrun} \
			${verbose} \
			--stats \
			--delete \
			${backup} \
			${exclude} \
			"${source}" "${target}" ${link_dest} > >(tee -a "${logfile}") 2>&1
			rsync_exit_code=${?}
		fi

		# If the connectiontype is sshpull
		if [[ "${connectiontype}" == "sshpull" ]]; then
			# Remote to Local: rsync [option]... [USER@]HOST:source... [target]
			# Notes: To transfer folder and file names from or to a remote shell 
			# that contain spaces and/or special characters, the rsync option 
			# --protect-args (-s) is used. Alternatively, folder and file names 
			# can also be set in additional single quotes. 
			# Example: either ... rsync -s "${source}" ... or ... "'${source}'"
			${ionice} \
			rsync -s \
			${syncopt} \
			${progress} \
			${bandwidth} \
			${dryrun} \
			${verbose} \
			--stats \
			--delete \
			${backup} \
			${exclude} \
			-e "ssh -p ${sshport} -i ~/.ssh/${privatekey}" ${sshuser}@${sshpull}:"${source}" "${target}" ${link_dest} > >(tee -a "${logfile}") 2>&1
			rsync_exit_code=${?}
		fi

		# If the connectiontype is sshpush
		if [[ "${connectiontype}" == "sshpush" ]]; then
			# Local to Remote: rsync [option]... [source]... [USER@]HOST:DEST
			# Notes: To transfer folder and file names from or to a remote shell 
			# that contain spaces and/or special characters, the rsync option 
			# --protect-args (-s) is used. Alternatively, folder and file names 
			# can also be set in additional single quotes. 
			# Example: either ... rsync -s "${target}" ... or ... "'${target}'"
			#
			# The parameter --chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r sets the permissions
			# in the backup target to 755 for directories and 644 for files.
			${ionice} \
			rsync -s \
			${syncopt} \
			${progress} \
			${bandwidth} \
			${dryrun} \
			${verbose} \
			--stats \
			--delete \
			${backup} \
			${exclude} \
			--chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r \
			-e "ssh -p ${sshport} -i ~/.ssh/${privatekey}" "${source}" ${sshuser}@${sshpush}:"${target}" ${link_dest} > >(tee -a "${logfile}") 2>&1
			rsync_exit_code=${?}
		fi

		#-----------------------------------------------------------------
		# rsync error analysis after rsync run...
		# ----------------------------------------------------------------
		if [[ "${rsync_exit_code}" -ne 0 ]]; then
			echo "" | tee -a "${logfile}"
			echo "${txt_rsync_error_line_1} ${rsync_exit_code}!" | tee -a "${logfile}"
			echo "${txt_rsync_error_line_2}" | tee -a "${logfile}"
			echo "" | tee -a "${logfile}"
			exit_code=1
		else
			echo "" | tee -a "${logfile}"
			exit_code=0
		fi
	done
	echo "${hr}" | tee -a "${logfile}"
	echo "$(timestamp) ${txt_rsync_job_executed}" | tee -a "${logfile}"
fi

# --------------------------------------------------------------------
# Rotation cycle for deleting /@recycle when incremental is off
# --------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	if [ -z "${incremental}" ] || [[ "${incremental}" == "false" ]]; then

		if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then

			# If the connectiontype is local or sshpull...
			if [ -z "${dryrun}" ] && [[ "${connectiontype}" == "sshpull" || "${connectiontype}" == "local" ]]; then

				# If the folder exists, then execute the find command
				if [ -d "${target%/*}/@recycle" ]; then
					find "${target%/*}/@recycle/"* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r 2>/dev/null
					if [[ ${?} -eq 0 ]]; then
						echo "${txt_recycle_note_num_1}" | tee -a "${logfile}"
						echo "${txt_recycle_note_num_2}" | tee -a "${logfile}"
					fi
				fi
			fi

			# If the connectiontype is sshpush...
			if [ -z "${dryrun}" ] && [[ "${connectiontype}" == "sshpush" ]]; then

				# Escape white spaces with backslash
				at_recycle=$(echo ${target%/*}/@recycle | sed -e 's/ /\ /g')

				# If the remote folder exists, then execute the find command
				if ${ssh} test -d "'${at_recycle}'"; then
					${ssh} "find '${at_recycle}'/* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r" 2>/dev/null
					if [[ ${?} -eq 0 ]]; then
						echo "${txt_recycle_note_num_1}" | tee -a "${logfile}"
						echo "${txt_recycle_note_num_2}" | tee -a "${logfile}"
					fi
				fi
			fi
		elif [ -n "${recycle}" ] && [[ "${recycle}" == "true" ]]; then
			echo "${txt_recycle_note_true_1}" | tee -a "${logfile}"
			echo "${txt_recycle_note_true_2}" | tee -a "${logfile}"
		elif [ -n "${recycle}" ] && [[ "${recycle}" == "false" ]]; then
			echo "${txt_recycle_note_false}" | tee -a "${logfile}"
		fi
	fi
fi

# --------------------------------------------------------------------
# Re-link version of the current data record if incremental is switched on
# --------------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	if [ -n "${incremental}" ] && [[ "${incremental}" == "true" ]]; then

		# If the connectiontype is local or sshpull...
		if [ -z "${dryrun}" ] && [[ "${connectiontype}" == "sshpull" || "${connectiontype}" == "local" ]]; then

			# After successful execution of --link-dest, the link to ../latest that referred to the previous
			# backup is removed and a new link with the same name is created that refers to the new backup.
			if [ -d "${latest_link}" ]; then
				rm -rf "${latest_link}"
				if [[ ${?} -eq 0 ]]; then
					ln -s "${target}" "${latest_link}"
					if [[ ${?} -eq 0 ]]; then
						echo "${txt_incremental_new_entry}" | tee -a "${logfile}"
					else
						echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
					fi
				else
					echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
				fi
			else
				echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
			fi

			# Rotation cycle for deleting versions when /@recycle is switched off
			if [ -d "${target%/*}" ]; then
				find "${target%/*}/"* -maxdepth 0 -type d -mtime +${versions} -print0 | xargs -0 rm -r 2>/dev/null
				if [[ ${?} -eq 0 ]]; then
					echo "${txt_incremental_del_success}" | tee -a "${logfile}"
				fi
			fi
		fi

		# If the connectiontype is sshpush...
		if [ -z "${dryrun}" ] && [[ "${connectiontype}" == "sshpush" ]]; then

			# Escape white spaces with backslash
			latest_link=$(echo ${latest_link} | sed -e 's/ /\ /g')
			target=$(echo ${target} | sed -e 's/ /\ /g')

			# Check if the remote folder exists, otherwise create it
			if ${ssh} test -d "'${latest_link}'"; then
				${ssh} "rm -rf '${latest_link}'"
				if [[ ${?} -eq 0 ]]; then
					${ssh} "ln -s '${target}' '${latest_link}'"
					if [[ ${?} -eq 0 ]]; then
						echo "${txt_incremental_new_entry}" | tee -a "${logfile}"
					else
						echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
					fi
				else
					echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
				fi
			else
				echo "${txt_incremental_add_failed}" | tee -a "${logfile}"
			fi

			# Rotation cycle for deleting versions when /@recycle is switched off
			if ${ssh} test -d "'${target%/*}'"; then
				${ssh} "find '${target%/*}'/* -maxdepth 0 -type d -mtime +${versions} -print0 | xargs -0 rm -r" 2>/dev/null
				if [[ ${?} -eq 0 ]]; then
					echo "${txt_incremental_del_success}" | tee -a "${logfile}"
				fi
			fi
		fi
	fi
fi

# ------------------------------------------------------------------------
# Notification of success or failure and exit script
# ------------------------------------------------------------------------
if [[ "${exit_code}" -eq 0 ]]; then
	# Notification that the backup job was successfully executed
	echo "${txt_script_exit_success}" | tee -a "${logfile}"
	echo "${hr}" | tee -a "${logfile}"
	exit 0
else
	# Notification that the backup job contained errors
	echo "${txt_script_exit_failed}" | tee -a "${logfile}"
	echo "${hr}" | tee -a "${logfile}"
	exit 1
fi
