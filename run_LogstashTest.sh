#!/bin/bash

cd /tmp

# Check if Logstash_Test exists 

LST="/tmp/work/Logstash_Test/"
if [ -d "$LST" ]
then
cd $LST
# Update project    
   git pull origin master 
else
   
# Create work folder
 
   mkdir work
   cd work

# Download project

   git clone  https://github.com/RaliZen/Logstash_Test.git
   
# Create data storage folder    
   mkdir lst_reports
fi    

# Check if sincedb exists

DST="/tmp/work/lst_reports/sincedb_sample_orig"
if [ -f "$DST" ] 
then  
   echo "sincedb exists alreaday"
# Remove sincedb
   cd $DST
   echo "Removing sincedb"
   rm sincedb_sample_orig
fi

# Switch to home folder
cd ~
# Run Logstash with the provided data
./logstash-2.4.0/bin/logstash -f "/tmp/work/Logstash_Test/test_orig_sj.conf"&
PID=`pgrep logstash`
echo $PID

sleep 180
kill -9 $PID&
echo "Logstash terminated"







