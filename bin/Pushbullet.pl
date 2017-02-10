#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON qw(encode_json decode_json);
use LWP::UserAgent;
use Getopt::Long;
use Data::Dumper;
use HTTP::Request;

use Pushbullet;

my ($help, $debug, $listDevice, $selDevice, $push, $title, $body, $link, $file);
my $Pb = Pushbullet->new("$FindBin::Bin/../pushbullet.conf");

GetOptions(
            "help|h"        => \$help,
            "debug"         => \$debug,
            "listdevices|l" => \$listDevice,
            "device:s"      => \$selDevice,
            "push:s"        => \$push,
            "title:s"       => \$title,
            "body:s"        => \$body,
            "link:s"        => \$link,
            "file:s"        => \$file,
          ) or $Pb->usage;

$Pb->usage if ($help);
$Pb->setDebug if ($debug);
$Pb->listDevices if ($listDevice);
$Pb->selectDevice($selDevice) if ($selDevice);

$Pb->pushIt($push, $title, $body, $link, $file) if ($push);
