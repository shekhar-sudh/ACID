#!/bin/bash
#########################################################################################
#                                                                                       #
# Script name:STEP-01_ACID_SRC_Database_Backup.sh                                       #
#                                                                                       #
# Purpose: This Script will take a full backup of the SOURCE IQ database for copyback   #
#                                                                                       #
# Usage Instructions: STEP-01_ACID_SRC_Database_Backup.sh                               #
# Version History: 1.0 by Sudhanshu Shekhar on 02/27/2017                               #
#                  2.0 by Sudhanshu Shekhar on 03/08/2018                               #
# For Support Contact : sudhanshu.shekhar@company.com                                      #
#########################################################################################

############################## Sourcing Variables for the script from the PARAMETERS.conf file - Begin ##############################
echo ""
echo ""
echo "Sourcing the parameter variables into the script now."
source PARAMETERS.conf
echo ""
############################## Sourcing Variables for the script from the PARAMETERS.conf file - End ##############################

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
############################## Echo the parameters obtained from the PARAMETERS.conf file - End ##############################

############################## Setting Variables for this script - Begin ##############################
        SCRIPT_NAME="${0}"
        SAPSID="`whoami | cut -c1-3 | tr '[a-z]' '[A-Z]'`"
        DBNAME="${SAPSID}IQDB"
        BACKUP_DATE="`date +"%m_%d_%Y"`"
        SCRIPT_LOG="${LOG_LOC_SRC}/step01_${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}.html"
        MY_HOSTNAME="`hostname -f`"
############################## Setting Variables for this script - End ##############################

############################## Verify run conditions for this script - Begin ##############################
if [ ${SRC_SID} == ${SAPSID} ] ; then
  echo "Looks like we are running this script on the right DB - ${SRC_SID}"
  if [ ${SRC_HOST} == ${MY_HOSTNAME} ] ; then
        echo "This script is running on the source database ${SAPSID}, on the host ${MY_HOSTNAME}."
        echo "Moving ahead to set up the environment for backup."
  fi
else
  echo "This script is running on the database ${SAPSID}, on the host ${MY_HOSTNAME}. This script must run on the source database."
  echo "" | mailx -s "This script must run on the source database - ${SRC_SID}, Check Immediately" "${mailreceiver}"
  exit 1
fi
############################## Verify run conditions for this script - End ##############################

############################## Remove the script templog file first - Begin ##############################
rm -f `pwd`/step01_log.temp
############################## Remove the script templog file first - End ##############################

############################## Handling the Copyback backup directories - Begin ##############################
        #Remove copyback backups older than previous build
        if [ -d "${DIRBKP_COPYBACK_SRC}_deleteme" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Removing copyback backups from previous than last build. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        rm -rf ${DIRBKP_COPYBACK_SRC}_deleteme >> `pwd`/step01_log.temp
        fi
        #Rename copyback backups from previous than the last build, mark them for deletion
        if [ -d "${DIRBKP_COPYBACK_SRC}_last" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Marking copyback backups from previous than the last build for delete. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mv ${DIRBKP_COPYBACK_SRC}_last ${DIRBKP_COPYBACK_SRC}_deleteme >> `pwd`/step01_log.temp
        fi
        #Rename copyback backups from the last build
        if [ -d "${DIRBKP_COPYBACK_SRC}" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Marking copyback backups from last build to be retained till next build. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mv ${DIRBKP_COPYBACK_SRC} ${DIRBKP_COPYBACK_SRC}_last >> `pwd`/step01_log.temp
        fi
        #Create copyback backup directory for this copyback
        echo "<table><tr><td><p style="color:Blue\;"> Creating directory for performing full backup for this copyback. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mkdir ${DIRBKP_COPYBACK_SRC}
        chmod 775 ${DIRBKP_COPYBACK_SRC}
        if [ -d "${DIRBKP_COPYBACK_SRC}" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Successfully created the backup directory for this copyback activity. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        echo "<table><tr><td><p style="color:Blue\;"> Moving ahead with the activity now. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        else
        echo "<table><tr><td><p style="color:Red\;"> Failed to create the copyback backup directory - ${DIRBKP_COPYBACK_SRC} . <br></p></td></tr></table> " >> `pwd`/step01_log.temp
        echo "" >> `pwd`/step01_log.temp
        mailx -s "Failed to create the copyback backup directory on - ${SRC_SID}, Check Immediately" ${mailreceiver} < `pwd`/step01_log.temp
        exit 1
        fi
############################## Handling the Copyback backup directories - End ##############################

############################## Handling the Copyback log directories - Begin ##############################
        #Remove copyback logs older than previous build
        if [ -d "${SCRIPT_LOC_SRC}/deleteme_copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"><br><br>Removing copyback logs from previous than last build. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        rm -rf ${SCRIPT_LOC_SRC}/deleteme_copybacklogs >> `pwd`/step01_log.temp
        fi
        #Rename copyback logs from previous than the last build, mark them for deletion
        if [ -d "${SCRIPT_LOC_SRC}/last_copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;">Marking copyback logs from previous than the last build for delete in next copyback. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mv ${SCRIPT_LOC_SRC}/last_copybacklogs ${SCRIPT_LOC_SRC}/deleteme_copybacklogs >> `pwd`/step01_log.temp
        fi
        #Rename copyback logs from the last build
        if [ -d "${SCRIPT_LOC_SRC}/copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Marking copyback logs from last build to be retained till next build. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mv ${SCRIPT_LOC_SRC}/copybacklogs ${SCRIPT_LOC_SRC}/last_copybacklogs >> `pwd`/step01_log.temp
        fi
        #Create copyback logs directory for this copyback
        echo "<table><tr><td><p style="color:Blue\;"> Creating directory for keeping logs for this copyback. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        mkdir ${SCRIPT_LOC_SRC}/copybacklogs
        chmod 775 ${SCRIPT_LOC_SRC}/copybacklogs
        if [ -d "${SCRIPT_LOC_SRC}/copybacklogs" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Successfully created directory for keeping logs for this copyback. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        echo "<table><tr><td><p style="color:Blue\;"> Moving ahead with the activity now. <br></p></td></tr></table>" >> `pwd`/step01_log.temp
        # Create the SCRIPT_LOG now & merge the temp log to the SCRIPT_LOG now
        touch ${SCRIPT_LOG}
        cat `pwd`/step01_log.temp > ${SCRIPT_LOG}
        rm -f `pwd`/step01_log.temp
        else
        echo "<table><tr><td><p style="color:Red\;"> Failed to create the directory for keeping logs for this copyback - ${SCRIPT_LOC_SRC}/copybacklogs. <br></p></td></tr></table> " >> `pwd`/step01_log.temp
        echo "" >> `pwd`/step01_log.temp
        mailx -s "Failed to create the directory for keeping logs for this copyback - ${SRC_SID}, Check Immediately" ${mailreceiver} < `pwd`/step01_log.temp
        exit 1
        fi
############################## Handling the Copyback log directories - End ##############################

############################## Verify if the backup directory is accessible - Begin ##############################
if [ -d "${DIRBKP_COPYBACK_SRC}" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> <br><br>Backup Directory ${DIRBKP_COPYBACK_SRC} exists. <br></p></td></tr></table>"  >> ${SCRIPT_LOG}
        echo "<table><tr><td><p style="color:Blue\;"> Moving ahead to set up the environment for backup. <br></p></td></tr></table>" >> ${SCRIPT_LOG}
else
  echo "<table><tr><td><p style="color:Blue\;"> Backup Directory ${DIRBKP_COPYBACK_SRC} Does Not Exist, Check if it is Mounted Properly. <br></p></td></tr></table> " >> ${SCRIPT_LOG}
  echo "" >> ${SCRIPT_LOG}
  mailx -s "${BACKUP_TYPE} Backup Failed for ${DBNAME}, Check Immediately" ${mailreceiver} < ${SCRIPT_LOG}
  exit 1
fi
############################## Verify if the backup directory is accessible - End ##############################

############################## Setting SYBASE environment - Begin ###############################
echo "<table><tr><td><p style="color:Blue\;"><br><br>Setting SYBASE database environment now. <br></p></td></tr></table>" >> ${SCRIPT_LOG}

if [ -f /usr/sap/${SAPSID}/server/SYBASE.sh ]; then
. /usr/sap/${SAPSID}/server/IQ-16_1/IQ-16_1.sh
fi # SYBASE environment
export PATH=/usr/sap/${SAPSID}/server/IQ-16_1/bin64:/bin
echo "<table><tr><td><p style="color:Blue\;"> Environment has been set for triggering the backup of the SAPIQ Source database.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
############################## Setting SYBASE environment - End ################################

############################## Generate runtime variables for other scripts - Begin ################################
echo ""
echo "<table><tr><td><p style="color:Blue\;">Setting the runtime variable BACKUP_DATE for other scripts in ACID Suite.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
echo "#Setting the runtime variable BACKUP_DATE for other scripts in ACID Suite#" > ${LOG_LOC_SRC}/SRC_runtimeVAR.conf
echo "BACKUP_DATE="${BACKUP_DATE}" " >> ${LOG_LOC_SRC}/SRC_runtimeVAR.conf
echo "<table><tr><td><p style="color:Blue\;">Copying the runtime variable file for copyback SCP to the target database.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
cp ${LOG_LOC_SRC}/SRC_runtimeVAR.conf ${DIRBKP_COPYBACK_SRC}/copyback_SRC_runtimeVAR.conf
#Check if the runtime variable file was copied successfully
if [ -f "${DIRBKP_COPYBACK_SRC}/copyback_SRC_runtimeVAR.conf" ]; then
echo "<table><tr><td><p style="color:Blue\;"><br><br> Runtime variable file is copied successfully and ready for SCP to the target db.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
else
# Send email about the failure status
    (
        echo "To: ${mailreceiver}"
        echo "MIME-Version: 1.0"
        echo "Subject: FAILURE:: Could not copy runtime variable file for SCP to the target database, check immediately."
        echo "Content-Type: text/html"
        cat ${SCRIPT_LOG}
    ) | /usr/sbin/sendmail -t
    exit 1
fi

############################## Generate runtime variables for other scripts - End ################################

############################## Trigger the copyback backup on SAPIQ - Begin ################################
echo "<table><tr><td><p style="color:Red\;"><b><br>${BACKUP_TYPE} backup of database ${DBNAME} started at `date +"%T"`.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
# Trigger the backup of SAPIQ database now
   #Lets Create the SQL script for FULL copyback Backup again with new logfile, will overwrite the old script.
   echo "backup database full to '${DIRBKP_COPYBACK_SRC}/${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}' SIZE 50000000 WITH COMMENT '${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}';" > ${SCRIPT_LOC_SRC}/step01_backup_copyback_full.sql

   #Lets trigger the backup using isql
   cd ${SCRIPT_LOC_SRC}
   dbisql -c DSN=${DBNAME} -nogui "step01_backup_copyback_full.sql" >> ${LOG_LOC_SRC}/step01_dbisql_output.tmp

   #Convert the tmp logfile in HTML format
   awk 'BEGIN {print "<table class=\"blueTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${LOG_LOC_SRC}/step01_dbisql_output.tmp > ${LOG_LOC_SRC}/step01_dbisql_output.tmp.html
############################## Trigger the copyback backup on SAPIQ - End ################################

############################## Output Formatting for SAPIQ Copyback Automation - Begin ################################
# Format the script output in HTML/CSS
        # Prepare the header log file for the backup log
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
                                </style>"  > ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html
                echo "<h1 style="color:blue\;text-align:left\;font-size:150%\;"><u>Automated Copyback of IQ Database Suite </u></h1>" >> ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html
                echo "<table><tr><td><p style="color:Blue\;"><b>Step-01. Full Backup of Source DB ${SAPSID}, Completed Successfully.</b><br> <br></p></td></tr></table>" >> ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html

# Merge the HTML log files into the final log now
cat ${SCRIPT_LOG} ${LOG_LOC_SRC}/step01_dbisql_output.tmp.html >> ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html
echo "<table><tr><td><p style="color:Red\;"><b><br> ${BACKUP_TYPE} backup of database ${DBNAME} finished at `date +"%T"`.<br></b></td></tr></table>" >>  ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html

# Report Bugs to the developer
echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.shekhar@company.com">Support</a></address>" >> ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html

############################## Output Formatting for SAPIQ Copyback Automation - End ################################

############################## Send mail with all information - Begin ################################
# Send the Backup Status to the team
#mailx -s "${BACKUP_TYPE} Backup Completed for ${DBNAME}" ${mailreceiver} < ${SCRIPT_LOG}
(
        echo "To: ${mailreceiver}"
        echo "MIME-Version: 1.0"
        echo "Subject: SUCCESS - ACID Suite ::STEP01:: Full Backup of Source SAP IQ DB ${DBNAME} Completed"
        echo "Content-Type: text/html"
        cat ${LOG_LOC_SRC}/step01_source_db_backup_final_log.html
) | /usr/sbin/sendmail -t

exit 0
############################## Send mail with all information - End ################################
#End of the Script
