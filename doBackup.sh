#!/bin/bash

# DESCRIPTION
# ------------------

#
# version 1.0-20220814
#
# This script exports all or just selected databases on Microsoft SQL Server,
# pack them into tarball archive and upload the archive to the SMB network
# location (Windows Share).
# Another functionalities are:
# - mounting the network location it the mountpoint is not persistent
# - cleaning up old files (how long backups should be stored - set the number
#   of days in variable)
# 
# It should not be hard to modify the script to suit your needs (upload just on
# hdd, upload to NFS share etc.
#
# >> CAVEATS: Usage of destination and temporary directory. Backup your server
# >> first.
#

# TERMS OF USE
# ------------------

# 2022, blaz@overssh.si
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
#  - The above copyright notice and this permission notice shall be included 
#    in all copies or substantial portions of the Software.
# 
#  - THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
#    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#    DEALINGS IN THE SOFTWARE.


# CONSTANTS
# ------------------

# BACKUP POLICY, < 1 RETAINS FOREVER
# in days
EXPORT_RETENTION=10

# db
sqlusr=dumpuser
sqlpwd=GesloKiJeZeloMocno

# not implemented yet - for more than one database
# replace $databaseToBackup parameter for mysqldump
# with list of databases
databaseToBackup=NameOfDatabase

# DIRECTORIES AND FILENAMES
# where to store dumps
DIR_MSSQLDUMPSTORE=/opt/sqldumps
# where to store TEMPORARY dumps
DIR_MYSQLEXPORTS=/opt/sqldumps_temp
# backup tarball name prefix
BACKUPSTRING_PREFIX=$(hostname)

STAMP=$(date +%y%m%d%H%M%S)

# SCRIPT
# ------------------

# DO CLEANUP
if [[ $EXPORT_RETENTION > 0 ]] ; then
	find $DIR_MSSQLDUMPSTORE* -mtime +$EXPORT_RETENTION -exec rm {} \;
fi

# DO SOME REAL WORK

# create temp directory if it does not exist (using absolute path
# from variable DIR_MYSQLEXPORTS)

# cleanup temporary directory
rm -r $DIR_MYSQLEXPORTS

mkdir -p $DIR_MYSQLEXPORTS

# success or fail?
if [ ! -d "$DIR_MYSQLEXPORTS" ]; then
	echo "mkdir error - check permissions"
	exit 1
fi

mysqldump -u $sqlusr -p$sqlpwd --databases $databaseToBackup > $DIR_MYSQLEXPORTS/$STAMP.sql

# clean destination (if tarball already exists)
rm -f $DIR_MSSQLDUMPSTORE/$BACKUPSTRING_PREFIX_$STAMP.tar.gz

# pack all to destination and do some housekeeping
tar --remove-files -czf \
	$DIR_MSSQLDUMPSTORE/$BACKUPSTRING_PREFIX_$STAMP.tar.gz \
	$DIR_MYSQLEXPORTS/*

