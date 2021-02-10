#!/bin/bash

#Released: February 9, 2021
#Version : 0.0.0.1

#Setup: Run these commands where the script is located
#sudo chmod +x gdns.sh
#sudo ./gdns.sh --help

#References
#https://andrea.corbellini.name/2020/04/28/ubuntu-global-dns/
#https://www.raymond.cc/blog/how-to-block-pornographic-websites-without-spending-money-on-software/

declare -r date=$(date +"%Y%m%d%H%M%S")
declare -r args=("$@")

#https://cleanbrowsing.org/filters
declare -r constCleanBrowsingFamilyFilter=("185.228.168.168" "2a0d:2a00:1::" "185.228.169.168" "2a0d:2a00:2::")
declare -r constCleanBrowsingAdultFilter=("185.228.168.10" "2a0d:2a00:1::1" "185.228.169.11" "2a0d:2a00:2::1")
declare -r constCleanBrowsingSecurityFilter=("185.228.168.9" "2a0d:2a00:1::2" "185.228.169.9" "2a0d:2a00:2::2")

#https://developers.google.com/speed/public-dns/docs/using
declare -r constGooglePublicDNS=("8.8.8.8" "2001:4860:4860::8888" "8.8.4.4" "2001:4860:4860::8844")

#https://use.opendns.com/
#https://www.opendns.com/about/innovations/ipv6/
#https://en.wikipedia.org/wiki/OpenDNS
declare -r constOpenDNSFamilyShield=("208.67.222.123" "208.67.220.123" "2620:119:35::35" "2620:119:53::53")
declare -r constOpenDNSHome=("208.67.222.222" "208.67.220.220" "2620:119:35::35" "2620:119:53::53")

declare argBackup=0
declare -a argDNS=()
declare -a argFallback=()
declare argHelp=0
declare argVerify=0

declare param=""
for arg in ${args[@]}; do
    declare -a constDNS=()

    if   [ "$arg" == "-b" ] || [ "$arg" == "--backup"   ]; then param="backup"
    elif [ "$arg" == "-d" ] || [ "$arg" == "--dns"      ]; then param="dns"; continue;
    elif [ "$arg" == "-f" ] || [ "$arg" == "--fallback" ]; then param="fallback"; continue;    
    elif [ "$arg" == "-h" ] || [ "$arg" == "--help"     ]; then param="help"
    elif [ "$arg" == "-v" ] || [ "$arg" == "--verify"   ]; then param="verify"
    fi

    if   [ "$arg" == "CBFF" ] || [ "$arg" == "CleanBrowsingFamilyFilter"   ]; then constDNS=( "${constCleanBrowsingFamilyFilter[@]}" )
    elif [ "$arg" == "CBAF" ] || [ "$arg" == "CleanBrowsingAdultFilter"    ]; then constDNS=( "${constCleanBrowsingAdultFilter[@]}" )
    elif [ "$arg" == "CBSF" ] || [ "$arg" == "CleanBrowsingSecurityFilter" ]; then constDNS=( "${constCleanBrowsingSecurityFilter[@]}" )
    elif [ "$arg" == "GPD"  ] || [ "$arg" == "GooglePublicDNS"             ]; then constDNS=( "${constGooglePublicDNS[@]}" )
    elif [ "$arg" == "ODFS" ] || [ "$arg" == "OpenDNSFamilyShield"         ]; then constDNS=( "${constOpenDNSFamilyShield[@]}" )
    elif [ "$arg" == "ODH"  ] || [ "$arg" == "OpenDNSHome"                 ]; then constDNS=( "${constOpenDNSHome[@]}" )
    fi

    if   [ "$param" == "backup"   ]; then argBackup=1; continue
    elif [ "$param" == "dns"      ]; then if [ ${#constDNS[@]} -gt 0 ]; then argDNS+=( "${constDNS[@]}" ); else argDNS+=( "$arg" ); fi; continue
    elif [ "$param" == "fallback" ]; then if [ ${#constDNS[@]} -gt 0 ]; then argFallback+=( "${constDNS[@]}" ); else argFallback+=( "$arg" ); fi; continue    
    elif [ "$param" == "help"     ]; then argHelp=1; continue
    elif [ "$param" == "verify"   ]; then argVerify=1; continue
    elif [ "$param" == ""         ]; then echo "ERROR: Invalid argument or flags missing"; exit 1
    fi
done

if [ $argHelp -eq 1 ]; then
    echo "Usage: ./gdns.sh [OPTION]...                          | REQUIRES SUDO PRIVILEGES"
    echo "Helper script for global DNS network setting used by /etc/systemd/resolved.conf"
    echo
    echo "Examples:"
    echo "  ./gdns.sh                        # Resets all files to original settings"
    echo "  ./gdns.sh -b                     # Same as previous but also creates backups"
    echo "  ./gdns.sh -b -v -d CBFF          # Same as previous but also set global dns"
    echo "  ./gdns.sh -f 8.8.8.8 8.8.4.4     # Sets fallback global dns to given ips"
    echo
    echo "  -b, --backup               Enables creating backups for all modified files"
    echo "  -d, --dns [ip|const]       List ips to set for global DNS"
    echo "  -f, --fallback [ip|const]  List ips to set for global fallback DNS"
    echo "  -v, --verify               Forces address to be verified by ping to proceed"
    echo
    echo "The following are supported constants [short|long] for public DNS servers:"
    echo
    echo "  CBFF|CleanBrowsingFamilyFilter"
    echo "      ${constCleanBrowsingFamilyFilter[@]}"
    echo "  CBAF|CleanBrowsingAdultFilter"
    echo "      ${constCleanBrowsingAdultFilter[@]}"
    echo "  CBSF|CleanBrowsingSecurityFilter"
    echo "      ${constCleanBrowsingSecurityFilter[@]}"
    echo "  GPD|GooglePublicDNS" 
    echo "      ${constGooglePublicDNS[@]}"
    echo "  ODFS|OpenDNSFamilyShield"
    echo "      ${constOpenDNSFamilyShield[@]}"
    echo "  ODH|OpenDNSHome"
    echo "      ${constOpenDNSHome[@]}"
    echo
    exit 0
fi

#https://stackoverflow.com/a/42876846
if [[ "$EUID" != 0 ]]; then
    echo "Script must run as root to work properly."
    exit 1
fi

#https://stackoverflow.com/a/18123263
if [ $argVerify -eq 1 ]; then
    for dns in ${argDNS[@]}; do
        if ping -c 1 "$dns" &> /dev/null 
        then
          echo \"$dns\" is found
        else
          echo \"$dns\" IS NOT FOUND
          exit 1
        fi
    done
    for dns in ${argFallback[@]}; do
        if ping -c 1 "$dns" &> /dev/null
        then
          echo \"$dns\" is found
        else
          echo \"$dns\" IS NOT FOUND
          exit 1
        fi
    done    
fi

#/etc/NetworkManager/conf.d/dns.conf
if [ ! -f /etc/NetworkManager/conf.d/dns.conf ]; then
    touch /etc/NetworkManager/conf.d/dns.conf || exit
elif [ $argBackup -eq 1 ]; then
    cp /etc/NetworkManager/conf.d/dns.conf /etc/NetworkManager/conf.d/dns.conf.$date.bak
fi
truncate -s 0 /etc/NetworkManager/conf.d/dns.conf
if [ ${#argDNS[@]} -gt 0 ] || [ ${#argFallback[@]} -gt 0 ]; then
    echo -e "[main]" | tee -a /etc/NetworkManager/conf.d/dns.conf &> /dev/null
    echo -e "dns=none" | tee -a /etc/NetworkManager/conf.d/dns.conf &> /dev/null
    echo -e "systemd-resolved=false" | tee -a /etc/NetworkManager/conf.d/dns.conf &> /dev/null
fi

#/etc/systemd/resolved.conf
if [ $argBackup -eq 1 ]; then
    cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.$date.bak
fi
if [ ${#argDNS[@]} -gt 0 ]; then
    printf -v dns ' %s' "${argDNS[@]}" && dns=${dns:1}    #https://stackoverflow.com/a/49167382
    sed -r -i "s/^#?DNS=.*/DNS=${dns}/" /etc/systemd/resolved.conf
else
    sed -r -i "s/^#?DNS=.*/#DNS=/" /etc/systemd/resolved.conf
fi
if [ ${#argFallback[@]} -gt 0 ]; then
    printf -v fallback ' %s' "${argFallback[@]}" && fallback=${fallback:1}    #https://stackoverflow.com/a/49167382
    sed -r -i "s/^#?FallbackDNS=.*/FallbackDNS=${fallback}/" /etc/systemd/resolved.conf
else
    sed -r -i "s/^#?FallbackDNS=.*/#FallbackDNS=/" /etc/systemd/resolved.conf
fi

#/etc/resolv.conf
if [ $argBackup -eq 1 ]; then
    mv /etc/resolv.conf /etc/resolv.conf.$date.backup
else
    rm -f /etc/resolv.conf
fi
ln -nsf /run/resolvconf/resolv.conf /etc/resolv.conf
ln -nsf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# restart services
systemd-resolve --flush-caches
/etc/init.d/networking restart
systemctl reload NetworkManager.service
systemctl restart resolvconf.service
systemctl restart systemd-resolved.service
#resolvconf -u
systemd-resolve --status | cat

echo
echo "Review networking output to verify global DNS settings are correct"
echo 

exit 0

