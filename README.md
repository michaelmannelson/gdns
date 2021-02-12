# gdns - Global DNS Setter

Helper bash script to easily set the global dns settings to route dns traffic to a desired location.

The motivation to create the script came from my child accidentally yet easily finding content online that was definitely not appropriate for his age, but I can't afford nor am I interested in nanny software that makes his laptop a hassle or unusable. 

To understand how this script works to achieve its original aim, use your favorite search engine to look for "DNS filtering" and read up on it.

# Quick Start

Open a terminal and paste the following lines to quickly setup strong DNS filering:

```
wget "https://github.com/michaelmannelson/gdns/raw/main/gdns.sh"
chmod +x "gdns.sh"
sudo ./gdns.sh -b -c -d CBFF -f ODFS
```

Here are something other options and scenarios:

  Run this to enable the script to be executed
  
  `sudo chmod +x gdns.sh`

  Run with no arguments or -h to see help info
  
  `sudo ./gdns.sh -h`

  Run this to set global dns to [CleanBrowsing](https://cleanbrowsing.org) and [OpenDNS](https://www.opendns.com/home-internet-security)
  
  `sudo ./gdns.sh -b -c -d CBFF -f ODFS`
  
  Run this to reset global dns to original settings
  
  `sudo ./gdns.sh -b -c -d -f`

# Works On
Tested and confirmed to work on the following systems:
  - Pop!_OS 20.04 LTS
