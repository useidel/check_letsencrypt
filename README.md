# check_letsencrypt

A very simply Nagios/Icinga plugin for a basic check if a lets encrypt certificate is about to expire.
The required input is the Common Name (CN) used for the certificate and how you want to perform the check.

This plugin can check a local file using the default file system structure. In that case make sure the the user executing this plugin has read access to the certificate file - either directly or via sudo.
But it can also look up the information in the internet. In that case you it is the tool curl that you need instead local access to something.
Due to some math actions you must have bc installed as well.

Default: it will trigger WARNING if the expiry is more than 10 days but less than 30 days away. If the expiry date is less than 10 days away it will trigger a CRITICAL.
You can configure your own thresholds (see below).


````
$ ./check_letsencrypt.sh 

 This plugin will check if a lets encrypt certificate is about to expire.

 Usage: check_letsencrypt.sh -<h|n> -l|r -w <warning> -c <critical>

   -n: Certifcate Common Name
   -l: Use the certifcate in /etc/letsencrypt/live for the check
   -r: Use http://crt.sh for the check
   -w: WARNING days left for renewal
   -c: CRITICAL days left for renewal

   -h: print this help

$
````
