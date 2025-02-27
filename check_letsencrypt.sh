#!/bin/sh
# check_letstencrypt plugin for Nagios
# Written by Udo Seidel
#
# Description:
#
# This plugin will check if a lets encrypt certificate is about to expire
#
# 


# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

EXITSTATUS=$STATE_UNKNOWN #default


PROGNAME=`basename $0`

print_usage() {
	echo 
	echo " This plugin will check if a lets encrypt certificate is about to expire."
	echo 
	echo 
        echo " Usage: $PROGNAME -<h|n>"
        echo
        echo "   -n: Certifcate CN"
        echo "   -h: print this help"
	echo 
}

if [ "$#" -lt 1 ]; then
	print_usage
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi

check_expiry_date()
{
MYNOW=`date +%s`
MYEXPIRYDATE=`curl -s https://crt.sh/csv?q=$1|tail -1|awk -F"," '{print $4}'`
MYEXPIRYDATE=`date -d $MYEXPIRYDATE +%s`
MYSEC2GO=`echo "$MYEXPIRYDATE - $MYNOW" | bc`
if [ $MYSEC2GO -gt 2592000 ]; 
then
	EXITSTATUS=0
else
	if [ $MYSEC2GO -gt 864000 ];
	then
		EXITSTATUS=1
	else
		EXITSTATUS=2
	fi
fi
}

while getopts "hn" OPT
do		
	case "$OPT" in
	h)
		print_usage
		exit $STATE_UNKNOWN
		;;
	n)
		MYLECN=$2
		;;
	*)
		print_usage
		exit $STATE_UNKNOWN
	esac
done

check_expiry_date $MYLECN
exit $EXITSTATUS
