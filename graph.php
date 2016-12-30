<!DOCTYPE html>
<html>
<head>
<h2 align = "center">Traffic Analysis</h2><br>
<title>Assignment 1</title>
</head>

<?php
	include "db.php";
	$conn = mysqli_connect($host, $username, $password,$database);

	if (!$conn)
	{
	   die("Connection failed: " . mysqli_connect_error());
	}

//RRD
		$id = $_GET['var'];
		$int = $_GET['var2'];

	$result = mysqli_query($conn,"SELECT * FROM Graphs WHERE id = '$id'");

	while ($row = mysqli_fetch_assoc($result))
	{
		$ip = $row['IP'];
		$ports = $row['PORT'];
		$com = $row['COMMUNITY'];
		$sname = $row['sysname'];

		$nam = explode (",",$row['name']);
		$det = explode (",",$row['descr']);
		
		print "System: $sname "."<br>";

		foreach	($det as $des)
		{
		 $desc = explode (".",$des);
			if ($desc[0]==$int)
			{
			 print "Description : $desc[1]"."<br>";			
			}
		
		}

		foreach ($nam as $ifn)
		{
		 $name = explode(".",$ifn);
		 	if ($name[0]==$int)
		 	{
			 print "ifName : $name[1]"."<br>";	 
			}
		}


	}


		$opts1 = array( "--start", "-1w","--vertical-label=Bytes per second",
                 "DEF:bytesIn=$ip\:$ports\:$com.rrd:bytesIn$int:AVERAGE",
                 "DEF:bytesOut=$ip\:$ports\:$com.rrd:bytesOut$int:AVERAGE",
		 "AREA:bytesIn#00FF00:In traffic",
                 "LINE1:bytesOut#0000FF:Out traffic\\r",
                 "GPRINT:bytesIn:MAX:Max In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:AVERAGE:Avg In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:LAST:Current In\:%6.2lf %SBps\\j",
		 "GPRINT:bytesOut:MAX:Max Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:AVERAGE:Avg Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:LAST:Current Out\:%6.2lf %SBps\\j"
               );
		 #print_r ($opts1);
		 $ret1 = rrd_graph("$ip:$ports:$com:$int.week.png", $opts1);

 		 $opts2 = array( "--start", "-1m","--vertical-label=Bytes per second",
                 "DEF:bytesIn=$ip\:$ports\:$com.rrd:bytesIn$int:AVERAGE",
                 "DEF:bytesOut=$ip\:$ports\:$com.rrd:bytesOut$int:AVERAGE",
		 "AREA:bytesIn#00FF00:In traffic",
                 "LINE1:bytesOut#0000FF:Out traffic\\r",
                 "GPRINT:bytesIn:MAX:Max In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:AVERAGE:Avg In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:LAST:Current In\:%6.2lf %SBps\\j",
		 "GPRINT:bytesOut:MAX:Max Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:AVERAGE:Avg Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:LAST:Current Out\:%6.2lf %SBps\\j"
               );
		 #print_r ($opts2);
		 $ret2 = rrd_graph("$ip:$ports:$com:$int.month.png", $opts2);

		 $opts3 = array( "--start", "-1y","--vertical-label=Bytes per second",
                 "DEF:bytesIn=$ip\:$ports\:$com.rrd:bytesIn$int:AVERAGE",
                 "DEF:bytesOut=$ip\:$ports\:$com.rrd:bytesOut$int:AVERAGE",
		 "AREA:bytesIn#00FF00:In traffic",
                 "LINE1:bytesOut#0000FF:Out traffic\\r",
                 "GPRINT:bytesIn:MAX:Max In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:AVERAGE:Avg In\:%6.2lf %SBps",
                 "GPRINT:bytesIn:LAST:Current In\:%6.2lf %SBps\\j",
		 "GPRINT:bytesOut:MAX:Max Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:AVERAGE:Avg Out\:%6.2lf %SBps",
                 "GPRINT:bytesOut:LAST:Current Out\:%6.2lf %SBps\\j"
               );
	         #print_r ($opts3);
		 $ret3 = rrd_graph("$ip:$ports:$com:$int.year.png", $opts3);

 		if( !is_array($ret1) || !is_array($ret2) || !is_array($ret3))
 		{
 		$err = rrd_error();
  		echo "rrd_graph() ERROR: $err\n";
 		}

?>
<div>
<h4><?php echo "`Daily' Graph (5 Minute Average)"?><br>
<img src=<?php echo "./$ip:$ports:$com:$int.daily.png";?> alt="Daily"></h4>
<br>
</div>

<div>
<h4><?php echo "`Weekly' Graph (30 Minute Average)"?><br>
<img src=<?php echo "./$ip:$ports:$com:$int.week.png"?> alt="Weekly"></h4>
<br>
</div>

<div>
<h4><?php echo "`Monthly' Graph (2 Hour Average)"?><br>
<img src=<?php echo "./$ip:$ports:$com:$int.month.png"?> alt="Monthly"></h4>
<br>
</div>

<div>
<h4><?php echo "`Yearly' Graph (1 Day Average)"?><br>
<img src=<?php echo "./$ip:$ports:$com:$int.year.png"?> alt="Yearly"></h4>
<br>
</div>
<br><br><br><footer><center>Rohit Pothuraju</center></footer>
</html>
