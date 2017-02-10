## pushbullet

Push messages/links/files to your devices from CLI or scripts using [Pushbullet](https://www.pushbullet.com/).

## Required perl modules
* `JSON`
* `HTTP::Request`
* `LWP::UserAgent`

## Setup

Create a file called `pushbullet.conf` in the parent directory as follows:
```
AccessToken:<YOUR_ACCESS_TOKEN>
Name:<YOUR_NAME>
```

## Usage
```
$ perl Pushbullet.pl --help

  Pushbullet.pl [options]

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
```
