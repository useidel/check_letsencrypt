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
MYNOW=`date +%s` # Now in Unix Epoch Seconds
# Fetch the expiry date ... but we need to change the format of it
MYEXPIRYDATE=`curl -s https://crt.sh/csv?q=$1|tail -1|awk -F"," '{print $4}'`
# Converting the expiry date to Unix Epoch Seconds
MYEXPIRYDATE=`date -d $MYEXPIRYDATE +%s`
# Check how many seconds are left between now and the expiry date
MYSEC2GO=`echo "$MYEXPIRYDATE - $MYNOW" | bc`

# Take action, i.e. set the EXITSTATUS
if [ $MYSEC2GO -gt 2592000 ];  # more than 30 days in seconds left
then
	EXITSTATUS=0
else
	if [ $MYSEC2GO -gt 864000 ]; # more than 10 days in seconds 
	then
		EXITSTATUS=1
	else
		EXITSTATUS=2	    # less than 10 days in seconds or even expired
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
