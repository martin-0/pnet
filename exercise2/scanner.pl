#!/usr/bin/perl
#
# ASSUMPTIONS:
#	- nmap returns port per line
#	- host line always start with "Nmap scan report for"
#	- port line always start with a "number/"
#
# NOTES: 
#	- to avoid loading one big file I'm saving the results to files per IP .. in big big networks I could either put them 
#	into directories depending on the hash of IP, or maybe I can use some db backend (sqlite?)
#

use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;
use JSON;

# parse command line options
my ($debug, $s_target) = (0, "");
GetOptions(     "t|target=s"	=>      \$s_target,
		"d|debug+"	=>	\$debug,
                "h|?|help"      =>      \&usage
        ) or &usage;

# target is required
usage() if ($s_target eq ""); 

# sanity check on input
if ($s_target !~ /^[A-Za-z0-9\.\|\-]+$/ ) {
	print "OOPS: blacklisted character in target specification, aborting.\n";
	exit(1);
}

printf "[I] requested to scan: $s_target\n";

# nmap output scroll
my @scroll = ();

# XXX: few test cases
#open(NMAP, "/usr/bin/nmap -P0 -sS -p 1,22,444,9999,55555 ". $s_target. "|") or die("OOPS: nmap execution failed.\n");
#open(NMAP, "/usr/bin/nmap -sU -sT -p60-70,514 ". $s_target. "|") or die("OOPS: nmap execution failed.\n");
open(NMAP, "/usr/bin/nmap -P0 -sS ". $s_target. "|") or die("OOPS: nmap execution failed.\n");
push @scroll, $_ while(<NMAP>); 
close(NMAP);

dbg_dump_scroll(\@scroll) if ($debug);

# get the scan results from the scroll
my %scan = parse_scroll(\@scroll);

print "[I] hosts scanned: ". (keys %scan) ."\n";

# verify against saved files
foreach my $ip (sort keys %scan) {
	my $js = JSON::XS->new();
	$js->canonical(1);

	# json pairs
	my $json = $js->encode( \%{$scan{$ip}});
	my $old_json = "";
	
	print "DEBUG: JSON: $json\n" if $debug;

	my $fname = $ip.".jsn";

	# if we fail to load the entry we consider it as n/a entry
	if ( ($old_json = load_json($fname)) eq "") {
		if (save_json($fname, $json) != 0 ) { 
			print "WARNING: unable to save results, failed to open $fname for writting!\n";
		}
	}
	else { 
		# if they are the same we have nothing else to do
		print "old json: '$old_json'\nnew json: '$json'\n" if ($debug);

		if ($old_json eq $json) { 
			print "*Target - $ip: No new records found in the last scan.*\n";
			next
		}

		# save new entry
		if (save_json($fname, $json) != 0 ) {
			print "WARNING: unable to save results, failed to open $fname for writting!\n";
		}
	}
	pretty_print($ip, \%{$scan{$ip}});
	print "\n";
}

# parse_scroll(scroll)
sub parse_scroll { 
	my %results = ();
	my ($f_ph, $f_pp, $ip) = (0, 0, "");

	# let's go through all scroll lines
	foreach my $line (@{$_[0]}) { 
		chomp($line);
		# get to the line of the new host
		if (!$f_ph) { 
			next if ( $line !~ /Nmap scan report for/);

			# determine the IP address
			if ( $line =~ /[(]/ ) {
				$ip = $1 if ($line =~ /\((\d+.\d+.\d+.\d+)\)/); 
			}
			else { 
				$ip = $1 if ($line =~  /for (\d+.\d+.\d+.\d+)/);
			}

			if ( $ip eq "" ) {
				print "OOPS: parsing error: unable to determine IP\nDEBUG: line: '$line'\nDEBUG: ip: '$ip'\n";
				exit(1);
			}
			$f_ph = 1;
			next;					# line parsed, go fetch another
		}

		# now we are parsing host, we are interested in only port lines ; skip this till we found one
		# set the flag once found and proceed down with its parsing
		if (!$f_pp) {
			next if ($line !~ /^[0-9]*\//); 
			$f_pp = 1;
		}

		# not a port line any more ? reset flags and continue
		if ($line !~ /^[0-9]*\//) {
			$f_pp = $f_ph = 0;
			next;
		}

		# parse the port line now
		if ( $line =~ /^([0-9]*)\/(\S+)\s+(\S+)\s+(\S+)/) {
			my $port = $1;
			my $proto= $2;
			my $status = $3;
			
			# some udp results can return status on closed ports, we don't want that
			if ($status =~ /closed/) { 
				print "DEBUG2: ignoring closed port : $port\n" if ($debug > 1);
				next;
			}
			$results{$ip}{$port}{$proto} = $status;
		}
		else { 
			print "OOPS: parsing error: unable to parse the port status\n";
			print "DEBUG: line: '$line'\n";
			exit(2);
		}

	}
	return %results;
}

# save_json(fname, json_entry)
sub save_json {
	my ($fname, $json) = ($_[0], $_[1]); 

	open(IPFILE, ">".$fname) or return 1;
	print IPFILE $json . "\n";
	close(IPFILE);
	return 0;
}

# load_json(fname)
sub load_json {
	open(IPFILE, "<".$_[0]) or return "";
	my $json = <IPFILE>;

	chomp($json);
	return $json;
}

# pretty_print(ip, ports)
sub pretty_print {
	my ($ip, %ipref) = ($_[0], %{$_[1]}); 

	print "*Target - $ip: Full scan results:*\n";

	foreach my $port (sort { $a <=> $b} keys %ipref) {
		foreach my $proto (sort keys %{$ipref{$port}}) {
			print "Host: $ip\tPorts: $port/$ipref{$port}{$proto}/$proto////\n";
		}
	}
	print "ip: $ip\n". Dumper(%ipref) if ($debug > 1);
}

sub usage {
	print "usage:\n\t$0 -t <scan target> [-d] | [-h?]\n\n";
	exit(1);
}

sub dbg_dump_scroll {
	print "DEBUG: dumping scroll\n";
	print "DEBUG: $_" foreach (@{$_[0]});
}
