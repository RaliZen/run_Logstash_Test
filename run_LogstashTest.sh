#!/bin/bash

# Switch to home folder
cd ~
OSV=$(cat /etc/*-release | grep ID_LIKE | cut -c 9-)
echo "$OSV"
# Get user
User=$(whoami)
# Check Java version, then extract only the relevant numbers
JV=$(java -version 2>&1 |head -n1 | grep -o -E '[0-9,.,_]+'| head -n1 )
CJVR=$(readlink -f /usr/bin/java)
java -version 2>&1 | grep "version" > /dev/null
ISJV=$(echo $?)
update-alternatives --list java | grep java-8-openjdk > /dev/null
ISJV8=$(echo $?)
git --version > /dev/null
G=$(echo $?)

if [ $ISJV -ne 0 ]
then

        echo "Installing OpenJDK 1.8.0_191. During the setup you might be prompted to enter your root password."
        # Install Java 8
        if [ "$OSV" == "debian" ]
	then
		# Installation for Debian-based systems	
        	sudo apt-get install openjdk-8-jre-headless
	else
		# Installation for Red Hat-based systems
		sudo yum -y install openjdk-8-jre-headless
	fi
fi	

if [ $G -ne 0 ]
then

        echo "Installing GIT. During the setup you might be prompted to enter your root password."
        # Install GIT
        if [ "$OSV" == "debian" ]
        then
                # Installation for Debian-based systems
                sudo apt-get install git
        else
                # Installation for Red Hat-based systems
                sudo yum -y install git
        fi
fi

if [ $ISJV8 -eq 0 ] && [ "$JV" != "1.8.0_191" ]
then
        
	echo "You are running OpenJDK Version $JV. To run Logstash you need Version 1.8.0_191 or lower"
	echo "Do you want to switch to OpenJDK Version 1.8.0.191?[y/n]"
	while read -r answ
	do
		if [ "$answ" == "y" ]
		then	
        		echo "Switching OpenJDK Version 1.8.0_191"
        		sudo update-alternatives --set java  /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 
		elif [ "$answ" == "n" ]
		then
			echo "Can not run Logstash Test \ Exiting"
                	
			# Terminate current bash
                        kill -s SIGTERM $$

		else 
       			echo $answ " is not a valid option. Please use "y" for "yes" or "n" for "no"."
			continue
		fi
		break		
	done
elif [ $ISJV8 -ne 0 ]&&[ "$JV" != "1.8.0_191" ]
then	
        echo "You are running OpenJDK Version $JV. To run Logstash you need Version 1.8.0_191 or lower"
        echo "Do you want me to install and setup OpenJDK Version 1.8.0_191[y/n]?" 
  	while read -r answer 
	do
		if [ "$answer" == "y" ]
               	then
                       	echo "During the setup you might be prompted to enter your root passwort"
                       	#Install Java 8
                       	echo "OpenJDK 1.8.0_191 is being installed"
			if [ "$OSV" == "debian" ]
			then
				# Debian-based systems
	                       	sudo apt-get install openjdk-8-jre-headless
                        	sudo update-alternatives --set java  /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 
			else
				# Red Hat-based systems
 				sudo yum -y install openjdk-8-jre-headless
				sudo update-alternatives --set java  /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 
			fi	
                elif [ "$answer" == "n" ]
		then
                       	echo "Can not run Logstash Test \ Exiting"
		 	break
		else
			echo $answer " is not a valid option. Please use "y" for "yes" or "n" for "no"."
			continue	
		fi
		break
	done

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
        if [ ! -d "/tmp/work" ]
	then	
		mkdir work
	fi
        cd work
	# Download project
	git clone  https://github.com/RaliZen/Logstash_Test.git
	# Create data storage folder if doesn't already exist
    	if [ ! -d "/tmp/work/lst_reports" ]
	then	
   		mkdir lst_reports
	fi
fi    
cd /tmp/work/Logstash_Test
# Check the size of the input file
FSZ="$(stat -c %s sample_orig.json)"
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
PIDP=$(pgrep logstash)
PID="$(echo $PIDP | cut -c -5 )"

# Check if process already running

if [ -z "$PID" ]
then 
	sleep 15
fi	

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
if [ -z "$SDB" ]
then
        cd /tmp/work/Logstash_Test
        rm sample_orig.json
        git checkout .
fi


if  grep $FSZ sincedb_sample_orig 
then	
  	kill -s SIGTERM $PID&
	echo "Logstash terminated"
fi

# Removing logstash_test.log
rm ~/work/logstash_test.log

sleep 15

if [ ! -f "~/work/logstash_test.log" ]
then	
	echo "Your report is ready and waiting in /tmp/work/lst_reports. Would you like me to reverse any changes, made to your system [y/n]?"
		while read -r reply
		do
			if [ "$reply" == "y" ]
			then
				echo "During the reverse setup you will be prompted to enter your root passwort"
        			# Reversing changes
				# Checking if Java 8 was already on this PC. If not it will be removed
				if [ $ISJV -ne 0 ]
				then	
        				echo "Removing OpenJDK 1.8.0_191"
					if [ "$OSV" == "debian" ]
					then
						# Debian-based systems
						sudo apt-get remove openjdk-8-jre-headless
					else
						# Red Hat-based systems
						sudo yum -y remove openjdk-8-jre-headless
					fi
				else	
				 	echo "Switching back to OpenJDK $JV"
                                        sudo update-alternatives --set java $CJVR 
                               	fi
				
				if [ $G -ne 0 ]
                                then
                                      echo "Removing GIT"
                                      if [ "$OSV" == "debian" ]
                                      then
                                              # Debian-based systems
                                              sudo apt-get remove git
                                      else
                                              # Red Hat-based systems
                                              sudo yum -y remove git                  
                                      fi
				fi


        			rm -rf /tmp/work/Logstash_Test
				rm /tmp/work/lst_reports/sincedb_sample_orig
				rm -rf ~/work
				echo "Your system and settings have been restored"
			elif [ "$reply" == "n" ]
			then
				echo "Exiting"
				break	
			else
                		echo $reply " is not a valid option. Please use "y" for "yes" and "n" for "no"."
                        	continue
                	fi
                	break
		done

fi
