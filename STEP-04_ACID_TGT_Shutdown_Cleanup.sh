#!/bin/bash
#########################################################################################
#                                                                                       #
# Script name: STEP-04_ACID_TGT_Shutdown_Cleanup.sh    			                        #
#                                                                                       #
# Purpose: This Script will shutdown IQ DB & cockpit services on target DB for copyback	#
#                                                                                       #
# Usage Instructions: STEP-04_ACID_TGT_Shutdown_Cleanup.sh						        #
# Version History: 2.0 by Sudhanshu Shekhar on 03/12/2018                               #
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
    echo "Step04 script ${0} failed to load the runtimeVAR.conf."
    echo "" | mailx -s "Step04 script ${0} failed to load the runtimeVAR.conf, Check Immediately" "${mailreceiver}"
  exit 1
fi
############################## Sourcing Runtime Variables for the script from the copyback_SRC_runtimeVAR.conf file - End ################################

############################## Echo the parameters obtained from the PARAMETERS.conf file - Begin ##############################
echo ""
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
	ACTIVITY_TYPE="Copyback_Shutdown"
	SAPSID="`whoami | cut -c1-3 | tr '[a-z]' '[A-Z]'`"
	DBNAME="${SAPSID}IQDB"
	RUN_DATE="`date +"%m_%d_%Y"`"
	MY_HOSTNAME="`hostname -f`"
	SCRIPT_LOG="${LOG_LOC_TGT}/step04_${DBNAME}_${ACTIVITY_TYPE}_${RUN_DATE}.html"
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

############################## Remove the script templog file first - Begin ##############################
rm -f `pwd`/step04_log.temp
############################## Remove the script templog file first - End ##############################

############################## Handling the Copyback log directories - Begin ##############################
        #Remove copyback logs older than previous build
        if [ -d "${SCRIPT_LOC_TGT}/deleteme_copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"><br><br>Removing copyback logs from previous than last build. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        rm -rf ${SCRIPT_LOC_TGT}/deleteme_copybacklogs >> `pwd`/step04_log.temp
        fi
        #Rename copyback logs from previous than the last build, mark them for deletion
        if [ -d "${SCRIPT_LOC_TGT}/last_copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;">Marking copyback logs from previous than the last build for delete in next copyback. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        mv ${SCRIPT_LOC_TGT}/last_copybacklogs ${SCRIPT_LOC_TGT}/deleteme_copybacklogs >> `pwd`/step04_log.temp
        fi
        #Rename copyback logs from the last build
        if [ -d "${SCRIPT_LOC_TGT}/copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Marking copyback logs from last build to be retained till next build. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        mv ${SCRIPT_LOC_TGT}/copybacklogs ${SCRIPT_LOC_TGT}/last_copybacklogs >> `pwd`/step04_log.temp
        fi
        #Create copyback logs directory for this copyback
        echo "<table><tr><td><p style="color:Blue\;"> Creating directory for keeping logs for this copyback. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        mkdir ${SCRIPT_LOC_TGT}/copybacklogs
        chmod 775 ${SCRIPT_LOC_TGT}/copybacklogs
        if [ -d "${SCRIPT_LOC_TGT}/copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Successfully created directory for keeping logs for this copyback. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        echo "<table><tr><td><p style="color:Blue\;"> Moving ahead with the activity ${ACTIVITY_TYPE} now. <br></p></td></tr></table>" >> `pwd`/step04_log.temp
        # Create the SCRIPT_LOG now & merge the temp log to the SCRIPT_LOG now
        touch ${SCRIPT_LOG}
        cat `pwd`/step04_log.temp > ${SCRIPT_LOG}
        rm -f `pwd`/step04_log.temp
        else
        echo "<table><tr><td><p style="color:Red\;"> Failed to create the directory for keeping logs for this copyback - ${SCRIPT_LOC_TGT}/copybacklogs. <br></p></td></tr></table> " >> `pwd`/step04_log.temp
        echo "" >> `pwd`/step04_log.temp
        mailx -s "Failed to create the directory for keeping logs for this copyback - ${SRC_SID}, Check Immediately" ${mailreceiver} < `pwd`/step04_log.temp
        exit 1
        fi
############################## Handling the Copyback log directories - End ##############################

############################## Output Formatting for SAPIQ Copyback Automation - Begin ################################
# Format the script output in HTML/CSS
	# Prepare the header log file for the script final log
		echo "<style type="text/css">
				table.blueTable {
				  border: 1px solid #1C6EA4;
				  background-color: #EEEEEE;
				  width: 60%;
				  text-align: center;
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
				</style>"  > ${LOG_LOC_TGT}/step04_header_log.html
		echo "<h1 style="color:blue\;text-align:left\;font-size:150%\;"><u>Automated Copyback of IQ Database Suite </u></h1>" >> ${LOG_LOC_TGT}/step04_header_log.html
		echo "<table><tr><td><p style="color:Blue\;"><b>Step-04. Shutdown of DB & Cockpit services for ${SAPSID}.</p></td></tr></table>" >> ${LOG_LOC_TGT}/step04_header_log.html
############################## Output Formatting for SAPIQ Copyback Automation - End ################################

############################## Fast Exit if this script is being run on the production system - Begin ##############################
	# Verify if the SAPSID is production machine :: ERROR-TRAP
	if [[ ${SAPSID} == *P ]] ; then

		# Print status information
		echo "<table><tr><td><p style="color:Red\;"> ERROR	ERROR	ERROR	ERROR	ERROR	ERROR <br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;"> This Action is Not Allowed On Production System - ${SAPSID}.  <br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;"> Why do you want to run this script on your production system, you need a time off dude !!  <br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Red\;">   <br></p></td></tr></table>" >> ${SCRIPT_LOG}

		# Merge the script log files into the final log now
		cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html

		# Send email about the status
		(
        echo "To: ${mailreceiver}"
        echo "MIME-Version: 1.0"
        echo "Subject: FAILURE:: Activity ${ACTIVITY_TYPE}, Script ${SCRIPT_NAME} Should Never Run on Production Database"
        echo "Content-Type: text/html"
        cat ${LOG_LOC_TGT}/step04_final_log.html
		) | /usr/sbin/sendmail -t
		exit 1
############################## Fast Exit if this script is being run on the production system - End ##############################
	else
############################## Setting SYBASE environment - Begin ###############################
		echo "<table><tr><td><p style="color:Blue\;"> Setting SYBASE database environment now for ${ACTIVITY_TYPE} activity. <br></p></td></tr></table>" >> ${SCRIPT_LOG}

		if [ -f /usr/sap/${SAPSID}/server/SYBASE.sh ]; then
		. /usr/sap/${SAPSID}/server/IQ-16_1/IQ-16_1.sh
		fi # SYBASE environment
		export PATH=/usr/sap/${SAPSID}/server/IQ-16_1/bin64:/bin

		# Completed Setting SYBASE environment
		echo "<table><tr><td><p style="color:Blue\;"> Environment has been set for ${ACTIVITY_TYPE} activity of the SAPIQ Target System ${SAPSID}.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
		echo "<table><tr><td><p style="color:Blue\;"><b><br>${ACTIVITY_TYPE} activity of database ${DBNAME} started at `date +"%T"`.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
############################## Setting SYBASE environment - End ################################

############################### Shutdown the target database - Begin ################################
			# Verify if the database is already running -
			dbping -c DSN=${TGT_DSN} >> ${SCRIPT_LOG}
			ACTIVE_DB_RC="`echo $?`"
			if [ ${ACTIVE_DB_RC} -eq 0 ] ; then
				echo "<table><tr><td><p style="color:Blue\;"><br>We found active database ${DBNAME} on server ${MY_HOSTNAME}.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
				echo "<table><tr><td><p style="color:Blue\;"><br>Shutting down the active db now.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
				#dbstop -y -c "eng=`echo $SAPSID`IQDB_SERVER;LS=SERVER;links=tcpip(host=`hostname`;port=6430);uid=DBA;pwd=companynw04" >> ${SCRIPT_LOG}
				dbstop -y -c DSN=${TGT_DSN} >> ${SCRIPT_LOG}
				# Verify for any active db post the dbstop command
				dbping -c DSN=${TGT_DSN} >> ${SCRIPT_LOG}
				ACTIVE_DB_POST_RC="`echo $?`"
					if [ ${ACTIVE_DB_POST_RC} -eq 1 ] ; then
						echo "<table><tr><td><p style="color:Blue\;"><br>Shutdown of target DB completed successfully, No active database found on server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
					else
						echo "<table><tr><td><p style="color:Red\;"><b><br>Shutdown of target DB failed, still active database found on server ${MY_HOSTNAME}, check immediately.</p></td></tr></table>" >> ${SCRIPT_LOG}
						# Merge the script log files into the final log now
						cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html
						# Send email about the status
						(
						echo "To: ${mailreceiver}"
						echo "MIME-Version: 1.0"
						echo "Subject: FAILURE:: Target DB Shutdown Failed, Please check immediately"
						echo "Content-Type: text/html"
						cat ${LOG_LOC_TGT}/step04_final_log.html
						) | /usr/sbin/sendmail -t
						exit 1
					fi
			else
				echo "<table><tr><td><p style="color:Blue\;"><br>Looks like there is no active database on server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
				echo "<table><tr><td><p style="color:Blue\;"><br>Lets check for the cockpit services now.</p></td></tr></table>" >> ${SCRIPT_LOG}
			fi
		# Shutdown the cockpit service on the target database
		# Verify if the cockpit is already running -
			COCKPIT_COMMAND="/usr/sap/${SAPSID}/server/COCKPIT-4/bin/cockpit.sh"			#Hard-Coded
			COCKPIT_STATUS="`${COCKPIT_COMMAND} -"status" | awk '{print $4}'`"

			if [ ${COCKPIT_STATUS} == running. ] ; then
				echo "<table><tr><td><p style="color:Blue\;"><br>We found cockpit ${COCKPIT_STATUS} on server ${MY_HOSTNAME}.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
				echo "<table><tr><td><p style="color:Blue\;"><br>Shutting down the cockpit now.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
				${COCKPIT_COMMAND} --stop >> ${SCRIPT_LOG}
				COCKPIT_STATUS_CHECK="`${COCKPIT_COMMAND} -status | awk '{print $4}'`"
					if [ ${COCKPIT_STATUS_CHECK} == stopped ] ; then
						echo "<table><tr><td><p style="color:Blue\;"><br>Shutdown of cockpit completed successfully on server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
						echo "<table><tr><td><p style="color:Blue\;"><b><br>DB & Cockpit Services have been shutdown and cleaned up successfully on Target DB server ${MY_HOSTNAME} at `date +"%T"`.</p></td></tr></table>" >> ${SCRIPT_LOG}
						# Merge the script log files into the final log now
						cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html
						# Send email about the status
						(
						echo "To: ${mailreceiver}"
						echo "MIME-Version: 1.0"
						echo "Subject: SUCCESS - ACID Suite ::STEP04:: DB & Cockpit Services have been shutdown and cleaned up successfully on Target DB server ${MY_HOSTNAME}"
						echo "Content-Type: text/html"
						cat ${LOG_LOC_TGT}/step04_final_log.html
						) | /usr/sbin/sendmail -t

					else
						echo "<table><tr><td><p style="color:Red\;"><b><br>Shutdown of cockpit failed, cockpit is still ${COCKPIT_STATUS_CHECK} on server ${MY_HOSTNAME}.</p></td></tr></table>" >> ${SCRIPT_LOG}
						# Merge the script log files into the final log now
						cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html

						# Send email about the status
						(
						echo "To: ${mailreceiver}"
						echo "MIME-Version: 1.0"
						echo "Subject: FAILURE:: Cockpit Shutdown Failed on Target Server, Please check immediately"
						echo "Content-Type: text/html"
						cat ${LOG_LOC_TGT}/step04_final_log.html
						) | /usr/sbin/sendmail -t
						exit 1
					fi
			elif [ ${COCKPIT_STATUS} == stopped ] ; then
				echo "<table><tr><td><p style="color:Blue\;"><br>Looks like there is no cockpit running on server ${MY_HOSTNAME}.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
				echo "<table><tr><td><p style="color:Blue\;"><b><br>DB & Cockpit Services have been shutdown and cleaned up successfully on Target DB server ${MY_HOSTNAME} at `date +"%T"`.</p></td></tr></table>" >> ${SCRIPT_LOG}
						# Merge the script log files into the final log now
						cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html
						# Send email about the status
						(
						echo "To: ${mailreceiver}"
						echo "MIME-Version: 1.0"
						echo "Subject: SUCCESS - ACID Suite ::STEP04:: DB & Cockpit Services have been shutdown and cleaned up successfully on Target DB server ${MY_HOSTNAME}"
						echo "Content-Type: text/html"
						cat ${LOG_LOC_TGT}/step04_final_log.html
						) | /usr/sbin/sendmail -t
			else
				echo "<table><tr><td><p style="color:Red\;"><b><br>Cockpit server on server ${MY_HOSTNAME} looks goofy, please check.</p></td></tr></table>" >> ${SCRIPT_LOG}
						# Merge the script log files into the final log now
						cat ${LOG_LOC_TGT}/step04_header_log.html ${SCRIPT_LOG} >> ${LOG_LOC_TGT}/step04_final_log.html
						# Send email about the status
						(
						echo "To: ${mailreceiver}"
						echo "MIME-Version: 1.0"
						echo "Subject: FAILURE:: Cockpit Server Status on Target Server looks goofy, Please check immediately"
						echo "Content-Type: text/html"
						cat ${LOG_LOC_TGT}/step04_final_log.html
						) | /usr/sbin/sendmail -t
					exit 1
			fi
	fi
exit 0
#End of the script
