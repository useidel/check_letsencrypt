#!/bin/sh
# check_letstencrypt plugin for Nagios
# Written by Udo Seidel
#
# Description:
#
# This plugin will check if a lets encrypt certificate is about to expire
#

CUSTOMWARNCRIT=0 # no external defined warning and critical levels
CATCHLOCAL=0 # check via http://crt.sh per default
WARNLEVEL=30 # predefined Warning level
CRITLEVEL=10 # predefined Critical level


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
        echo " Usage: $PROGNAME -<h|n> -l|r -w <warning> -c <critical>"
        echo
        echo "   -n: Certifcate Common Name"
        echo "   -l: Use the certifcate in /etc/letsencrypt/live for the check"
        echo "   -r: Use http://crt.sh for the check"
        echo "   -w: WARNING days left for renewal"
        echo "   -c: CRITICAL days left for renewal"
	echo
        echo "   -h: print this help"
	echo 
}

if [ "$#" -lt 2 ]; then
	print_usage
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi

check_tools()
{
EXITMESSAGE=""
# run a basic bc to see if it works
echo "2+2" | bc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	EXITMESSAGE="Please install bc"
	EXITSTATUS=$STATE_UNKNOWN
	echo $EXITMESSAGE
	exit $EXITSTATUS
fi

if [ $CATCHLOCAL -ne 1 ]; then
	which curl > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		EXITMESSAGE="Please install curl"
		echo $EXITMESSAGE
		exit $EXITSTATUS
	fi
fi
}

get_expiry_date()
{
# Fetch the expiry date ... but we need to change the format of it
if [ $CATCHLOCAL -ne 1 ] ; then
	MYEXPIRYDATE=`curl -s https://crt.sh/csv?q=$1\&exclude=expired\&deduplicate=Y|tail -1|awk -F"," '{print $4}'`
else
	MYEXPIRYDATE=`sudo openssl x509 -noout -enddate -in /etc/letsencrypt/live/$1/cert.pem | cut -f2 -d '='`
	# the variable will be empty in case of missing file or access to it
	echo $MYEXPIRYDATE | grep '[0-9]' > /dev/null
        if [ $? -ne 0 ]; then
		echo " Missing certificate file or access to it in /etc/letsencrypt/live/$1/"
		echo " Please x-check"
		EXITSTATUS=$STATE_UNKNOWN
		exit $EXITSTATUS
	fi
fi
}

check_expiry_date()
{
MYNOW=`date +%s` # Now in Unix Epoch Seconds
# Converting the expiry date to Unix Epoch Seconds
MYEXPIRYDATE=`echo $MYEXPIRYDATE | date +%s -f -`
if [ $? -ne 0 ]; then
	# something went wrong
	echo "UNKNOWN - expiry date for $MYLECN is not available"
	exit $STATE_UNKNOWN
fi
# Check how many seconds are left between now and the expiry date
MYSECS2GO=`echo "$MYEXPIRYDATE - $MYNOW" | bc`
# If the number of seconds is negativ we can simply stop here -> certificate is expired
if [ $MYSECS2GO -lt 0 ]; then
	echo "UNKNOWN - certificate for $MYLECN is expired"
	exit $STATE_UNKNOWN
fi
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
if [ $MYDAYS2GO -gt $WARNLEVEL ];  # more than Warninglevel days 
then
	echo "OK - $MYDAYS2GO days left for renewal of $MYLECN"
	EXITSTATUS=$STATE_OK
else
	if [ $MYDAYS2GO -gt $CRITLEVEL ]; # more than Criticallevel days 
	then
		echo "WARNING - $MYDAYS2GO days left for renewal of $MYLECN"
		EXITSTATUS=$STATE_WARNING
	else
		echo "CRITICAL - $MYDAYS2GO days left for renewal of $MYLECN"
		EXITSTATUS=$STATE_CRITICAL	    # less than Criticallevel days 
	fi
fi
}

while getopts "hn:lrw:c:" OPT
do		
	case "$OPT" in
	h)
		print_usage
		exit $STATE_UNKNOWN
		;;
	n)
		MYLECN=$2
		;;
	l)
		CATCHLOCAL=1
		;;
	r)
		CATCHLOCAL=0
		;;
        w)
                WARNLEVEL=$5
                CUSTOMWARNCRIT=1
                ;;
        c)
                CRITLEVEL=$7
                CUSTOMWARNCRIT=1
		;;
	*)
		print_usage
		exit $STATE_UNKNOWN
	esac
done

check_tools
get_expiry_date $MYLECN
check_expiry_date $MYLECN
check_warning_critical
compare_dates
exit $EXITSTATUS
