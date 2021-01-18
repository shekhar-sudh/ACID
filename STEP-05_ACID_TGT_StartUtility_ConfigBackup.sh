#!/bin/bash
#########################################################################################
#                                                                                       #
# Script name: STEP-05_ACID_TGT_StartUtility_ConfigBackup.sh	                        #
#                                                                                       #
# Purpose: This Script will start utility server & db, and perform a backup of config   #
#          files on the target database.                                                #
#                                                                                       #
# Usage Instructions: STEP-05_ACID_TGT_StartUtility_ConfigBackup.sh				        #
# Version History: 2.0 by Sudhanshu Shekhar on 03/14/2018                               #
# For Support Contact : sudhanshu.shekhar@company.com 									    #
#########################################################################################

############################## Sourcing Variables for the script from the PARAMETERS.conf file - Begin ##############################
echo ""
echo ""
echo "Sourcing the parameter variables into the script now."
source PARAMETERS.conf
############################## Sourcing Variables for the script from the PARAMETERS.conf file - End ##############################

############################## Sourcing Runtime Variables for the script from the copyback_SRC_runtimeVAR.conf file - Begin ##############################
if [ -f "${DIRBKP_COPYBACK_TGT}/copyback_SRC_runtimeVAR.conf" ]; then
    echo""
    echo""
    echo "Sourcing the run time variables into the script now."
    source ${DIRBKP_COPYBACK_TGT}/copyback_SRC_runtimeVAR.conf
else
    echo "Step05 script ${0} failed to load the runtimeVAR.conf."
    echo "" | mailx -s "Step05 script ${0} failed to load the runtimeVAR.conf, Check Immediately" "${mailreceiver}"
  exit 1
fi
############################## Sourcing Runtime Variables for the script from the copyback_SRC_runtimeVAR.conf file - End ################################

############################## Echo the parameters obtained from the PARAMETERS.conf file - Begin ##############################
echo "Below are the parameters obtained from the PARAMETERS.conf file -"
echo "Source SID is -  ${SRC_SID}"
echo "Source HOST is - ${SRC_HOST}"
echo "Source user is - ${SRC_USER}"
echo "Source DB DSN is - ${SRC_DSN}"
echo "Target SID is - ${TGT_SID}"
echo "Target HOST is - ${TGT_HOST}"
echo "Target user is - ${TGT_USER}"
echo "Target DB DSN is - ${TGT_DSN}"
echo "Source Script Location is - ${SCRIPT_LOC_SRC}"
echo "Target Script Location is - ${SCRIPT_LOC_TGT}"
echo "Source Log Location is - ${LOG_LOC_SRC}"
echo "Target Log Location is - ${LOG_LOC_TGT}"
echo "Backup type is - ${BACKUP_TYPE}"
echo "Directory for copyback on source is - ${DIRBKP_COPYBACK_SRC}"
echo "Directory for copyback on target is - ${DIRBKP_COPYBACK_TGT}"
echo "File pattern for transfer is - ${FILE_PATTERN}"
echo "Parallel threads for transfer is - ${PARALLEL_THREADS}"
echo "Mail receiver list is - ${mailreceiver}"
echo ""
echo ""
echo "Name of utility server is ${UTIL_SRV}"
echo "Port of utility server is ${UTIL_PORT}"
echo "Password for utility DB is ${UTIL_PASS}"
echo ""
echo "Target database DB file is ${DBFILE_NAME_TGT}"
echo "Target database DB logfile is ${DBLOG_NAME_TGT}"
echo "Target database DB parameter file is ${DBPARAM_NAME_TGT}"
echo "Target database DB message file is ${DBMSG_NAME_TGT}"
echo ""
echo "Target database dbspace location is ${DBSPACE_LOC_TGT}"
echo "Target database tempspace location is ${TMPSPACE_LOC_TGT}"
echo ""
echo "Runtime variable BACKUP_DATE is - ${BACKUP_DATE}"
echo ""
############################## Echo the parameters obtained from the PARAMETERS.conf file - End ##############################

############################## Setting Variables for this script - Begin ##############################
	SCRIPT_NAME=${0}
	ACTIVITY_TYPE="StartUtility_ConfigBackup"
	SAPSID="`whoami | cut -c1-3 | tr '[a-z]' '[A-Z]'`"
	DBNAME="${SAPSID}IQDB"
	RUN_DATE="`date +"%m_%d_%Y"`"
	MY_HOSTNAME="`hostname -f`"
	SCRIPT_LOG="${LOG_LOC_TGT}/step05_${DBNAME}_${ACTIVITY_TYPE}_${RUN_DATE}.html"
############################## Setting Variables for this script - End ##############################

############################## Verify run conditions for this script - Begin ##############################
if [ ${TGT_SID} == ${SAPSID} ] ; then
  echo "Looks like we are running this script on the right DB - ${TGT_SID}"
  if [ ${TGT_HOST} == ${MY_HOSTNAME} ] ; then
        echo "This script is running on the target database ${SAPSID}, on the host ${MY_HOSTNAME}."
        echo "Moving ahead to set up the environment for activity ${ACTIVITY_TYPE}."
  fi
else
  echo "This script is running on the database ${SAPSID}, on the host ${MY_HOSTNAME}. This script must run on the target database."
  echo "" | mailx -s "This script must run on the target database - ${TGT_SID}, Check Immediately" "${mailreceiver}"
  exit 1
fi
############################## Verify run conditions for this script - End ##############################

############################## Taking Care of Any Old Logs - Begin ##############################
rm -f ${LOG_LOC_TGT}/step05*log* ${LOG_LOC_TGT}/step05*html
############################## Taking Care of Any Old Logs - Begin ##############################

############################## Output Formatting for SAPIQ Copyback Automation - Begin ################################
# Format the script output in HTML/CSS
	# Prepare the header log file for the script final log
		echo "<style type="text/css">
				table.blueTable {
				  border: 1px solid #1C6EA4;
				  background-color: #EEEEEE;
				  width: 60%;
				  text-align: left;
				  border-collapse: collapse;
				}
				table.blueTable td, table.blueTable th {
				  border: 1px solid #AAAAAA;
				  padding: 3px 2px;
				}
				table.blueTable tbody td {
				  font-size: 13px;
				}
				table.blueTable tr:nth-child(even) {
				  background: #D0E4F5;
				}
				table.blueTable tfoot td {
				  font-size: 14px;
				}
				table.blueTable tfoot .links {
				  text-align: right;
				}
				table.blueTable tfoot .links a{
				  display: inline-block;
				  background: #1C6EA4;
				  color: #FFFFFF;
				  padding: 2px 8px;
				  border-radius: 5px;
				}
				</style>"  > ${LOG_LOC_TGT}/step05_header_log.html
		echo "<h1 style="color:blue\;text-align:left\;font-size:150%\;"><u>Automated Copyback of IQ Database Suite </u></h1>" >> ${LOG_LOC_TGT}/step05_header_log.html
		echo "<table><tr><td><p style="color:Blue\;"><b>Step-05. Start Utility Server & Backup Config Files of Target DB ${SAPSID}.</p></td></tr></table>" >> ${LOG_LOC_TGT}/step05_header_log.html

# Report Bugs to the developer
echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.shekhar@company.com">Support</a></address>" > ${LOG_LOC_TGT}/step05_Report_Bug_log.html
############################## Output Formatting for SAPIQ Copyback Automation - End ################################

############################## Fast Exit if this script is being run on the production system - Begin ##############################
# Verify if the SAPSID is production machine :: ERROR-TRAP
if [[ ${SAPSID} == *P ]] ; then

		# Print status information
		echo "<table><tr><td><p style="color:Red\;"> ERROR	ERROR	ERROR	ERROR	ERROR	ERROR <br></p></td></tr></table>" > ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;"> This Action is Not Allowed On Production System - ${SAPSID}.  <br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;"> Why do you want to run this script on your production system, you need a time off dude !!  <br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;">   <br></p></td></tr></table>" >> ${SCRIPT_LOG}

		# Merge the script log files into the final log now
		cat ${LOG_LOC_TGT}/step05_header_log.html ${SCRIPT_LOG} ${LOG_LOC_TGT}/step05_Report_Bug_log.html >> ${LOG_LOC_TGT}/step05_final_log.html

		# Send email about the status
		(
        echo "To: ${mailreceiver}"
        echo "MIME-Version: 1.0"
        echo "Subject: FAILURE:: Activity ${ACTIVITY_TYPE}, Script ${SCRIPT_NAME} Should Never Run on Production Database"
        echo "Content-Type: text/html"
        cat ${LOG_LOC_TGT}/step05_final_log.html
		) | /usr/sbin/sendmail -t
		exit 1
############################## Fast Exit if this script is being run on the production system - End ##############################
	else
############################## Setting SYBASE environment - Begin ###############################
		if [ -f /usr/sap/${SAPSID}/server/SYBASE.sh ]; then
		. /usr/sap/${SAPSID}/server/IQ-16_1/IQ-16_1.sh
		fi # SYBASE environment
		export PATH=/usr/sap/${SAPSID}/server/IQ-16_1/bin64:/bin

		# Completed Setting SYBASE environment
		echo "<table><tr><td><p style="color:Blue\;">Environment has been set for ${ACTIVITY_TYPE} activity of the SAPIQ Target System ${SAPSID}.</p></td></tr></table>" > ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;"><b>${ACTIVITY_TYPE} activity of database ${DBNAME} started at `date +"%T"`.</p></td></tr></table>" >> ${SCRIPT_LOG}
############################## Setting SYBASE environment - End ################################

############################## Backup the existing configuration of the Target DB - Begin ##############################
if [ -e "${DBLOG_NAME_TGT}" -a -e "${DBPARAM_NAME_TGT}" -a -e "${DBMSG_NAME_TGT}" ]; then
    echo "<table><tr><td><p style="color:Blue\;">Following DB log-file, parameter-file and message-file have been located for Target DB ${DBNAME} --> </p></td></tr></table>" >> ${SCRIPT_LOG}
    echo "<table><tr><td><p style="color:Blue\;"><ul>${DBLOG_NAME_TGT}</ul><ul>${DBPARAM_NAME_TGT}</ul><ul>${DBMSG_NAME_TGT}</ul></p></td></tr></table>" >> ${SCRIPT_LOG}

    echo "<table><tr><td><p style="color:Red\;">Removed all old backups of the above DB files from the previous copyback activities.</p></td></tr></table>" >> ${SCRIPT_LOG}
    rm -f ${DBLOG_NAME_TGT}.BKP_COPYBACK* ${DBPARAM_NAME_TGT}.BKP_COPYBACK* ${DBMSG_NAME_TGT}.BKP_COPYBACK*

    echo "<table><tr><td><p style="color:Blue\;">Backing up the current configuration files for the db ${SAPSID} in following files --> </p></td></tr></table>" >> ${SCRIPT_LOG}
    cp ${DBLOG_NAME_TGT} ${DBLOG_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}
    cp ${DBPARAM_NAME_TGT} ${DBPARAM_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}
    cp ${DBMSG_NAME_TGT} ${DBMSG_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}

    echo "<table><tr><td><p style="color:Blue\;"><ul>${DBLOG_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}</ul><ul>${DBPARAM_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}</ul><ul>${DBMSG_NAME_TGT}.BKP_COPYBACK_${RUN_DATE}</ul></p></td></tr></table>" >> ${SCRIPT_LOG}
else
    echo "<table><tr><td><p style="color:Red\;"><b><br>Failed to locate DB configuration files for Target DB ${DBNAME}, check immediately.</p></td></tr></table>" >> ${SCRIPT_LOG}
    # Merge the script log files into the final log now
    cat ${LOG_LOC_TGT}/step05_header_log.html ${SCRIPT_LOG} ${LOG_LOC_TGT}/step05_Report_Bug_log.html >> ${LOG_LOC_TGT}/step05_final_log.html
        # Send email about the status
        (
         echo "To: ${mailreceiver}"
         echo "MIME-Version: 1.0"
         echo "Subject: FAILURE:: Failed to Locate DB configuration files for Target DB ${DBNAME}, Please check immediately"
         echo "Content-Type: text/html"
         cat ${LOG_LOC_TGT}/step05_final_log.html
        ) | /usr/sbin/sendmail -t
        exit 1
fi
############################## Backup the existing configuration of the Target DB - End ##############################

#####################################Start the Utility Server & DB - Begin ###########################################
echo "<table><tr><td><p style="color:Blue\;"><br><b>Starting the Utility Server & DB on the target db server ${MY_HOSTNAME} --> </b><br></p></td></tr></table>" >> ${SCRIPT_LOG}
start_iq -n ${UTIL_SRV} -x "tcpip{PORT=${UTIL_PORT}}" -su ${UTIL_PASS} >> ${LOG_LOC_TGT}/step05_start_iq_log

#Convert & merge the tmp logfile in HTML format

awk 'BEGIN {print "<table class=\"blueTable\">" "<tbody>"} {print "<tr>"; print "<td>" $0"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${LOG_LOC_TGT}/step05_start_iq_log > ${LOG_LOC_TGT}/step05_start_iq_log.html
cat ${LOG_LOC_TGT}/step05_start_iq_log.html >> ${SCRIPT_LOG}

echo "<table><tr><td><p style="color:Blue\;"><br>Verifying the Utility Server & DB on the target db server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
dbping -c dbn=utility_db >> ${SCRIPT_LOG}
UTILITY_RC="`echo $?`"
if [  ${UTILITY_RC} -eq 0 ]; then
    echo "<table><tr><td><p style="color:Blue\;">Utility Server and Utility DB have been started successfully on server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
else
    echo "<table><tr><td><p style="color:Red\;"><b><br>Failed to start Utility Server and Utility DB on server ${MY_HOSTNAME}, check immediately.</p></td></tr></table>" >> ${SCRIPT_LOG}
    # Merge the script log files into the final log now
    cat ${LOG_LOC_TGT}/step05_header_log.html ${SCRIPT_LOG} ${LOG_LOC_TGT}/step05_Report_Bug_log.html >> ${LOG_LOC_TGT}/step05_final_log.html
        # Send email about the status
        (
         echo "To: ${mailreceiver}"
         echo "MIME-Version: 1.0"
         echo "Subject: FAILURE:: Utility Server & DB Startup Failed, Please check immediately"
         echo "Content-Type: text/html"
         cat ${LOG_LOC_TGT}/step05_final_log.html
        ) | /usr/sbin/sendmail -t
        exit 1
fi

echo "<table><tr><td><p style="color:Red\;"><b>${ACTIVITY_TYPE} activity of database ${DBNAME} completed at `date +"%T"`.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
#####################################Start the Utility Server & DB - End #############################################

###########################################Send Mail Confirmation - Begin ############################################

echo "<table><tr><td><p style="color:Blue\;"><b>Utility Server & DB started, Configuration Backup Completed successfully on Target DB ${DBNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
# Merge the script log files into the final log now
cat ${LOG_LOC_TGT}/step05_header_log.html ${SCRIPT_LOG} ${LOG_LOC_TGT}/step05_Report_Bug_log.html >> ${LOG_LOC_TGT}/step05_final_log.html
# Send email about the status
(
echo "To: ${mailreceiver}"
echo "MIME-Version: 1.0"
echo "Subject: SUCCESS - ACID Suite ::STEP05:: Utility Server & DB started, Configuration Backup Completed successfully on Target DB ${SAPSID}"
echo "Content-Type: text/html"
cat ${LOG_LOC_TGT}/step05_final_log.html
) | /usr/sbin/sendmail -t

fi
exit 0
###########################################Send Mail Confirmation - End ##############################################
#End of the script
