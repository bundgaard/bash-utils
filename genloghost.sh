#!/bin/bash


# Author: David Bundgaard


USAGE="\e[1;31m Error \e[0;0m $0 [ --tomcat | --varnish | --apache | --php | --mysql | --nginx ]"


if [ "$1" == "debug" ]; then
    set -x
    shift #if there is more parameters then it will shift to the next one and that will become \$1 :-) Nice function
fi
# Specific port for each application
# varnish 6000
# apache/httpd 6001
# nginx 6002
# mysql 6003
# php 6004
# tomcat 6005

SOFTWARE="undefined"
CLUSTER="undefined" 
SOFTWAREPORT="undefined"
COUNT="1"
OUTPUTFILE="60-${SOFTWARE}-loghost.conf"
LOGHOST="undefined" 

function fileExist() {
    if [ -e "${OUTPUTFILE}" ]; then
        echo -n "${OUTPUTFILE} exists. Continue (y/N): "
        read CONTINUE
        if [[ "${CONTINUE}" =~ "(y|Y)" ]]; then
            return
        elif [[ "${CONTINUE}" =~ "(n|N)" ]]; then
            exit 25
        fi
    fi
}

function checkRoot() {
    if [ $(id -u) != 0 ]; then
        echo "Can only be run as root\n Aborting."
        exit 1
    fi
    if [[ $(id -u) == 0 && "${LOGNAME}" == "root" ]]; then
        echo "Please set your LOGNAME. Aborting\n"
        exit 1
    fi
}

function prepare() {
    echo -n "Enter loghost server: "
    read LOGHOST
}

checkRoot


case $1 in
    --varnish ) 
        unset SOFTWARE
        SOFTWARE="varnish" 
        SOFTWAREPORT="6000"
    ;;
    --tomcat ) 
        unset SOFTWARE
        SOFTWARE="tomcat" 
        SOFTWAREPORT="6005"
    ;;
    --apache ) 
        unset SOFTWARE
        SOFTWARE="httpd"
        COUNT="24" 
        SOFTWAREPORT="6001"
    ;;
    --php ) 
        unset SOFTWARE
        SOFTWARE="php" 
        SOFTWAREPORT="6004"
    ;;
    --mysql ) 
        unset SOFTWARE
        SOFTWARE="mysql" 
        SOFTWAREPORT="6003"
    ;;
    --nginx ) 
        unset SOFTWARE
        SOFTWARE="nginx" 
        SOFTWAREPORT="6002"
    ;;
    *) echo -e "${USAGE}" || exit 2; exit ;;
esac


prepare
HEADER="
# AUTHOR: ${LOGNAME}
# DATE: $(date +%d-%m-%Y\ %H:%m:%S)
# DESCRIPTION: To ship all logs to logstash server\n\n"

# Apache specific
APACHE_TEXT="
"

# More generic
GENERIC_TEXT="
\$ModLoad imfile
\$InputFileName /var/log/DAM/${SOFTWARE}/${CLUSTER}/log.log
\$InputFileTag ${SOFTWARE}-log-tag
\$InputFileStateFile ${SOFTWARE}-log-state
\$InputRunFileMonitor"


FOOTER="
if \$programname == '${SOFTWARE}-log-tag' then @${LOGHOST}:${SOFTWAREPORT}
if \$programname == '${SOFTWARE}-log-tag' then ~
\n\n"

echo -e "${HEADER}"
if [ "${SOFTWARE}" == "httpd" ]; then
    for i in $(seq 1 ${COUNT}); do
        printf "\$ModLoad imfile
                \$InputFileName /var/log/DAM/httpd/${CLUSTER}/access-${i}.log
                \$InputFileTag access-httpd-${i}-log
                \$InputFileStateFile state-access-httpd-${i}-log
                \$InputRunFileMonitor" #>> 50-loghost.conf
    done
else
    echo "${GENERIC_TEXT}" # >> ${OUTPUTFILE}
fi
echo -e "${FOOTER}"

