#! /usr/bin/env perl

package Pushbullet;

use strict;
use warnings;

sub new {
  my $class = shift;
  my $configFile = shift;

  my $self = {};
  bless ( $self, $class );

  die "Configuration file [".$configFile."] does not exist!\n" if ( ! -e $configFile );

  $self->{configFile} = $configFile;
  $self->{debug} = 0;
  $self->{readConfigFile} = 0;
  $self->{headerSet} = 0;
  $self->{gotDevices} = 0;
  $self->{ua} = LWP::UserAgent->new;

  # Setup api links
  $self->{base_url} = 'https://api.pushbullet.com/v2/';
  $self->{links} = {
    'myself'  => $self->{base_url} . 'users/me',
    'devices' => $self->{base_url} . 'devices',
    'pushes'  => $self->{base_url} . 'pushes',
  };

  return $self;
}

sub setDebug {
  my $self = shift;
  $self->{debug} = 1;
}

sub usage {
  print <<USAGE;

  $0 [options]

  -h --help         Display this message and exit
  -l --listdevices  List the available devices
  --debug           Turn on debug messages
  --device [ID]     Select a single device by it's ID
  --push [o]        Push message. Options:
                    - note
                    - link
                    - file
  --title           The title of the push notice
  --body            The message of the push notice
  --link            The url to open, used for [--push link] pushes
  --file            File name, used for [--push file] pushes

USAGE

  exit;
}

sub getPostUri {
  my $self = shift;

  print "DEBUG: URI [".$self->{links}->{pushes}."]\n" if ($self->{debug});
  return $self->{links}->{pushes};
}

sub readConfigFile {
  my $self = shift;
  open ( my $fh, "<", $self->{configFile} ) or die "Can't open config file [".$self->{configFile}."]\n";

  while ( my $line = <$fh> ) {
    chomp $line;
    my @data = split /:/, $line;
    $self->{$data[0]} = $data[1];
  }
  close $fh;
  $self->{readConfigFile} = 1;
  print "DEBUG: Config file [".$self->{configFile}."] read successfully \n" if ($self->{debug});
}

sub getAccessToken {
  my $self = shift;
  $self->readConfigFile if (!$self->{readConfigFile});
  die "Couldn't get Access Token!" if (!defined $self->{AccessToken});

  print "DEBUG: Access token [".$self->{AccessToken}."]\n" if ($self->{debug});
  return $self->{AccessToken};
}

sub setupRequestHeader {
  my $self = shift;

  $self->getAccessToken if (!defined $self->{AccessToken});

  $self->{ua}->default_header('Access-Token' => $self->{AccessToken});
  $self->{ua}->default_header('Content-Type' => 'application/json; charset=UTF-8');

  print "DEBUG: Request header set\n" if ($self->{debug});

  $self->{headerSet} = 1;
}

sub getDevices {
  my $self = shift;

  $self->setupRequestHeader if (!$self->{headerSet});

  my $response = $self->{ua}->get($self->{links}->{devices});
  if ($response->is_success) {
    $self->{response} = JSON::decode_json $response->decoded_content;
  } else {
    die $response->status_line;
  }
  $self->{gotDevices} = 1;
}

sub listDevices {
  my $self = shift;

  $self->getDevices if (!$self->{gotDevices});

  print "List of devices\n------------------------------------\n";
  foreach my $device ( @{ $self->{response}->{devices} } ) {
    next if (!defined $device->{manufacturer});
    print "Device: " . $device->{manufacturer} . " " . $device->{model} . " [".$device->{nickname}."]\n";
    print "Device ID [".$device->{iden}."]\n";
    print "------------------------------------\n";
  }
  exit;
}

sub verifyDevice {
  my $self = shift;
  my $dev_id = shift || die "No device ID provided";
  $self->{$dev_id.'-found'} = 0;

  $self->getDevices if (!$self->{gotDevices});

  foreach my $device ( @{ $self->{response}->{devices} } ) {
    if ( $dev_id eq $device->{iden} ) {
      $self->{$dev_id.'-found'} = 1;
    }
  }
}

sub selectDevice {
  my $self = shift;
  my $dev_id = shift || die "No device ID provided";

  $self->verifyDevice($dev_id);

  if ($self->{$dev_id.'-found'}) {
    $self->{selected_device} = $dev_id;
    print "DEBUG: Device successfully selected. ID [".$self->{selected_device}."]\n" if ($self->{debug});
  } else {
    die "Device not found! ID [".$dev_id."]";
  }
}

sub pushIt {
  my $self  = shift;
  my $push  = shift;
  my $title = shift;
  my $body  = shift;
  my $link  = shift;
  my $file  = shift;
  my $content;

  my $uri = $self->getPostUri;
  $self->setupRequestHeader if (!$self->{headerSet});
  my $req = HTTP::Request->new( 'POST', $uri );

  my $data = {
              'title' => $title,
              'body'  => $body,
  };

  # Look if single device selected
  $data->{'device_iden'} = $self->{selected_device} if ($self->{selected_device});

  die "Empty title! Use --title option" if (!$title);
  die "Empty body! Use --body option" if (!$body);

  if (lc($push) eq 'note') {

    $data->{type} = 'note';

  } elsif (lc($push) eq 'link') {

    die "Empty link! Use --link option" if (!$link);
    $data->{type} = 'link';
    $data->{url} = $link;

  } elsif (lc($push) eq 'file') {

    die "File required! Use --file option" if (!$file);
    die "File [".$file."] does not exist!" if (! -e $file);
    $data->{type} = 'file';
    $data->{file_name} = $file;
    my $mime = `file -i $file`;
    chomp($mime);
    my @mime_detail = split /: /, $mime;
    $data->{file_type} = $mime_detail[1];

  } else {
    die "Wrong --push option! Accepted: [note|link|file]";
  }

  $content = JSON::encode_json $data;
  $req->content ( $content );
  my $res = $self->{ua}->request( $req );
  if (!$res->is_success) {
    print "Error [" . $res->status_line . "]\n";
  }
}

1;
