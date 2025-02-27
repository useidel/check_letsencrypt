#!/bin/sh
# check_letstencrypt plugin for Nagios
# Written by Udo Seidel
#
# Description:
#
# This plugin will check if a lets encrypt certificate is about to expire
#

CUSTOMWARNCRIT=0 # no external defined warning and critical levels
WARNLEVEL=30
CRITLEVEL=10


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
        echo " Usage: $PROGNAME -<h|n> -w <warning> -c <critical>"
        echo
        echo "   -n: Certifcate Common Name"
        echo "   -w: WARNING days left for renewal"
        echo "   -c: CRITICAL days left for renewal"
	echo
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
MYSECS2GO=`echo "$MYEXPIRYDATE - $MYNOW" | bc`
# Convert the seconds in days
MYDAYS2GO=`echo "$MYSECS2GO / 3600 / 24" | bc`
}

check_warning_critical() 
{
if [ $CUSTOMWARNCRIT -ne 0 ]; then
        # check if the levels are integers
        echo $WARNLEVEL | awk '{ exit ! /^[0-9]+$/ }'
        if [ $? -ne 0 ]; then
                echo " warning level ($WARNLEVEL) is not an integer"
                exit $STATE_UNKNOWN
        fi
        echo $CRITLEVEL | awk '{ exit ! /^[0-9]+$/ }'
        if [ $? -ne 0 ]; then
                echo " critical level ($CRITLEVEL) is not an integer"
                exit $STATE_UNKNOWN
        fi
        if [ $WARNLEVEL -lt $CRITLEVEL ]; then
                echo
                echo " The value for critical level has to be equal or lower than the one for warning level"
                echo " Your values are: critcal ($CRITLEVEL) and warning ($WARNLEVEL)"
                echo
                exit $STATE_UNKNOWN
        fi
fi
}

compare_dates(){
# Take action, i.e. set the EXITSTATUS
if [ $MYDAYS2GO -gt $WARNLEVEL ];  # more than Warninglevel days in seconds left
then
	echo "OK - $MYDAYS2GO left for renewal of $MYLECN"
	EXITSTATUS=0
else
	if [ $MYDAYS2GO -gt $CRITLEVEL ]; # more than Criticallevel days in seconds 
	then
		echo "WARNING - $MYDAYS2GO left for renewal of $MYLECN"
		EXITSTATUS=1
	else
		echo "CRITICAL - $MYDAYS2GO left for renewal of $MYLECN"
		EXITSTATUS=2	    # less than Criticallevel days in seconds or even expired
	fi
fi
}

while getopts "hn:w:c:" OPT
do		
	case "$OPT" in
	h)
		print_usage
		exit $STATE_UNKNOWN
		;;
	n)
		MYLECN=$2
		;;
        w)
                WARNLEVEL=$4
                CUSTOMWARNCRIT=1
                ;;
        c)
                CRITLEVEL=$6
                CUSTOMWARNCRIT=1
		;;
	*)
		print_usage
		exit $STATE_UNKNOWN
	esac
done

check_expiry_date $MYLECN
check_warning_critical
compare_dates
exit $EXITSTATUS
