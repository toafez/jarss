#!/bin/bash
# Filename: jarss.sh - coded in utf-8
script_version="2.0-000"

#         jarss - just another rsync shell script
#    Copyright (C) 2026 by tommes (toafez) | MIT License

  
# ------------------------------------------------------------------------
# Debugging and tracing tools
# ------------------------------------------------------------------------
# -e (errexit):	The shell script will terminate immediately with
#				an error code if a command returns a non-zero exit code. 
set -e

# -u (nounset):	The shell interprets the use of an unset variable
#				as an error, which causes the script to terminate.
set -u

# -o pipefail:	By default, a pipeline returns the exit code of the last
#				command. With the `pipefail` option, however, the pipeline
#				returns the exit code of the first failed command instead.
set -o pipefail

# -x (xtrace):	This option enables output logging. This is useful for
#				debugging scripts. To enable, use the command "set -x" 
#				To disable, use the command "set +x"
set +x

# ------------------------------------------------------------------------
# Loading backup config and rsync options
# ------------------------------------------------------------------------

# Create variables, some of which may be left unused
username="$(whoami)"
dryrun=
progress=
verbose=
exit_rsync=
exit_recycle=
exit_create=
exit_delete=
git_version=$(wget --no-check-certificate --timeout=60 --tries=1 -q -O- "https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss.sh" | grep ^script_version= | cut -d '"' -f2)

# Multi-branching for string pattern matching
for i in "$@" ; do
	case $i in
		-j=*|--job-name=*)
		script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"
		script_name=$(basename "$0")
		jobname="${i#*=}"
		if [[ -f "${script_path}/${jobname}" ]] && [[ -f "${script_path}/${script_name}" ]]; then
			source "${script_path}/${jobname}"
		else
			echo "Backup aborted! The job configuration could not be read!"
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
#  Set up language
# ------------------------------------------------------------------------
if [[ -z "${language}" ]] || [[ "${language}" == "enu" ]]; then
	# English language variables
	hr="---------------------------------------------------------------------------------------------------"
	txt_run_script_as_non_root_1="The command is executed by the root user, who may have limited"
	txt_run_script_as_non_root_2="permissions."
	txt_run_script_as_root_1=" - If problems occur, the task should preferably be performed by the"
	txt_run_script_as_root_2="   system user root to avoid possible backup problems!"
	txt_load_config="The job configuration [ ${jobname} ] is being loaded"
	txt_github_check_1="IMPORTANT NOTICE:"
	txt_github_check_2="This script has been updated and is available on GitHub."
	txt_github_check_3="Please update your version ${script_version} to the new version ${git_version}."
	txt_local_setup=" - A local backup will be performed."
	txt_ssh_setup_pull=" - Performing a pull backup from a remote server. The connection is being checked..."
	txt_ssh_setup_push=" - Doing a push backup to a remote server. Checking the connection..."
	txt_ssh_setup_failed=" - Configuration error: Either a pull OR a push backup can be performed."
	txt_ssh_test_success=" - The SSH connection test to the remote server was successful. Connecting..."
	txt_ssh_test_failed=" - The SSH connection test failed. Please check your SSH connection."
	txt_ssh_push_info_1=" - Note: During a push backup to a remote server, the permissions in the"
	txt_ssh_push_info_2="   backup target will be set to 755 for directories and 644 for files."
	txt_rsync_start_backup="Starting the rsync backup..."
	txt_rsync_target_success=" - The backup target has been found."
	txt_rsync_target_failed=" - Warning: The target folder could not be created."
	txt_rsync_write_log="Write rsync log..."
	txt_rsync_write_log_source=" - Source directory :"
	txt_rsync_write_log_target=" - Target directory :"
	txt_rsync_progress="Current progress..."
	txt_rsync_error=" - Rsync reports error code"
	txt_speed_limited=" - The read and write speed of the rsync process has been limited to"
	txt_speed_unlimited_1=" - The rsync process is using the maximum read and write speed, which is limited to"
	txt_speed_unlimited_2="   System availability may be severely limited for the duration of the backup!"
	txt_speed_ionice_1=" - The [ ionice ] program optimises the read and write speed of the rsync process"
	txt_speed_ionice_2="  to ensure system availability during the backup!"
	txt_rsync_job_executed="The job has been completed..."
	txt_recycle_delete=" - Data in the /@recycle folder that was older than ${recycle} days has been deleted."
	txt_recycle_rejected=" - Any data from the source(s) that had been deleted in the meantime has also been permanently deleted from the destination."
	txt_incremental_create_entry=" - Another incremental version folder has been added to the destination folder."
	txt_incremental_create_failed=" - Adding an incremental version folder to the destination folder failed"
	txt_incremental_delete_entry=" - Data older than ${versions} days was deleted from the incremental version folder."
	txt_incremental_del_note_1=" - Either no incremental version folders older than ${versions} of days"
    txt_incremental_del_note_2="   were found, or the deletion process failed."
	txt_script_success="The backup job was successfully executed."
	txt_script_warning="Warning: Warning: One or more problems occurred during execution!"
	txt_script_failed=" - The backup job either failed or was terminated prematurely."
	txt_email_success=" - An email containing the meeting minutes will be sent."
	txt_email_failed=" - The email could not be sent because the command-line tool, curl, is unavailable!"
elif [[ "${language}" == "ger" ]]; then
	# Deutsche Sprachvariablen
	hr="---------------------------------------------------------------------------------------------------"
	txt_run_script_as_non_root_1="Der Auftrag wird durch den Benutzer [ ${username} ] ausgeführt, der möglicherweise nur über"
	txt_run_script_as_non_root_2="eingeschränkte Berechtigungen verfügt."
	txt_run_script_as_root_1=" - Falls Probleme auftreten, sollte der Auftrag vorzugsweise als Systembenutzer [ root ]"
	txt_run_script_as_root_2="   ausgeführt werden, um mögliche Probleme bei der Datensicherung zu vermeiden!"
	txt_load_config="Die Auftragskonfiguration [ ${jobname} ] wird geladen"
	txt_github_check_1="WICHTIGER HINWEIS:"
	txt_github_check_2="Auf GitHub steht ein Update für dieses Skript zur Verfügung."
	txt_github_check_3="Bitte aktualisiere deine Version ${script_version} auf die neue Version ${git_version}."
	txt_local_setup=" - Eine lokale Sicherung wird durchgeführt."
	txt_ssh_setup_pull=" - Ein (Pull)-Backup von einem Remote Server wird durchgeführt. Die Verbindung wird überprüft..."
	txt_ssh_setup_push=" - Ein (Push)-Backup auf einen Remote Server wird durchgeführt. Die Verbindung wird überprüft..."
	txt_ssh_setup_failed=" - Konfigurationsfehler: Es kann entweder ein Pull- ODER ein Push-Backup durchgeführt werden."
	txt_ssh_test_success=" - Der SSH-Verbindungstest zum Remote-Server war erfolgreich. Verbinde..."
	txt_ssh_test_failed=" - Der SSH-Verbindungstest ist fehlgeschlagen. Bitte überprüfe die SSH-Verbindung."
	txt_ssh_push_info_1=" - Hinweis: Während eines (Push)-Backups auf einem Remote Server werden die Berechtigungen"
	txt_ssh_push_info_2="   im Sicherungsziel auf 755 für Verzeichnisse und 644 für Dateien gesetzt."
	txt_rsync_start_backup="Starte die rsync-Datensicherung..."
	txt_rsync_target_success=" - Das Sicherungsziel wurde gefunden."
	txt_rsync_target_failed=" - Warnung: Der Zielordner konnte nicht erstellt werden."
	txt_rsync_write_log="Schreibe rsync-Protokoll..."
	txt_rsync_write_log_source=" - Quellverzeichnis:"
	txt_rsync_write_log_target=" - Zielverzeichnis :"
	txt_rsync_progress="Aktueller Fortschritt..."
	txt_rsync_error=" - Rsync meldet Fehlercode"
	txt_speed_limited=" - Die Lese- und Schreibgeschwindigkeit des rsync-Prozesses wurde begrenzt auf"
	txt_speed_unlimited_1=" - Der rsync-Prozess verwendet die maximale Lese- und Schreibgeschwindigkeit, was die"
	txt_speed_unlimited_2="   Verfügbarkeit des Systems für die Dauer der Datensicherung stark einschränken kann!"
	txt_speed_ionice_1=" - Das Programm [ ionice ] optimiert die Lese- und Schreibgeschwindigkeit des rsync-Prozesses"
	txt_speed_ionice_2="   um die Verfügbarkeit des Systems während der Datensicherung zu gewährleisten!"
	txt_rsync_job_executed="Der Auftrag wird abgeschlossen..."
	txt_recycle_delete=" - Daten aus dem Ordner /@recycle, die älter als ${recycle} Tage waren, wurden gelöscht."
	txt_recycle_rejected=" - Zwischenzeitlich gelöschte Daten der Quelle(n) wurden auch im Ziel unwiderruflich gelöscht."
	txt_incremental_create_entry=" - Ein weiterer inkrementeller Versionsordner wurde dem Sicherungsziel hinzugefügt."
	txt_incremental_create_failed=" - Das Hinzufügen eines inkrementellen Versionsordners zum Sicherungsziel ist fehlgeschlagen."
	txt_incremental_delete_entry=" - Daten aus dem inkrementellen Versionsordner, die älter als ${versions} Tage sind, wurden gelöscht."
	txt_incremental_del_note_1=" - Entweder konnten keine inkrementellen Versionsordner gefunden werden, die"
    txt_incremental_del_note_2="   älter als ${versions} Tage sind, oder der Löschvorgang ist fehlgeschlagen."
	txt_script_success="Der Sicherungsauftrag wurde erfolgreich ausgeführt."
	txt_script_warning="Warnung: Während der Ausführung sind ein oder mehrere Probleme aufgetreten!"
	txt_script_failed=" - Der Sicherungsauftrag ist fehlgeschlagen oder wurde vorzeitig abgebrochen!"
	txt_email_success=" - Es wird eine E-Mail mit den Protokollinhalten gesendet."
	txt_email_failed=" - Die E-Mail konnte nicht gesendet werden, da das Kommandozeilen-Werkzeug curl nicht verfügbar ist!"
fi

# ------------------------------------------------------------------------
#  Set up environment variables and provide system information
# ------------------------------------------------------------------------

# Securing the Internal Field Separator (IFS)
backupIFS="${backupIFS:-$IFS}"
readonly backupIFS

# When using a versioned, incremental backup and the value of ${versions} is less than 2 or invalid, set ${versions} to 2
if [[ "${incremental}" == "true" ]] && ! [[ ${versions-} =~ ^[2-9][0-9]*$ ]]; then
	versions=2
fi

# Ensure that the number is greater than zero
non_zero_number='^[1-9][0-9]*$'

# Set timestamp function
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

# Set the date and time variable for the label of the Recycle Bin folder
datetime_dir="$(date +%Y-%m-%d_%Hh-%Mm-%Ss)"

# ------------------------------------------------------------------------
#  Set up email
# ------------------------------------------------------------------------
# Set the default port to 587 if it is empty
mail_port="${smtp_port:-587}"

# The Message-ID is a unique identifier that is an  RFC-compliant
# header. It helps mail servers and clients with referencing,
# threading, and duplicate detection.
mail_from="${mail_from-}"
message_id="$(date +%s).$$@${mail_from#*@}"

# When combined with a timestamp, the likelihood of a collision is extremely low.
date_header="$(date -R)"

# Specify the connection type
if [[ "${tls_enabled-}" == "yes" ]]; then
    if [[ "${mail_port}" == "465" ]]; then
        url="smtps://${smtp_host-}:${mail_port-}"
        # Port 465 → smtps:// + --ssl (implicit TLS)
        tls_args=(--ssl)
    elif [[ "${mail_port}" == "587" || "${mail_port}" == "25" ]]; then
        url="smtp://${smtp_host-}:${mail_port-}"
        # Port 587/25 → smtp:// + --starttls smtp (explicit STARTTLS)
        # If support for STARTTLS is missing in older versions of cURL or 
        # in a minimal installation, use the --ssl-reqd flag.
        tls_args=(--ssl-reqd)
    else
        url="smtp://${smtp_host-}:${mail_port-}"
        # Other Ports → smtp:// + --ssl-reqd (alternatively: --starttls smtp)
        tls_args=(--ssl-reqd)
    fi
else
    # Otherwise, if `tls_enabled` is not set to `yes` 
    url="smtp://${smtp_host-}:${mail_port-}"
    tls_args=()
fi

# Send email function
send_email() {
curl --silent --show-error --fail \
    --connect-timeout 15 \
    --max-time 60 \
    --url "${url}" \
    --user "${smtp_user-}:${smtp_passwd-}" \
    --mail-from "${mail_from-}" \
    --mail-rcpt "${mail_to-}" \
    "${tls_args[@]}" \
    -T <(cat <<EOF
From: ${mail_from-}
To: ${mail_to-}
Subject: ${jobname%%.*}
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Date: ${date_header}
Message-ID: <${message_id-}>

$(cat "$logfile")
EOF
)
}

# ------------------------------------------------------------------------
#  Set up logfile
# ------------------------------------------------------------------------

# Create logfile
logfile="${script_path}/${jobname%%.*}.log"
: > "${logfile}" || { echo "ERROR: The log file could not be created!" >&2; exit 1; }

# Make the log file readable and writable for everyone, but not executable
chmod 0666 "$logfile" || { echo "ERROR: The log file could not be set to writable!" >&2; exit 1; }

# Output the echo command to the terminal's standard output (stdout) and write it to the log file
log() { printf '%s\n' "$*" | tee -a "${logfile}"; }

# Success log function
success_log() {
	log ""
	log "${hr}"
	log "$(timestamp) ${txt_rsync_job_executed}"
	log "${txt_script_success}"
	[[ -n "${1:-}" ]] && log "${1:-}"
	[[ -n "${2:-}" ]] && log "${2:-}"
	if [[ "${email_notification-}" == "always" ]]; then
  		if command -v curl >/dev/null 2>&1; then
    		log "${txt_email_success}"
    		send_email
  		else
    		log "${txt_email_failed}"
		fi
	fi
	log "${hr}"
}

# Error log funktion
error_log() {
	log ""
	log "${hr}"
	log "$(timestamp) ${txt_rsync_job_executed}"
	[[ -n "${1:-}" ]] && log "${1:-}"
	[[ -n "${2:-}" ]] && log "${2:-}"
	log "${txt_script_warning}"
	[[ -n "${3:-}" ]] && log "${3:-}"
	[[ -n "${4:-}" ]] && log "${4:-}"
	log "${hr}"
	if [[ "${email_notification-}" == "always" || "${email_notification-}" == "error" ]]; then
  		if command -v curl >/dev/null 2>&1; then
    		log "${txt_email_success}"
    		send_email
  		else
    		log "${txt_email_failed}"
  		fi
	fi
}

# ------------------------------------------------------------------------
#  Start logfile
# ------------------------------------------------------------------------

# Check whether the script you are using is up to date, and if an update is available on GitHub.
if [ -n "${git_version}" ] && [ -n "${script_version}" ]; then
	if dpkg --compare-versions ${git_version} gt ${script_version}; then
		log "${hr}"
		log "${txt_github_check_1}"
		log "${txt_github_check_2}"
		log "${txt_github_check_3}"
		log "Link: https://github.com/toafez/jarss"
		log "${hr}"
		log ""
	fi
fi

# Notification that backup job starts
log "${hr}"
log "jarrs (just another rsync shell script)"
log " - Config Script Version : ${jobconfig_version-}"
log " - Rsync Script Version: ${script_version}"
log "${hr}"

# Check if the script is running as root or user
if [[ "${username}" != "root" ]]; then
	log ""
	log "${txt_run_script_as_non_root_1}"
	log "${txt_run_script_as_non_root_2}"
	log "${txt_run_script_as_root_1}"
	log "${txt_run_script_as_root_2}"
fi

log ""
log "${txt_load_config}"

# ------------------------------------------------------------------------
# Connection type settings
# ------------------------------------------------------------------------
# Local settings
if [[ -z "${sshpush}" ]] && [[ -z "${sshpull}" ]]; then
	log "${txt_local_setup}"
	connectiontype="local"
fi

# Pull settings
if [[ -z "${sshpush}" ]] && [[ -n "${sshpull}" ]]; then
	log "${txt_ssh_setup_pull}"
	ssh_cmd="ssh -p ${sshport-} -i ~/.ssh/${privatekey-} ${sshuser-}@${sshpull-}"
	connectiontype="sshpull"
fi

# Push settings
if [[ -n "${sshpush}" ]] && [[ -z "${sshpull}" ]]; then
	log "${txt_ssh_setup_push}"
	ssh_cmd="ssh -p ${sshport-} -i ~/.ssh/${privatekey-} ${sshuser-}@${sshpush-}"
	connectiontype="sshpush"
fi

# If pull and push settings have been selected 
if [[ -n "${sshpush}" ]] && [[ -n "${sshpull}" ]]; then
	error_log "" "" "${txt_ssh_setup_failed}" "${txt_script_failed}"
	exit 1
fi

# ------------------------------------------------------------------------
# Establish SSH connection
# ------------------------------------------------------------------------
if [[ "${connectiontype}" == "sshpush" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
	if ${ssh_cmd} -q -o BatchMode=yes -o ConnectTimeout=2 'echo -n' >/dev/null 2>&1; then
		log "${txt_ssh_test_success}"
		if [[ "${connectiontype}" == "sshpush" ]]; then
			log "${txt_ssh_push_info_1}"
			log "${txt_ssh_push_info_2}"
		fi
		if [[ -n "${verbose}" ]]; then
			${ssh_cmd} ${verbose} logout > >(tee -a "${logfile}") 2>&1
		fi
	else
		error_log "" "" "${txt_ssh_test_failed}" "${txt_script_failed}"
		exit 1
	fi
fi

# ------------------------------------------------------------------------
# Create a target or version folder on the local machine or a remote server
# ------------------------------------------------------------------------
# Make sure that the target path ends with a slash
target="${target:-}"
if [[ "${target: -1}" != "/" ]]; then
	target="${target}/"
fi

#---------------------------------------------------------------------
# Switch on @recycle bin without incremental versioning and set target path
#---------------------------------------------------------------------
if [[ -z "${incremental}" ]] || [[ "${incremental}" == "false" ]]; then

	# If the connectiontype is local or sshpull
	if [[ "${connectiontype}" == "local" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
		if [[ ! -d "${target}" ]]; then
			if ! mkdir -p "${target}"; then
				error_log "" "" "${txt_rsync_target_failed}" "${txt_script_failed}"
				exit 1
			fi
		fi
	fi

	# If the connectiontype is sshpush
	if [[ "${connectiontype}" == "sshpush" ]]; then
		if ${ssh_cmd} test ! -d "'${target}'"; then
			if ! ${ssh_cmd} "mkdir -p -m u+X '${target}'"; then
				error_log "" "" "${txt_rsync_target_failed}" "${txt_script_failed}"
				exit 1
			fi
		fi
	fi

	# If the number of days in the recycle bin is a number and not 0 or true, create a restore point.
	if [[ -n ${recycle} ]]; then
		if [[ ${recycle} =~ ${non_zero_number} ]] || [[ ${recycle} == "true" ]]; then
			backup="--backup --backup-dir=@recycle/${datetime_dir}"
		fi
	fi
fi

#---------------------------------------------------------------------
# Switch on incremental versioning without @recycle and set target path
# --------------------------------------------------------------------
if [[ "${incremental}" == "true" ]]; then

	# Rewrite target folder and temporarily linked folder
	init_target="${target}"
	target="${init_target}${datetime_dir}/"
	latest_link="${init_target}latest"
	link_dest="--link-dest=${latest_link}"

	# If the connectiontype is local or sshpull
	if [[ "${connectiontype}" == "local" ]] || [[ "${connectiontype}" == "sshpull" ]]; then
		if [[ ! -d "${init_target}latest" ]]; then
			if ! mkdir -p "${latest_link}"; then
				error_log "" "" "${txt_rsync_target_failed}" "${txt_script_failed}"
				exit 1
			fi
		fi
	fi
	
	# If the connectiontype is sshpush
	if [[ "${connectiontype}" == "sshpush" ]]; then
		if ${ssh_cmd} test ! -d "'${init_target}'latest"; then
			if ! ${ssh_cmd} "mkdir -p -m u+X '${latest_link}'"; then
				error_log "" "" "${txt_rsync_target_failed}" "${txt_script_failed}"
				exit 1
			fi
		fi
	fi
fi

# ------------------------------------------------------------------------
# Start rsync data backup...
# ------------------------------------------------------------------------
# Notification that rsync data backup starts...
log ""
log "${txt_rsync_start_backup}"
log "${txt_rsync_target_success}"

# If the ionice program is installed, use it, otherwise use the rsync bandwidth limitation
if command -v ionice >/dev/null 2>&1; then
	log "${txt_speed_ionice_1}"
	log "${txt_speed_ionice_2}"
	ionice_cmd="ionice -c 3"
elif [[ -n "${speedlimit}" ]] && [[ "${speedlimit}" -gt 0 ]]; then
	log "${txt_speed_limited} ${speedlimit} kB/s"
	bandwidth="--bwlimit=${speedlimit}"
else
	log "${txt_speed_unlimited_1}"
	log "${txt_speed_unlimited_2}"
fi

#---------------------------------------------------------------------
# Read in the sources and pass them to the rsync script
# --------------------------------------------------------------------
IFS='&'
read -r -a all_sources <<< "${sources-}"
IFS="${backupIFS}"
for source in "${all_sources[@]}"; do
	source=$(echo "${source}" | sed 's/^[ \t]*//;s/[ \t]*$//')

	#-----------------------------------------------------------------
	# Beginn rsync loop
	# ----------------------------------------------------------------
	log ""
	log "${hr}"
	log "$(timestamp) ${txt_rsync_write_log}"
	log "${txt_rsync_write_log_source} ${source}"
	log "${txt_rsync_write_log_target} ${target}${source##*/}"
	log "${hr}"
	if [[ -n "${progress}" ]]; then
		log "${txt_rsync_progress}"
		log ""
	fi

	# If the connectiontype is local
	if [[ "${connectiontype}" == "local" ]]; then
		# Local to Local:  rsync [option]... [source]... target
		${ionice_cmd-} \
		rsync \
		${syncopt-} \
		${progress-} \
		${bandwidth-} \
		${dryrun-} \
		${verbose-} \
		--stats \
		--delete \
		${backup-} \
		${exclude-} \
		"${source}" "${target}" ${link_dest-} > >(tee -a "${logfile}") 2>&1
		exit_rsync=${?}
	fi

	# If the connectiontype is sshpull
	if [[ "${connectiontype}" == "sshpull" ]]; then
		# Remote to Local: rsync [option]... [USER@]HOST:source... [target]
		# Notes: To transfer folder and file names from or to a remote shell
		# that contain spaces and/or special characters, the rsync option
		# --protect-args (-s) is used. Alternatively, folder and file names
		# can also be set in additional single quotes.
		# Example: either ... rsync -s "${source}" ... or ... "'${source}'"
		${ionice_cmd-} \
		rsync -s \
		${syncopt-} \
		${progress-} \
		${bandwidth-} \
		${dryrun-} \
		${verbose-} \
		--stats \
		--delete \
		${backup-} \
		${exclude-} \
		-e "ssh -p ${sshport} -i ~/.ssh/${privatekey}" ${sshuser}@${sshpull}:"${source}" "${target}" ${link_dest-} > >(tee -a "${logfile}") 2>&1
		exit_rsync=${?}
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
		${ionice_cmd-} \
		rsync -s \
		${syncopt-} \
		${progress-} \
		${bandwidth-} \
		${dryrun-} \
		${verbose-} \
		--stats \
		--delete \
		${backup-} \
		${exclude-} \
		--chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r \
		-e "ssh -p ${sshport} -i ~/.ssh/${privatekey}" "${source}" ${sshuser}@${sshpush}:"${target}" ${link_dest-} > >(tee -a "${logfile}") 2>&1
		exit_rsync=${?}
	fi

	#-----------------------------------------------------------------
	# rsync error analysis after rsync run...
	# ----------------------------------------------------------------
	if [[ "${exit_rsync}" -ne 0 ]]; then
		error_log "" "" "${txt_rsync_error} ${exit_rsync}" "${txt_script_failed}"
		exit 1
	fi
done

# --------------------------------------------------------------------
# Rotation cycle for deleting /@recycle when incremental versioning is off
# --------------------------------------------------------------------
if [[ -z "${incremental}" ]] || [[ "${incremental}" == "false" ]]; then

	if [[ -n "${recycle}" ]] && [[ "${recycle}" =~ ${non_zero_number} ]]; then

		# If the connectiontype is local or sshpull...
		if [[ -z "${dryrun}" ]] && { [[ "${connectiontype}" == "sshpull" ]] || [[ "${connectiontype}" == "local" ]]; }; then

			# If the folder exists, then execute the find command
			if [[ -d "${target%/*}/@recycle" ]]; then
				if find "${target%/*}/@recycle/"* -maxdepth 0 -type d -mtime +${recycle} -print -quit | grep -q .; then
					if find "${target%/*}/@recycle/"* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r; then
						success_log "${txt_recycle_delete}"
						exit_recycle="1"
					fi
				fi
			fi
		fi

		# If the connectiontype is sshpush...
		if [[ -z "${dryrun}" ]] && [[ "${connectiontype}" == "sshpush" ]]; then

			# If the remote folder exists, then execute the find command
			if ${ssh_cmd} test -d "'${target%/*}/@recycle'"; then
				if ${ssh_cmd} "find '${target%/*}/@recycle'/* -maxdepth 0 -type d -mtime +${recycle} -print -quit | grep -q ."; then
					if ${ssh_cmd} "find '${target%/*}/@recycle'/* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r"; then
						success_log "${txt_recycle_delete}"
						exit_recycle="1"
					fi
				fi
			fi
		fi
	elif [[ -n "${recycle}" ]] && [[ "${recycle}" == "false" ]]; then
		success_log "${txt_recycle_rejected}"
		exit_recycle="1"
	fi
fi

# --------------------------------------------------------------------
# Re-link version of the current data record if incremental versioning is switched on
# --------------------------------------------------------------------
if [[ "${incremental}" == "true" ]]; then

	# If the connectiontype is local or sshpull...
	if [[ -z "${dryrun}" ]] && [[ "${connectiontype}" == "sshpull" || "${connectiontype}" == "local" ]]; then

		# After successful execution of --link-dest, the link to ../latest that referred to the previous
		# backup is removed and a new link with the same name is created that refers to the new backup.
		if [[ -d "${latest_link}" ]]; then
			if rm -rf "${latest_link}"; then
				if ln -s "${target}" "${latest_link}"; then
					exit_create="true"
				else
					exit_create="false"
				fi
			else
				exit_create="false"
			fi
		else
			exit_create="false"
		fi


		# Rotation cycle for deleting versions when /@recycle is switched off
		# Note: The initial target ${init_target} must be specified here and 
		#       not ${target} in order to delete older version folders.
		if [[ -d "${init_target%/*}" ]]; then
			if find "${init_target%/*}"/* -maxdepth 0 -type d -mtime +${versions} -print -quit | grep -q .; then
				if find "${init_target%/*}"/* -maxdepth 0 -type d -mtime +${versions} -print0 | xargs -0 rm -r; then
					exit_delete="true"
				fi
			fi
		fi
	fi

	# If the connectiontype is sshpush...
	if [[ -z "${dryrun}" ]] && [[ "${connectiontype}" == "sshpush" ]]; then

		# After successful execution of --link-dest, the link to ../latest that referred to the previous
		# backup is removed and a new link with the same name is created that refers to the new backup.
		if ${ssh_cmd} test -d "'${latest_link}'"; then
			if ${ssh_cmd} "rm -rf '${latest_link}'"; then
				if ${ssh_cmd} "ln -s '${target}' '${latest_link}'"; then
					exit_create="true"
				else
					exit_create="false"
				fi
			else
				exit_create="false"
			fi
		else
			exit_create="false"
		fi

		# Rotation cycle for deleting versions when /@recycle is switched off
		# Note: The initial target ${init_target} must be specified here and 
		#       not ${target} in order to delete older version folders.
		if ${ssh_cmd} test -d "'${init_target%/*}'"; then
			if ${ssh_cmd} "find '${init_target%/*}'/* -maxdepth 0 -type d -mtime +${versions} -print -quit | grep -q ."; then
				if ${ssh_cmd} "find '${init_target%/*}'/* -maxdepth 0 -type d -mtime +${versions} -print0 | xargs -0 rm -r"; then
					exit_delete="true"
				else 
					exit_delete="false"
				fi
			fi
		fi
	fi

	# Analysis of the results of creating or deleting additional incremental version folders.
	if [[ "${exit_create}" == "true" ]] && [[ -z "${exit_delete}" ]]; then
		success_log "${txt_incremental_create_entry}"
	elif [[ "${exit_create}" == "true" ]] && [[ "${exit_delete}" == "true" ]]; then
		success_log "${txt_incremental_create_entry}" "${txt_incremental_delete_entry}"
	elif [[ "${exit_create}" == "true" ]] && [[ "${exit_delete}" == "false" ]]; then
		error_log "${txt_incremental_create_entry}" "" "${txt_incremental_del_note_1}" "${txt_incremental_del_note_2}"
	elif [[ "${exit_create}" == "false" ]] && [[ -z "${exit_delete}" ]]; then
		error_log "" "" "${txt_incremental_create_failed}"
	elif [[ "${exit_create}" == "false" ]] && [[ "${exit_delete}" == "true" ]]; then
		error_log "${txt_incremental_delete_entry}" "" "${txt_incremental_create_failed}"
	elif [[ "${exit_create}" == "false" ]] && [[ "${exit_delete}" == "false" ]]; then
		error_log "" "" "${txt_incremental_create_failed}" "${txt_incremental_del_note_1}" "${txt_incremental_del_note_2}"
	fi
fi

# ------------------------------------------------------------------------
# Notification of success or failure and exit script
# ------------------------------------------------------------------------
if [[ "${exit_rsync}" -eq 0 ]] && [[ "${exit_recycle}" -eq 0 ]] && [[ -z "${exit_create}" ]] && [[ -z "${exit_delete}" ]]; then
	success_log
fi
