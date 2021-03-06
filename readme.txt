										*****	README	*****

Assignment1
-----------

The objective of this assignment is to configure MRTG and also develop a tool which works similar to MRTG. 
The results are presented through a web dashboard.

This document describes the information about the various files in this folder, modules/software needed and steps to run this assignment.

This folder consists of 8 files in total:
-----------------------------------------

1. backend.pl
2. mrtgconf.pl
3. index.php
4. graph.php
5. dbpath.pl
6. db.php
7. readme.txt
8. report.pdf

Software Requirements:
----------------------

1. Operating System: Ubuntu 14.04 LTS.

2. You need to install Apache server, MySQL and PHP.

3. Modules which are needed to be installed from CPAN are:
	 Data::Dumper
	 DBD::Mysql
	 DBI
	 Cwd
	 RRD::Simple
   	 Net::SNMP
             
4. Install packages from terminal (sudo apt-get install ____)
	snmp && snmpd
	rrdtool	 
	librrds-perl		
	php5-rrd

Steps to run this assignment:
-----------------------------
1. Once the database and DEVICES table are setup , modify the db.conf file in the root directory accordingly. The backend scripts will access the 
   database mentioned in db.conf use the device credentials mentioned in the table (IP, PORT and COMMUNITY) to obtain bitrate.

2. Go to the terminal and cd into the directory where this folder is present. 
   (It is assumed that the working directory configured in the apache localhost i.e. /var/www/html/, change the path accordingly) 

3. To configure MRTG, Run the perl script "mrtgconf.pl" in the terminal with the command "perl mrtgconf.pl".

4. To view the MRTG statistics, go to the URL:
   http://localhost/mrtg/

5. To run the network monitoring tool, run the perl script "backend.pl" in the terminal with the command "perl backend.pl".
   The backend will retrieve device credentials from the table, conduct snmp get request to get interfaces of each device, filter the interfaces
   based on ifOperStatus(must be =1), ifType(must not be equal to 24) and ifSpeed(must be >0) and retrieve bitrate for the filtered interfaces.
   RRDs are used to store inOctets and outOctets 
   It will store ifNames and ifDescr of interfaces as well as the sysname of devices in the database.   

6. Now, open a web browser and type the following URL:
   http://localhost/et2536-ropo15/assignment1/
   It will open index.php and show the RRD (daily) graphs of the interfaces of the devices provided in DEVICES table.  

7. Choose the desired device to view the graphs and statistics. Details of the interface and device are shown along with Daily,Weekly,Monthly and Yearly Graphs

NOTE:
-----
1. Make sure to create "DEVICES" table in the MySQL database prior to running the backend script in the terminal. 
   It can be created by following the steps in the readme.txt file in the root directory, for all the 4 assignments.

2. Add the following lines to the file "apache2.conf" before configuring the MRTG.
   The path for file is "/etc/apache2/apache2.conf";

Alias /mrtg "/var/www/mrtg/"
 
<Directory "/var/www/mrtg/">
        Options None
        AllowOverride None
        Require all granted
</Directory>

ServerName localhost:80

3. Restart Apache after adding the above lines to apache2.conf
   sudo service apache2 restart

