# check_letsencrypt

A very simply Nagios/Icinga plugin for a basic check if a lets encrypt certificate is about to expire.
The required input is the Common Name (CN) used for the certificate. 
Right now it will trigger WARNING if the expiry is more than 10 days but less than 30 days away.
If the expiry date is less than 10 days away it will trigger a CRITICAL.


````
$ ./check_letsencrypt.sh 

 This plugin will check if a lets encrypt certificate is about to expire.


 Usage: check_letsencrypt.sh -<h|n>

   -n: Certifcate CN
   -h: print this help
 
$
````


