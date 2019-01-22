#!/bin/bash

cd ~
#Check if logstash 2.4.0 is installed on this PC
if [ -d "./work/logstash-2.4.0/" ]
then
	echo "Logstash 2.4.0 already installed"
else
	# Create work folder
	mkdir work
	cd work
	#Download and install Logstash 2.4.0
   	echo "Logstash 2.4.0 is being installed"
   	wget https://download.elastic.co/logstash/logstash/logstash-2.4.0.tar.gz
   	tar -xzf logstash-2.4.0.tar.gz
fi
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

cd /tmp/work/Logstash_Test
FSZ=$(stat -c %s sample_orig.json)
echo $FSZ

# Check if sincedb exists
DST="/tmp/work/lst_reports/sincedb_sample_orig"
if [ -f "$DST" ] 
then  
	echo "sincedb exists alreaday"
	# Remove sincedb
   	cd /tmp/work/lst_reports
   	echo "Removing sincedb"
   	rm sincedb_sample_orig
fi

# Switch to home folder
cd ~
# Run Logstash with the provided data
./work/logstash-2.4.0/bin/logstash -f "/tmp/work/Logstash_Test/test_orig_sj.conf"&

PID=`pgrep logstash`
echo $PID

cd /tmp/work/lst_reports
until [ -f sincedb_sample_orig ]
do
 	sleep 15
done

if grep -q $FSZ sincedb_sample_orig
then	
  	kill -s SIGTERM $PID&
	echo "Logstash terminated"
fi







