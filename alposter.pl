#!/usr/bin/env perl
# # #
# Alposter: Alpaca flag poster, v1.1
# # #

use strict;
use warnings;
use IO::Socket::INET;

### config
my $remhost = '192.168.1.50';
my $port = 1234;
my $proto = 'tcp';

### flags
my $flag_regex = '\w{6}';

### timeouts
my $wait_after_each_flag = 0;
my $timeout = 1; # for waiting after each flag
my $final_timeout = 2;

###

$| = 1;

print "> Connecting to: $remhost:$port...\n";
my $sock = IO::Socket::INET->new(	PeerAddr	=> $remhost,
                                  PeerPort	=> $port,
                                  Proto		=> $proto,
                                )
  or die "Can't open socket: $!";


my @flags;
my $flag_array_size = 0;
my $filemode = 0;

my $peeraddr = $sock->peerhost();
my $peerport = $sock->peerport();
print "> Connected to: $peeraddr:$peerport\n> Don't be afraid and post some flags.\n";

# arguments are present (filenames)
if (@ARGV) {
  $filemode = 1;
  # generate flag list (from files)
  while (<>) {
    my @tempfl = /$flag_regex/g;
    push @flags, @tempfl;
  }

  $flag_array_size = @flags;
  print "> Flags detected: $flag_array_size\n";
  if ($flag_array_size == 0) {
    exit(0);
  }
}
# read from standard input
else {
  print "> Reading flags from standard input...\n";
}


my $pid = fork();

if ($pid < 0) {
  die "> Cannot fork! $!\n";
}

# child: read from socket
if ($pid == 0) {

  my ($curdata, $data);

  while (sysread($sock, $curdata, 1024)) {
    $data .= $curdata;
    print $curdata;
  }

  print "CONNECTION LOST!!!\n";
  kill SIGTERM => getppid();
}

# parent: write to socket
elsif ($pid > 0) {

  # read from files
  if ($filemode) {
    sleep 1;
    for (@flags) {
      print $sock "$_\n";
      if ($wait_after_each_flag) {
        sleep $timeout;
      }
    }
  }

  # read from standard input
  else {
    while (<STDIN>) {
      if (!$sock->connected) {
        print "CONNECTION LOST\n";
        goto FINISH;
      }
      if (/^q(uit)?$|^e(xit)?$/i) {
        print ">> Quitting... <<<\n";
        goto FINISH;
      }

      # send flags if any
      if (/($flag_regex)/) {
        push @flags, $1;
        print $sock "$1\n";
      }
      else {
        print "> Ooops.. Are you sure it looks like a flag?\n"
      }

    }
  }

  sleep $final_timeout;
  FINISH:
  close $sock;
  kill SIGTERM => $pid;
}

