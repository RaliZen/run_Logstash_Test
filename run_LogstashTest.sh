#!/bin/bash

cd ~

# Check if Logstash_Test exists 

LST=$(find -type d -name Logstash_Test)
echo $LST 

if [ -d "$LST" ]
then
cd $LST
# Update project    
   git pull origin master 
else
# Download project
   
   git clone  https://github.com/RaliZen/Logstash_Test.git
   
# Create data storage folder    
   mkdir lst_reports
fi    

# Check if sincedb exists
cd ~/lst_reports
DST=$(find -type f -name sincedb_sample_orig)
if [ -f "$DST" ] 
then  
   echo "sincedb exists alreaday"
# Remove sincedb
   cd $DST
   echo "Removing sincedb"
   rm sincedb_sample_orig
fi

cd ~
# Update the path
LST=$(find -type d -name Logstash_Test)
echo $LST

# Run Logstash with the provided data
./logstash-2.4.0/bin/logstash --allow-env -f "$LST/test_orig_sj.conf"&
PID=`pgrep logstash`
echo $PID

sleep 180
kill -9 $PID&
echo "Logstash terminated"







