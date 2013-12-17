#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Text::CSV_XS;

# convert pcapng to csv
    
my @info = `ls -tr ./pcapng/intray`;
chomp(@info);
pop(@info);
foreach my $i (@info) {
    system("tshark -r ./pcapng/intray/" . $i . " -T fields -e frame.number -e frame.time -e ip.src -e ip.dst -e frame.protocols -e frame.len -e eth.src -e eth.dst -e frame.interface_id -E separator=, -E quote=d > ./csv/intray/" . substr($i, 0, -6) . "csv");
    if ( $? == -1 ) {
		system("mv ./pcapng/intray/" . $i . " ./pcapng/rejected/");
	}
	else
	{
		system("rm -f ./pcapng/intray/" . $i);
	}
}

# insert csv into db

my $dbh = DBI->connect(          
"dbi:SQLite:dbname=./db/network.sqlite", 
"",                          
"",                          
{ RaiseError => 1 },         
) or die $DBI::errstr;

@info = `ls ./csv/intray`;
chomp(@info);

my $sth = $dbh->prepare(<<'SQL');
INSERT INTO Traffic
       (ID, Time, Source_IP, Destination_IP, Protocol, Length, Source_MAC, Destination_MAC, Interface)
VALUES (?,  ?,    ?,         ?,              ?,        ?,      ?,          ?,               ?)
SQL

foreach my $i (@info) {
	my $csv = Text::CSV_XS->new or die;
	open my $fh, "<", "./csv/intray/".$i;

	while(my $row = $csv->getline($fh)) {
   		$sth->execute(@$row);
	}
	$csv->eof;
	close $fh;
	system("rm -f ./csv/intray/" . $i);
}

$sth->finish;

# consolidate uploads by day, source MAC and destination IP.

$sth = $dbh->prepare("select Interface, substr(t.Time, 9,4)||'-'|| m.Number ||'-'||substr(t.Time,5,2) as Day, t.Source_MAC, t.Destination_IP, SUM(t.Length) from Traffic t, Month m where m.Short = substr(t.Time, 1,3) and substr(t.Source_IP,1,7) = '192.168' and substr(t.Destination_IP,1,7) != '192.168' group by Interface, substr(t.Time, 9,4)||'-'|| m.Number ||'-'||substr(t.Time,5,2), t.Source_MAC, t.Destination_IP");
$sth->execute();

while (my $row = $sth->fetchrow_arrayref()) {
	my $sth1 = $dbh->prepare("select Length from Upload where Interface = '".@$row[0]."' and Day = '".@$row[1]."' and Source_MAC = '".@$row[2]."' and Destination_IP = '".@$row[3]."'");
	$sth1->execute();

	my $row1;
	my $sth2;

    if ($row1 = $sth1->fetchrow_arrayref()) {
		my $newLength = @$row[4] + @$row1[0];
    	$sth2 = $dbh->prepare("update Upload set Length = ".$newLength." where Interface = '".@$row[0]."' and Day = '".@$row[1]."' and Source_MAC = '".@$row[2]."' and Destination_IP = '".@$row[3]."'");
    }
    else 
    {
    	$sth2 = $dbh->prepare("insert into Upload (Interface, Day, Source_MAC, Destination_IP, Length) values ('".@$row[0]."', '".@$row[1]."', '".@$row[2]."', '".@$row[3]."', '".@$row[4]."')");
    }
    $sth2->execute();
    $sth2->finish();
    $sth1->finish();
}

$sth->finish();

# consolidate downloads by Day, Destination MAC and Source IP.

$sth = $dbh->prepare("select Interface, substr(t.Time, 9,4)||'-'|| m.Number ||'-'||substr(t.Time,5,2) as Day, t.Destination_MAC, t.Source_IP, SUM(t.Length) from Traffic t, Month m where m.Short = substr(t.Time, 1,3) and substr(t.Destination_IP,1,7) = '192.168' and substr(t.Source_IP,1,7) != '192.168' group by Interface, substr(t.Time, 9,4)||'-'|| m.Number ||'-'||substr(t.Time,5,2), t.Destination_MAC, t.Source_IP");
$sth->execute();

while (my $row = $sth->fetchrow_arrayref()) {
	my $sth1 = $dbh->prepare("select Length from Download where Interface = '".@$row[0]."' and Day = '".@$row[1]."' and Destination_MAC = '".@$row[2]."' and Source_IP = '".@$row[3]."'");
	$sth1->execute();

	my $row1;
	my $sth2;

    if ($row1 = $sth1->fetchrow_arrayref()) {
		my $newLength = @$row[4] + @$row1[0];
    	$sth2 = $dbh->prepare("update Download set Length = ".$newLength." where Interface = '".@$row[0]."' and Day = '".@$row[1]."' and Destination_MAC = '".@$row[2]."' and Source_IP = '".@$row[3]."'");
    }
    else 
    {
    	$sth2 = $dbh->prepare("insert into Download (Interface, Day, Destination_MAC, Source_IP, Length) values ('".@$row[0]."', '".@$row[1]."', '".@$row[2]."', '".@$row[3]."', '".@$row[4]."')");
    }
    $sth2->execute();
    $sth2->finish();
    $sth1->finish();
}

$sth->finish();

# clean up.
$sth = $dbh->prepare("delete from Traffic");
$sth->execute();
$sth->finish();

# reporting




