#!/bin/bash

# Switch to home folder
cd ~
# Get user
User=$(whoami)
# Check Java version, then extract only the relevant numbers
JV=$( java -version 2>&1 | grep -o -E '[0-9,.,_]+'| head -n1 )
JVN=$( java -version 2>&1 | tr -dc '0-9' |  cut -c -6  )

if [ -z $JVN  ]
then
        echo "Installing OpenJDK 1.8.0_191. During the setup you will be prompted to enter your root password."
        # Install Java 8
        read -s -p "Enter your password for sudo: " sudoPW
        echo $sudoPW | sudo -u $User
        sudo apt-get install openjdk-8-jre-headless
elif [ $JVN -lt 180191 ]
then
        if [ -d "/usr/lib/jvm/java-8-openjdk-amd64/" ]
        then
                echo "Switching OpenJDK Version 1.8.0_191"
                read -s -p "Enter your password for sudo: " sudoPW
                echo $sudoPW | sudo -u $User
                echo 2 | sudo update-alternatives --config java
        else
                echo "You are running OpenJDK Version $JV. To run Logstash you need Version 1.8.0_191 or lower"
                read -p "Do you want me to install and setup OpenJDK Version 1.8.0_191[y/n]?" answer
                if [ $answer == "y" ]
                then
                        echo "During the setup you will be prompted to enter your root passwort"
                        #Install Java 8
                        echo "OpenJDK 1.8.0_191 is being installed"
                        read -s -p "Enter your password for sudo: " sudoPW
                        echo $sudoPW | sudo -u $User
                        sudo apt-get install openjdk-8-jre-headless
                        echo 2 | sudo update-alternatives --config java
                 else
                        echo "Can not run Logstash Test \ Exiting"
			break
                fi
        fi
fi

# Revoking sudo rights 

sudo -k
# Check if logstash 2.4.0 is installed on this PC
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

# Switch to root/tmp folder 
cd /tmp/
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
# Check the size of the input file
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

# Get current logstash process ID
PID="$(pgrep logstash)"

if [ -f  "./work/logstash_test.log" ]
then
	LGPID=$(less ./work/logstash_test.log)
	if [ "$PID" != "$LGPID" ]
	then	
       		echo "Previous Logstash process with ID $LGPID still running. New test can not be started"
		# Terminate Logstash
		kill -s SIGTERM $PID
		# Terminate current bash
		kill -s SIGTERM $$
	fi
else
	echo $PID | tee ./work/logstash_test.log	
fi

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

# Removing logstash_test.log
rm ~/work/logstash_test.log





