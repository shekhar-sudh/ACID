#!/bin/bash
#########################################################################################
#                                                                                       #
# Script name: STEP-02_ACID_SRC_Generate_Restore_Command.sh                             #
#                                                                                       #
# Purpose: This Script will generate the command for restoring target database  	      #
#                                                                                       #
# Usage Instructions: STEP-02_ACID_SRC_Generate_Restore_Command.Sh                      #
# Version History: 1.0 by Sudhanshu Shekhar on 02/27/2017                               #
#                  2.0 by Sudhanshu Shekhar on 04/09/2018                               #
# For Support Contact : sudhanshu.shekhar@company.com                                      #
#########################################################################################

############################## Sourcing Variables for the script from the PARAMETERS.conf file - Begin ##############################
echo ""
echo ""
echo "Sourcing the parameter variables into the script now."
source PARAMETERS.conf
############################## Sourcing Variables for the script from the PARAMETERS.conf file - End ################################

############################## Sourcing Runtime Variables for the script from the SRC_runtimeVAR.conf file - Begin ##############################
echo ""
echo ""
echo "Sourcing the run time variables into the s
source ${LOG_LOC_SRC}/SRC_runtimeVAR.conf
############################## Sourcing Runtime Variables for the script from the SRC_runtimeVAR.conf file - End ################################

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
echo "Runtime variable BACKUP_DATE is - ${BACKUP_DATE}"
echo ""
############################## Echo the parameters obtained from the PARAMETERS.conf file - End ##############################

############################## Setting Variables for this script - Begin ##############################
        SCRIPT_NAME="${0}"
        SAPSID="`whoami | cut -c1-3 | tr '[a-z]' '[A-Z]'`"
        DBNAME="${SAPSID}IQDB"
        SCRIPT_LOG="${LOG_LOC_SRC}/step02_${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}.html"
        MY_HOSTNAME="`hostname -f`"
        ACTIVITY_TYPE="Generate_Restore_Command"
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

############################## Remove & Re-Touch the log file first - Begin ##############################
rm -f ${SCRIPT_LOG}
touch ${SCRIPT_LOG}
############################## Remove & Re-Touch the log file first - End ################################

############################## Verify if the backup directory is accessible - Begin ##############################
if [ -d "${DIRBKP_COPYBACK_SRC}" ]; then
        echo "<table><tr><td><p style="color:Blue\;"> Backup Directory ${DIRBKP_COPYBACK_SRC} exists. Let us generate the restore command here.<br></p></td></tr></table>"  > ${SCRIPT_LOG}

        echo "<table><tr><td><p style="color:Blue\;"> Moving ahead to set up the environment for generating the restore command. <br></p></td></tr></table>" >> ${SCRIPT_LOG}
else
  echo "<table><tr><td><p style="color:Red\;"> Backup Directory ${DIRBKP_COPYBACK_SRC} Does Not Exist, Check if it is Mounted Properly. <br></p></td></tr></table> " >> ${SCRIPT_LOG}
  echo "" >> ${SCRIPT_LOG}
  mailx -s "${ACTIVITY_TYPE} Activity Failed for ${DBNAME}, Check Immediately" ${mailreceiver} < ${SCRIPT_LOG}
  exit 1
fi
############################## Verify if the backup directory is accessible - End ##############################

############################## Setting SYBASE environment - Begin ###############################
echo "<table><tr><td><p style="color:Blue\;"> Setting SYBASE database environment now. <br></p></td></tr></table>" >> ${SCRIPT_LOG}

if [ -f /usr/sap/${SAPSID}/server/SYBASE.sh ]; then
. /usr/sap/${SAPSID}/server/IQ-16_1/IQ-16_1.sh
fi # SYBASE environment
export PATH=/usr/sap/${SAPSID}/server/IQ-16_1/bin64:/bin
############################## Setting SYBASE environment - End ################################

############################## Generate the restore command for target database - Begin ################################
echo "<table><tr><td><p style="color:Blue\;"> Environment has been set for generating the restore command for the target database.<br></p></td></tr></table>" >> ${SCRIPT_LOG}
echo "<table><tr><td><p style="color:Red\;"><b><br>Activity ${ACTIVITY_TYPE} started at `date +"%T"`.<br></p></td></tr></table>" >> ${SCRIPT_LOG}

# Create sql script for generating the dbfile details of source database
   echo "select DBFileName, Path, DBFileSize from sp_iqfile(); OUTPUT TO ${LOG_LOC_SRC}/step02_dbspace_detail.txt FORMAT ASCII DELIMITED BY ' ' " > ${SCRIPT_LOC_SRC}/step02_dbspace_details_copyback.sql
	#Lets trigger the dbfile details sql using isql
	cd ${SCRIPT_LOC_SRC}
	dbisql -c DSN=${DBNAME} -nogui "step02_dbspace_details_copyback.sql" > ${LOG_LOC_SRC}/step02_dbisql_dbspace_output.tmp

	#Format the dbspace details into the restore command needed for target database
	awk '{ print $1 }' ${LOG_LOC_SRC}/step02_dbspace_detail.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_column1.txt
	awk '{ print $2 }' ${LOG_LOC_SRC}/step02_dbspace_detail.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_column2.txt
	awk '{gsub("\x27",""); print}' ${LOG_LOC_SRC}/step02_dbspace_detail_column1.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_column1_formatted.txt

	paste ${LOG_LOC_SRC}/step02_dbspace_detail_column1_formatted.txt ${LOG_LOC_SRC}/step02_dbspace_detail_column2.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_column_1_2_formatted.txt

rm -f  ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql

	#awk 'BEGIN {print "restore database '/usr/sap/${TGT_SID}/data/db/${TGT_SID}IQDB.db' from '${DIRBKP_COPYBACK_SRC}/${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}'"} {for(i=1;i<=NF;i++) print "rename " $1 " to " $2 " "; } END {print ";"}' ${LOG_LOC_SRC}/step02_dbspace_detail_column_1_2_formatted.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql

  awk 'BEGIN {print "restore database '/usr/sap/${TGT_SID}/data/db/${TGT_SID}IQDB.db' from '${DIRBKP_COPYBACK_SRC}/${DBNAME}_${BACKUP_TYPE}_${BACKUP_DATE}'"} { print "rename " $1 " to " $2 " "; } END {print ";"}' ${LOG_LOC_SRC}/step02_dbspace_detail_column_1_2_formatted.txt > ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql
############################## Generate the restore command for target database - End ################################

############################## Copy the restore command for SCP to target database - End ################################
echo "<table><tr><td><p style="color:Blue\;"><br><br>Copying the generated restore command in ${DIRBKP_COPYBACK_SRC} for SCP to ${TGT_SID}. <br></p></td></tr></table>" >>  ${SCRIPT_LOG}
        if [ -f "${LOG_LOC_SRC}/step02_dbspace_detail_final.sql" ]; then
          rm -f ${DIRBKP_COPYBACK_SRC}/${SRC_SID}_to_${TGT_SID}_${BACKUP_TYPE}_restore_command.sql
          cp ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql ${DIRBKP_COPYBACK_SRC}/${SRC_SID}_to_${TGT_SID}_${BACKUP_TYPE}_restore_command.sql
          # Capture return code of copy command
          RC=$?
              if [ ${RC} -eq 0 ] ; then
              echo "<table><tr><td><p style="color:Blue\;"> Successfully copied the generated restore command ${DIRBKP_COPYBACK_SRC}/${SRC_SID}_to_${TGT_SID}_${BACKUP_TYPE}_restore_command.sql. <br></p></td></tr></table>" >>  ${SCRIPT_LOG}
              else
              echo "<table><tr><td><p style="color:Red\;"> Failed to copy the generated restore command ${DIRBKP_COPYBACK_SRC}/${SRC_SID}_to_${TGT_SID}_${BACKUP_TYPE}_restore_command.sql for scp to ${TGT_SID}. <br></p></td></tr></table> " >>  ${SCRIPT_LOG}
              echo "" >>  ${SCRIPT_LOG}
              #mailx -s "Failed to copy the generated restore command for SCP activity, Check Immediately" ${mailreceiver} <  ${SCRIPT_LOG}
              (
                echo "To: ${mailreceiver}"
                echo "MIME-Version: 1.0"
                echo "Subject: Failed to copy the generated restore command for SCP activity, Check Immediately"
                echo "Content-Type: text/html"
                cat ${SCRIPT_LOG}
              ) | /usr/sbin/sendmail -t
              exit 1
              fi
        else
        echo "<table><tr><td><p style="color:Red\;"> Failed to locate the generated restore command ${DIRBKP_COPYBACK_SRC}/${SRC_SID}_to_${TGT_SID}_${BACKUP_TYPE}_restore_command.sql. <br></p></td></tr></table> " >>  ${SCRIPT_LOG}
        echo "" >>  ${SCRIPT_LOG}
        #mailx -s "Failed to locate the generated restore command, Check Immediately" ${mailreceiver} <  ${SCRIPT_LOG}
              (
                echo "To: ${mailreceiver}"
                echo "MIME-Version: 1.0"
                echo "Subject: Failed to locate the generated restore command for SCP activity, Check Immediately"
                echo "Content-Type: text/html"
                cat ${SCRIPT_LOG}
              ) | /usr/sbin/sendmail -t
        exit 1
        fi
############################## Copy the restore command for SCP to target database - End ################################

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
                                </style>"  > ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html
                echo "<h1 style="color:blue\;text-align:left\;font-size:150%\;"><u>Automated Copyback of IQ Database Suite </u></h1>" >> ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html
                echo "<table><tr><td><p style="color:Blue\;"><b>Step-02. Generate Restore Command for Target DB ${TGT_SID}, Below are the details -</b><br> <br></p></td></tr></table>" >> ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html

# Convert the step02_dbspace_detail_final.sql into HTML format for reporting via email
echo "<table><tr><td><p style="color:Blue\;">`cat ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql` <br></p></td></tr></table>" > ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql.html
echo "<table><tr><td><p style="color:Red\;"><b><br> Activity ${ACTIVITY_TYPE} finished at `date +"%T"`.<br></b></td></tr></table>" >>  ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql.html

# Merge the HTML log files into the final log now
cat ${SCRIPT_LOG}  ${LOG_LOC_SRC}/step02_dbspace_detail_final.sql.html >> ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html

# Report Bugs to the developer
echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.shekhar@company.com">Support</a></address>" >> ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html
############################## Output Formatting for SAPIQ Copyback Automation - End ################################

############################## Send mail with all information - Begin ################################
# Send the Backup Status to the team
#mailx -s "${ACTIVITY_TYPE} Backup Completed for ${DBNAME}" ${mailreceiver} < ${SCRIPT_LOG}
(
        echo "To: ${mailreceiver}"
        echo "MIME-Version: 1.0"
        echo "Subject: SUCCESS - ACID Suite ::STEP02:: Restore Command Generated for Target Database ${TGT_SID}"
        echo "Content-Type: text/html"
        cat ${LOG_LOC_SRC}/step02_generate_restore_command_final_log.html
) | /usr/sbin/sendmail -t

exit 0
############################## Send mail with all information - Begin ################################
#End of the Script
