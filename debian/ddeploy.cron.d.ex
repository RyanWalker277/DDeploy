#
# Regular cron jobs for the ddeploy package
#
0 4	* * *	root	[ -x /usr/bin/ddeploy_maintenance ] && /usr/bin/ddeploy_maintenance
