#!usr/bin/perl

use DBI;    
use Cwd;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort oid_base_match);
use RRD::Simple ();
use Data::Dumper qw(Dumper);

require "dbpath.pl";
require "$realpath";

	$dsn = "DBI:mysql:$database:$host:$port";
	$dbh = DBI->connect($dsn,$username,$password);   

	$uth = $dbh->prepare("CREATE TABLE IF NOT EXISTS Graphs (id int (11) NOT NULL AUTO_INCREMENT, IP tinytext NOT NULL, PORT int (11) NOT NULL, COMMUNITY tinytext NOT NULL, interfaces tinytext NOT NULL,name varchar (1024) NOT NULL, descr varchar (1024) NOT NULL, sysname varchar (100) NOT NULL, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET= latin1 AUTO_INCREMENT=1;");
	$uth->execute() or die $DBI::errstr; 
	
	$fth = $dbh->prepare("INSERT INTO Graphs (IP,PORT,COMMUNITY) SELECT DISTINCT DEVICES.IP, DEVICES.PORT, DEVICES.COMMUNITY FROM DEVICES;");		
	$fth->execute() or die $DBI::errstr;

while (1)
{
	$sth = $dbh->prepare("SELECT * FROM Graphs");
	$sth->execute() or die $DBI::errstr;

%filter;	

while(@row = $sth->fetchrow_array())
{
	$ip = $row[1];
	$ports = $row[2];
	$com = $row[3];

	$filter{"$ip:$ports:$com"} = {
					ip => $ip,
					port => $ports,
					community => $com
				      };

	$oper = '1.3.6.1.2.1.2.2.1.8.';		#ifOperStatus
	$speed = '1.3.6.1.2.1.2.2.1.5.';	#ifSpeed
	$type = '1.3.6.1.2.1.2.2.1.3.';		#ifType
	$index = '1.3.6.1.2.1.2.2.1.1';		#ifIndex		
	$name = '1.3.6.1.2.1.31.1.1.1.1.';	#ifName
	$desc = '1.3.6.1.2.1.2.2.1.2.';		#ifDescr
	$sname = '1.3.6.1.2.1.1.5.0';		#sysname
	$scont = '1.3.6.1.2.1.1.4.0';		#syscontact
	$sloca = '1.3.6.1.2.1.1.6.0';		#syslocation 

# Create the non-blocking SNMP session
($session, $error) = Net::SNMP->session(
   -hostname    => $ip,
   -community   => $com,
   -port        => $ports,
   -nonblocking => 1,
);

$filter{"$ip:$ports:$com"}{session} = $session;

# Was the session created?
if (!defined($session)) {
   printf("ERROR: %s.\n", $error);
}

if (!defined($session->get_table(-baseoid  => $index,
                                 -callback => [\&cback,$ip,$ports,$com])))
{
   printf("ERROR: %s.\n", $session->error());
}

}

snmp_dispatcher();

sub cback
{
	($session, $ip, $ports, $com) = @_;

	foreach (keys (%{$session->var_bind_list()})) 
	{

		$filter{"$ip:$ports:$com"}{interfaces}{$_} = $session->var_bind_list->{$_};	
	}

	foreach (values (%{$filter{"$ip:$ports:$com"}{interfaces}}))
	{
		$ifoper = '1.3.6.1.2.1.2.2.1.8.'. $_;
		$ifspeed = '1.3.6.1.2.1.2.2.1.5.'. $_;
		$iftype = '1.3.6.1.2.1.2.2.1.3.'. $_;			
		push @combo,$ifoper,$ifspeed,$iftype;
	}	
	
	while(@combo)
	{
	@req = splice (@combo, 0, 40);	

	$session->get_request(
                          -callback        => [\&cback2,$ip,$ports,$com],
                          -varbindlist     => \@req,			
                 	);

	snmp_dispatcher();

	}

}	
	
sub cback2
{
	($session,$ip,$ports,$com) = @_;		

	foreach (keys (%{$session->var_bind_list()}))
	{
	 $filter{"$ip:$ports:$com"}{getreq}{$_} = $session->var_bind_list()->{$_};				
	}		

}

	foreach(keys (%filter))
	{
	$ifin = '1.3.6.1.2.1.2.2.1.10.';
	$ifout = '1.3.6.1.2.1.2.2.1.16.';	
	
	($ip,$ports,$com) = split/:/,$_;	
	
	@oct = ();
	@graph = ();

		foreach (values (%{$filter{"$ip:$ports:$com"}{interfaces}}))
		{
		$op = $filter{$ip.":".$ports.":".$com}{getreq}{$oper.$_};
		$sp = $filter{$ip.":".$ports.":".$com}{getreq}{$speed.$_};
		$ty = $filter{$ip.":".$ports.":".$com}{getreq}{$type.$_};

			if (($op == 1) && ($sp != 0) && ($ty != 24))
			{
	 	 	 push @graph,$_;
	 	 	 push @oct,$ifin.$_,$ifout.$_,;
		
			}
		}

	foreach (@graph)
	{
	 $filter{"$ip:$ports:$com"}{filter}{$_} = $_;
	}

	$int = join (".",@graph);
	
	$rth = $dbh->prepare("UPDATE Graphs SET interfaces='$int' WHERE IP='$ip' AND PORT ='$ports' AND COMMUNITY ='$com'");		
	$rth->execute() or die $DBI::errstr;

	while(@oct)
	{
	@ifin = splice (@oct, 0, 40);	

	$filter{"$ip:$ports:$com"}{session}->get_request(
                          				-callback        => [\&cback3,$ip,$ports,$com],
                          				-varbindlist     => \@ifin,			
                       					);	
	snmp_dispatcher();
	}

	}

sub cback3
{
	($session,$ip,$ports,$com) = @_;

		foreach (keys (%{$session->var_bind_list()}))
		{
			$filter{"$ip:$ports:$com"}{bitrate}{$_} = $session->var_bind_list()->{$_};				
		}		

}

	foreach (keys (%filter))
	{
         @det = ();	
	 @update = ();
	 @create = ();

	 ($ip,$ports,$com) = split/:/,$_;	

	if ($filter{"$ip:$ports:$com"}{filter}!=0)
{
	 $rrdfile = "$_.rrd";

	 $rrd = RRD::Simple->new(
         			 file => $rrdfile,
         			 cf => [ qw(AVERAGE) ],
         			 default_dstype => "COUNTER",
         			 on_missing_ds => "add"
     	 				);


	foreach (values %{$filter{"$ip:$ports:$com"}{filter}})
	{			 

	 $name = '1.3.6.1.2.1.31.1.1.1.1.';
	 $descr = '1.3.6.1.2.1.2.2.1.2.';
	 push @det,$name.$_,$descr.$_;

	 $inoct = $filter{"$ip:$ports:$com"}{bitrate}{$ifin.$_};
	 $outoct = $filter{"$ip:$ports:$com"}{bitrate}{$ifout.$_};
	 $bytesIN = "bytesIn$_";
	 $bytesOUT = "bytesOut$_";
	 
	 push @update,"$bytesIN"=>"$inoct","$bytesOUT"=>"$outoct";
	 push @create,"$bytesIN"=>"COUNTER","$bytesOUT"=>"COUNTER";
	}	


	$rrd->create("mrtg",@create) unless -f $rrdfile;
	$rrd->update(time(),@update);
}
	while(@det)
	{
	@det1 = splice (@det, 0, 20);	
	$filter{"$ip:$ports:$com"}{session}->get_request(
                        				-callback        => [\&cback4,$ip,$ports,$com],
                          				-varbindlist     => \@det1,
							);     	
	snmp_dispatcher();              			
	}	
	}		

	sub cback4
	{
	 ($session,$ip,$ports,$com) = @_;
	
	 foreach (keys (%{$session->var_bind_list()}))
		{
		 $filter{"$ip:$ports:$com"}{details}{$_} = $session->var_bind_list()->{$_};				
		}	

	}

	foreach (keys (%filter))
  {
	 ($ip,$ports,$com) = split/:/,$_;	
	 
	 if ($filter{"$ip:$ports:$com"}{filter}!=0)
  	 {
	 @ifname=();
	 @details=();
	 
	 foreach (values %{$filter{"$ip:$ports:$com"}{filter}})
	 {
	 $ifn_str = ();
	 $det_str = ();
	 $ifn = $filter{"$ip:$ports:$com"}{details}{'1.3.6.1.2.1.31.1.1.1.1.'.$_};
	 $det = $filter{"$ip:$ports:$com"}{details}{'1.3.6.1.2.1.2.2.1.2.'.$_};
	 $ifn_st = $_.".".$ifn;
	 $det_st = $_.".".$det;
	 push @ifname,$ifn_st;
	 push @details,$det_st;

	 $ifn_str = join(",",@ifname);
	 $det_str = join(",",@details);
	}
	$rth = $dbh->prepare("UPDATE Graphs SET name='$ifn_str', descr = '$det_str' WHERE IP='$ip' AND PORT ='$ports' AND COMMUNITY ='$com'");		
   	$rth->execute() or die $DBI::errstr;
        }
  }
	
	foreach (keys (%filter))
   	{
	 my $ip,$ports,$com;	 
 	 @det2 = $sname;	
	 ($ip,$ports,$com) = split/:/,$_;	

	 $filter{"$ip".":"."$ports".":"."$com"}{session}->get_request(
                         				-callback        => [\&cback5,$ip,$ports,$com],
                          				-varbindlist     => \@det2,
							);         	
	 snmp_dispatcher();              		
	}		


	sub cback5
	{
	 ($session,$ip,$ports,$com) = @_;

	 foreach (keys (%{$session->var_bind_list()}))
		{
		 $filter{"$ip:$ports:$com"}{details2}{'1.3.6.1.2.1.1.5.0'} = $session->var_bind_list()->{$_};				
		}	

	}

	foreach (keys (%filter))
	{
	my $ip,$ports,$com;	 
	($ip,$ports,$com) = split/:/,$_;	
	$sysname = $filter{"$ip".":"."$ports".":"."$com"}{details2}{'1.3.6.1.2.1.1.5.0'};

	$rth2 = $dbh->prepare("UPDATE Graphs SET sysname ='$sysname' WHERE IP='$ip' AND PORT ='$ports' AND COMMUNITY ='$com'");		
   	$rth2->execute() or die $DBI::errstr;
	}

sleep(120);
}




