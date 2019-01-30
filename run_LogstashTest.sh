#!/bin/bash

# Switch to home folder
cd ~
OSV=$(cat /etc/*-release | grep ID_LIKE | cut -c 9-)
echo "$OSV"
# Get user
User=$(whoami)
# Check Java version, then extract only the relevant numbers
JV=$( java -version 2>&1 | grep -o -E '[0-9,.,_]+'| head -n1 )
JVN=$( java -version 2>&1 | tr -dc '0-9' |  cut -c -6  )

if [ -z "$JV"  ]
then
        echo "Installing OpenJDK 1.8.0_191. During the setup you will be prompted to enter your root password."
        # Install Java 8
	#mkdir /usr/java
        #cd /usr/java/
	# Download binary file
	# wget https://download.java.net/java/early_access/jdk8/b03/BCL/jdk-8u202-ea-bin-b03-linux-x64-07_nov_2018.tar.gz
	#tar zxvf jdk-8u202-ea-bin-b03-linux-x64-07_nov_2018.tar.gz
	#rm jdk-8u202-ea-bin-b03-linux-x64-07_nov_2018.tar.gz
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

# Check if git is installed on this PC

G="$(git --version)"
	if [ -z "$G" ]
	then
	       apt-get install git
	fi	       

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
	# Remove logstash.tar when done unpacking
	rm logstash-2.4.0.tar.gz
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

# Check if sincedb has any content. This is a workaround. Sometimes logstash can't find the inode address of the sample file. If however it gets a new address, all runs smoothly. I haven't yet figured out what causes that.
SDB="$(less sincedb_sample_orig)"
if [ -z $SDB ]
then
        cd /tmp/work/Logstash_Test
        rm sample_orig.json
        git checkout .
fi


if grep -q $FSZ sincedb_sample_orig
then	
  	kill -s SIGTERM $PID&
	echo "Logstash terminated"
fi

# Removing logstash_test.log
rm ~/work/logstash_test.log

if [ ! -f "~/work/logstash_test.log" ]
then	
	read -p  "Your report is ready and waiting in /tmp/work/lst_reports. Would you like me to reverse any changes, made to your system [y/n]?" reply
		if [ $reply == "y" ]
		then
			echo "During the reverse setup you will be prompted to enter your root passwort"
        		# Reversing changes
			if [ -z "$JV" ]
			then	
        			echo "Removing OpenJDK 1.8.0_191"
                		read -s -p "Enter your password for sudo: " sudoPW
                		echo $sudoPW | sudo -u $User
			if

			if  [ -z "$G" ]
			then	
               			sudo apt-get remove git
        			sudo apt-get remove openjdk-8-jre-headless
			fi

        	rm -rf /tmp/work/Logstash_Test
		rm /tmp/work/lst_reports/sincedb_orig_json
		rm -rf ~/work
		echo "Your system and settings have been restored"
else
	echo "Exiting"
        break
fi



