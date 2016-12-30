#!usr/bin/perl

use DBI;
use Cwd;
use Data::Dumper qw (Dumper);
require "dbpath.pl";
require "$realpath";

	$dsn = "DBI:mysql:$database:$host:$port";
	$dbh = DBI->connect($dsn,$username,$password);   
	$sth = $dbh->prepare("SELECT * FROM DEVICES");
	$sth->execute() or die $DBI::errstr;

while (@row = $sth->fetchrow_array())
	{
	$id = $row[0];
	$ip = $row[1];
	$ports = $row[2];
	$com = $row[3];

	$node = "$com\@$ip:$ports";
	push @device,$node;	
	}

	$front = join (" ",@device);
	system("cfgmaker --global \"RunAsDaemon:Yes\" --global \"Interval:5\" --global \"WorkDir: /var/www/mrtg\" --global \"Options[_]: growright\" --output /etc/mrtg/mrtg.cfg $front ");
	system("sudo env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg");	
	system("indexmaker /etc/mrtg/mrtg.cfg > /var/www/mrtg/index.html  ");
	
	
