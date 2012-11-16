Migration Instructions
	FusionPBX 2.0 to 3.0.x
	Need assistance: http://www.fusionpbx.com/support.php

1. Check revision number.
	svn info

2. If you are below version 1877 then update to the version 1877.
	svn update -r1877

3. Make sure the current system is updated with the latest database structure.
	cd /var/www/fusionpbx
	php /var/www/fusionpbx/core/upgrade/upgrade.php

4. Ensure that you can login and see the menu before upgrading further.

5. If using MySQL or Postgres Create a new database one way to do that is using advanced -> adminer.
	Any database name you want to use will work for these instructions we will use a database name of fusionpbx3.

6. Download the export PHP Script
	cd /var/www/fusionpbx
	wget http://fusionpbx.googlecode.com/svn/trunk/scripts/upgrade/r1877-export.php

7. Make a backup of the FusionPBX PHP directory and the FreeSWITCH conf directory.
	cp -R /var/www/fusionpbx var/www/fusionpbx-bak
	cp -R /usr/local/freeswitch/conf /usr/local/freeswitch/conf-bak

8. Change the top of the script where and set the database you want to export the data to.
	$db_type = "sqlite"; //pgsql, sqlite, mysql

9. Upload it to the root of your server

10. Login to the using the web interface.

11. Run the 1877-export.php script if it was placed in the web directory you would run it with the following url.
	http://x.x.x.x/r1877-export.php

12. Save the sql file.

13. Move the sql file to the server then import the sql code into the database.
	a. For postgres you can import the sql file into the database by using the following command.
		su postgres
		psql -U postgres -d fusionpbx3 -f /tmp/database_backup.sql -L sql.log
	b. For sqlite you need to use sqlite by command line.
		1. Assuming fusionpbx is installed to /var/www/fusionpbx and the database is called fusionpbx.db
		2. Move the old database to a new name
			mv /var/www/fusionpbx/secure/fusionpbx.db /var/www/fusionpbx/secure/fusionpbx-version2.db
		3. Import the sql file into the sqlite database
			Debian / Ubuntu Server
			apt-get install sqlite3
			sqlite3 /var/www/fusionpbx/secure/fusionpbx.db < /tmp/database_backup.sql
		4. Make sure the database is writeable

14. Edit fusionpbx/includes/config.php change the database name to the new database.

15. Update the source code to 3.0.x
	svn update

16. Login with the web browser.

17. Update the menu by going to:
	http://x.x.x.x/core/menu/menu.php then edit the menu and press 'restore default'

18. Update the permissions.
	Go to advanced -> group manager edit the permissions for the superadmin group
	Select the permissions you that are not select in the list when finished press save.

19. Logout of the web interface to clear the session.

20. For multi-tenant systems delete the domain based dialplan xml files in.
	rm /usr/local/freeswitch/conf/dialplans/replace_with_the_domain_name.xml

21. Upgrade FusionPBX
	cd /var/www/fusionpbx
	/usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php

22. Go to Advanced -> XML Editor
	Expand 'autoload_configs'
	Click on xml_cdr.conf.xml
	At <param name="url" remove /mod/ and replace it with /app/
	Status -> SIP Status press 'reloadxml'
	System -> Modules restart XML CDR.

23. Upgrade is complete.
