# gdns - Global DNS Setter

Helper bash script to easily set the global dns settings to route dns traffic to a desired location.

The motivation to create the script came from my child accidentally yet easily finding content online that was definitely not appropriate for his age, but I can't afford nor am I interested in nanny software that makes his laptop a hassle or unusable. 

To understand how this script works to achieve its original aim, use your favorite search engine to look for "DNS filtering" and read up on it.

# Quick Start
Download the script, open a terminal, and run the following commands where the file is located:

  #Run this to enable the script to be executed
  
  sudo chmod +x gdns.sh

  #Run this to set global DNS filter
  
  sudo ./gdns.sh -b -c -p -v -d CBFF -f ODFS
  
  #Run this to reset global DNS to original settings
  
  sudo ./gdns.sh -b -c -p -v -d -f

# Works On
Tested and confirmed to work on the following systems:
  - Pop!_OS 20.04 LTS
