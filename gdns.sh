#!/bin/bash

#Setup: Run these commands where the script is located
#   sudo chmod +x gdns.sh
#   sudo ./gdns.sh --help

#References
#https://andrea.corbellini.name/2020/04/28/ubuntu-global-dns/
#https://www.raymond.cc/blog/how-to-block-pornographic-websites-without-spending-money-on-software/

declare -r ver="0.0.0.2"
declare -r date=$(date +"%Y%m%d%H%M%S")
declare -r args=("$@")
declare -r epfx="\n~~~"
declare -r esfx=" \n"

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
declare argClean=0
declare argDNS=0
declare argFallback=0
declare argHelp=0
declare argPing=0
declare v=""
declare -a argsDNS=()
declare -a argsFallback=()

declare param=""
for arg in ${args[@]}; do
    declare -a constDNS=()

    if   [ "$arg" == "-b" ] || [ "$arg" == "--backup"   ]; then argBackup=1; continue
    elif [ "$arg" == "-c" ] || [ "$arg" == "--clean"    ]; then argClean=1; continue
    elif [ "$arg" == "-d" ] || [ "$arg" == "--dns"      ]; then argDNS=1; param="dns"; continue;
    elif [ "$arg" == "-f" ] || [ "$arg" == "--fallback" ]; then argFallback=1; param="fallback"; continue;    
    elif [ "$arg" == "-h" ] || [ "$arg" == "--help"     ]; then argHelp=1; continue
    elif [ "$arg" == "-p" ] || [ "$arg" == "--ping"     ]; then argPing=1; continue
    elif [ "$arg" == "-v" ] || [ "$arg" == "--verbose"  ]; then v="v"; continue
    fi

    if   [ "$arg" == "CBFF" ] || [ "$arg" == "CleanBrowsingFamilyFilter"   ]; then constDNS=( "${constCleanBrowsingFamilyFilter[@]}" )
    elif [ "$arg" == "CBAF" ] || [ "$arg" == "CleanBrowsingAdultFilter"    ]; then constDNS=( "${constCleanBrowsingAdultFilter[@]}" )
    elif [ "$arg" == "CBSF" ] || [ "$arg" == "CleanBrowsingSecurityFilter" ]; then constDNS=( "${constCleanBrowsingSecurityFilter[@]}" )
    elif [ "$arg" == "GPD"  ] || [ "$arg" == "GooglePublicDNS"             ]; then constDNS=( "${constGooglePublicDNS[@]}" )
    elif [ "$arg" == "ODFS" ] || [ "$arg" == "OpenDNSFamilyShield"         ]; then constDNS=( "${constOpenDNSFamilyShield[@]}" )
    elif [ "$arg" == "ODH"  ] || [ "$arg" == "OpenDNSHome"                 ]; then constDNS=( "${constOpenDNSHome[@]}" )
    fi

    if   [ "$param" == "dns"      ]; then if [ ${#constDNS[@]} -gt 0 ]; then argsDNS+=( "${constDNS[@]}" ); else argsDNS+=( "$arg" ); fi; continue
    elif [ "$param" == "fallback" ]; then if [ ${#constDNS[@]} -gt 0 ]; then argsFallback+=( "${constDNS[@]}" ); else argsFallback+=( "$arg" ); fi; continue    
    elif [ "$param" == ""         ]; then printf "$epfx ERROR: Invalid argument or flags missing! $esfx"; exit 1
    fi
done

if [ $argHelp -eq 1 ] || [ ${#args[@]} -eq 0 ]; then
    echo "Usage: ./gdns.sh [OPTION]...                          | REQUIRES SUDO PRIVILEGES"
    echo "Version: $ver"
    echo "Helper script for setting global DNS network values"
    echo
    echo "Examples:"
    echo "  ./gdns.sh -d -f                  # Resets all files to original settings"
    echo "  ./gdns.sh -b -d CBFF             # Create backup and set global dns to const"
    echo "  ./gdns.sh -f 8.8.8.8 8.8.4.4     # Sets fallback global dns to given ips"
    echo
    echo "  -b, --backup                Enables creating backups for all modified files"
    echo "  -c, --clean                 Remove all previous backup files"    
    echo "  -d, --dns [ips|consts]      List ips to set for global DNS"
    echo "  -f, --fallback [ips|consts] List ips to set for global fallback DNS"
    echo "  -p, --ping                  Test ip addresses via ping to proceed"
    echo "  -v, --verbose               Output more details about what is being done"
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

if [[ "$EUID" != 0 ]]; then         #https://stackoverflow.com/a/42876846
    printf "$epfx ERROR: Script must run as root to work properly! $esfx"
    exit 1
fi

if [ $argClean -eq 1 ]; then
    if [[ $v == "v" ]]; then printf "$epfx Removing previous backup files $esfx"; fi
    rm -f$v /etc/NetworkManager/conf.d/dns.conf.*.bak
    rm -f$v /etc/systemd/resolved.conf.*.bak
    rm -f$v /etc/resolv.conf.*.bak
    rm -rf$v /tmp/gdns
fi

if [ $argBackup -eq 1 ]; then
    if [[ $v == "v" ]]; then printf "$epfx Creating backup files $esfx"; fi
    cp -f$v /etc/NetworkManager/conf.d/dns.conf /etc/NetworkManager/conf.d/dns.conf.$date.bak    
    cp -f$v /etc/systemd/resolved.conf /etc/systemd/resolved.conf.$date.bak
    cp -f$v --no-preserve=links /etc/resolv.conf /etc/resolv.conf.$date.bak
fi

if [ $argPing -eq 1 ]; then       #https://stackoverflow.com/a/18123263
    if [[ $v == "v" ]]; then printf "$epfx Pinging provided dns ip addresses $esfx"; fi
    for dns in ${argsDNS[@]}; do
        if ping -c 1 "$dns" &> /dev/null 
        then
          printf "  found: \"$dns\" $esfx"
        else
          printf "  ERROR: \"$dns\" $esfx"
          exit 1
        fi
    done
    for fallback in ${argsFallback[@]}; do
        if ping -c 1 "$fallback" &> /dev/null
        then
          printf "  found: \"$fallback\" $esfx"
        else
          printf "  ERROR: \"$fallback\" $esfx"
          exit 1
        fi
    done
fi

if [ $argDNS -eq 1 ] || [ $argFallback -eq 1 ]; then
    declare tmpDir="/tmp/gdns/systemd-resolve/status"
    declare tmpPrev=$date.prev.dat
    declare tmpCurr=$date.curr.dat

    if [[ $v == "v" ]]; then 
        mkdir -p $tmpDir
        systemd-resolve --status | cat > "$tmpDir/$tmpPrev"
    fi

    declare file=""

    file="/etc/NetworkManager/conf.d/dns.conf"
    if [[ $v == "v" ]]; then printf "$epfx Processing $file $esfx"; fi
    if [ ! -f $file ]; then
        touch $file || exit
    fi
    truncate -s 0 $file
    if [ ${#argsDNS[@]} -gt 0 ] || [ ${#argsFallback[@]} -gt 0 ]; then
        echo -e "[main]" | tee -a $file &> /dev/null
        echo -e "dns=none" | tee -a $file &> /dev/null
        echo -e "systemd-resolved=false" | tee -a $file &> /dev/null
    fi
    if [[ $v == "v" ]] && [ $argBackup -eq 1 ]; then 
        printf "$file.$date.bak <---OLD vs NEW---> $file\n"
        diff -wy --suppress-common-lines $file.$date.bak $file
    fi
    
    file="/etc/systemd/resolved.conf"
    if [[ $v == "v" ]]; then printf "$epfx Processing $file $esfx"; fi
    if [ ${#argsDNS[@]} -gt 0 ]; then
        printf -v dns ' %s' "${argsDNS[@]}" && dns=${dns:1}    #https://stackoverflow.com/a/49167382
        sed -r -i "s/^#?DNS=.*/DNS=${dns}/" $file
    elif [ $argDNS -eq 1 ]; then
        sed -r -i "s/^#?DNS=.*/#DNS=/" $file
    fi
    if [ ${#argsFallback[@]} -gt 0 ]; then
        printf -v fallback ' %s' "${argsFallback[@]}" && fallback=${fallback:1}    #https://stackoverflow.com/a/49167382
        sed -r -i "s/^#?FallbackDNS=.*/FallbackDNS=${fallback}/" $file
    elif [ $argFallback -eq 1 ]; then
        sed -r -i "s/^#?FallbackDNS=.*/#FallbackDNS=/" $file
    fi
    if [[ $v == "v" ]] && [ $argBackup -eq 1 ]; then 
        printf "$file.$date.bak <---OLD vs NEW---> $file\n"
        diff -wy --suppress-common-lines $file.$date.bak $file
    fi

    if [[ $v == "v" ]]; then printf "$epfx Flush and restarting networking services $esfx"; fi
    systemd-resolve --flush-caches
    if [ -f "/etc/init.d/dns-clean" ]; then /etc/init.d/dns-clean start; fi
    /etc/init.d/networking restart
    systemctl reload NetworkManager.service
    systemctl restart resolvconf.service
    systemctl restart systemd-resolved.service
    resolvconf -u 2>/dev/null
    
    file="/etc/resolv.conf"
    if [[ $v == "v" ]]; then printf "$epfx Processing $file $esfx"; fi
    rm -f $file
    ln -sf /run/resolvconf/resolv.conf $file
    ln -sf /run/systemd/resolve/resolv.conf $file
    if [[ $v == "v" ]] && [ $argBackup -eq 1 ]; then 
        printf "$file.$date.bak <---OLD vs NEW---> $file\n"
        diff -wy --suppress-common-lines $file.$date.bak $file
    fi
    
    if [[ $v == "v" ]]; then 
        systemd-resolve --status | cat > "$tmpDir/$tmpCurr"
        printf "$epfx Compare networking settings $esfx"
        printf "$tmpDir/$tmpPrev <---OLD vs NEW---> $tmpDir/$tmpCurr\n"
        diff -wy --suppress-common-lines "$tmpDir/$tmpPrev" "$tmpDir/$tmpCurr"
    fi    
fi

if [[ $v == "v" ]]; then printf "$epfx Done! $esfx"; fi

exit 0

