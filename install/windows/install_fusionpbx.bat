GOTO EndComment
Coder:Len Graham
Len.pgh@gmail.com
:EndComment
@ ECHO OFF
ECHO Use This Install AT YOUR OWN RISK!!!
Echo This will install and configure FusionPBX, FreeSWITCH, PostgreSQL, PHP, NGINX and 7-Zip.
    
    REM //@echo on
     
    	title Install FusionPBX on Windows
	ECHO Let's Install!
	ECHO Please wait just a few moments.....
	
    	
	cd "%USERPROFILE%\Downloads"
	Pause Going to download Freeswitch
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('http://files.freeswitch.org/windows/installer/x64/FreeSWITCH-1.7.0-0a024c4ecb-64bit.msi', 'FreeSWITCH-1.7.0-0a024c4ecb-64bit.msi')"
	powershell -Command "Invoke-WebRequest http://files.freeswitch.org/windows/installer/x64/FreeSWITCH-1.7.0-0a024c4ecb-64bit.msi -OutFile FreeSWITCH-1.7.0-0a024c4ecb-64bit.msi"
	echo Downloading and Installing 7-Zip
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z1514-x64.exe', '7z1514-x64.exe')"
	powershell -Command "Invoke-WebRequest http://www.7-zip.org/a/7z1514-x64.exe -OutFile 7z1514-x64.exe"
	start /wait 7z1514-x64.exe /quiet
	ECHO Going to install Freeswitch
	Pause
  	start /wait freeswitch.msi /quiet
	Pause Going to download Postgresql
	
  	REM //  -Command "(New-Object Net.WebClient).DownloadFile('http://get.enterprisedb.com/postgresql/postgresql-9.4.5-3-windows-x64.exe', 'postgresql-9.4.5-3-windows-x64.exe')"
	powershell -Command "Invoke-WebRequest http://get.enterprisedb.com/postgresql/postgresql-9.4.5-3-windows-x64.exe -OutFile postgresql-9.4.5-3-windows-x64.exe"
	Pause
	ECHO Going to install Postgresql
	
	set database_superuser_password = Default
	echo Enter database_superuser_password
	set /p database_superuser_password=
	
	set system_password = Default1
	echo Enter system_password
	set /p system_password=
	
	echo Downloading postgresql-odbc
	powershell -Command "Invoke-WebRequest https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_05_0100-x64.zip -OutFile psqlodbc_x64.msi"
	echo postgresql-odbc install
	start /wait psqlodbc_x64.msi /quiet
	pause
	
	echo Configure ODBC Administrator
	echo The ODBC Administrator window will open. Go to the System DSN tab and click *ADD* then choose PostgreSQL Unicode(x64) and click finish.  You will have info to fill out. Leave *Data Source* as is, SSLmode disabled and enter the other info. Press *test* to be sure the info is correct.  You should get *connection successful*. Click Save then on. Go back to the script and press the any key ;)
	start "C:\Windows\System32\odbcad32.exe"
	
	echo Download Git
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.6.4.windows.1/Git-2.6.4-64-bit.exe', 'Git-2.6.4-64-bit.exe')"
	powershell -Command "Invoke-WebRequest https://github.com/git-for-windows/git/releases/download/v2.6.4.windows.1/Git-2.6.4-64-bit.exe -OutFile Git-2.6.4-64-bit.exe"
	echo install git
	pause 
	start /wait Git-2.6.4-64-bit.exe /quiet
	del Git-2.6.4-64-bit.exe
	REM // 
	pause
	
	start /wait postgresql-9.4.5-3-windows-x64.exe --mode unattended --superpassword %database_superuser_password% --servicepassword %system_password%
	Pause Going to install NGINX 1.9.9
	cd "C:/"
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('http://nginx.org/download/nginx-1.9.9.zip', 'nginx-1.9.9.zip')"
	powershell -Command "Invoke-WebRequest http://nginx.org/download/nginx-1.9.9.zip -OutFile nginx-1.9.9.zip"
	Pause Going to unzip NGINX
	ECHO Going to UnZip NGINX
	"C:\Program Files\7-Zip\7z.exe" e nginx-1.9.9.zip
	cd "C:/nginx-1.9.9"
	Pause
	REM // needed for php7.0
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe', 'vc_redist.x64.exe')"
	powershell -Command "Invoke-WebRequest https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe -OutFile vc_redist.x64.exe"
	start /wait vc_redist.x64.exe /quiet
	ECHO Going to install PHP 7.0
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('http://windows.php.net/downloads/releases/php-7.0.1-nts-Win32-VC14-x64.zip', 'php-7.0.1-nts-Win32-VC14-x64.zip')"
	powershell -Command "Invoke-WebRequest http://windows.php.net/downloads/releases/php-7.0.1-nts-Win32-VC14-x64.zip -OutFile php-7.0.1-nts-Win32-VC14-x64.zip"
	"C:\Program Files\7-Zip\7z.exe" e php-7.0.1-nts-Win32-VC14-x64.zip
	
	pause
	cd "C:/nginx-1.9.9/html"
	echo Download FusionPBX
	REM // powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/fusionpbx/fusionpbx/archive/master.zip', 'master.zip')"
	REM // powershell -Command "Invoke-WebRequest https://github.com/fusionpbx/fusionpbx/archive/master.zip -OutFile master.zip"
	
	REM // "C:\Program Files\7-Zip\7z.exe" e master.zip
	REM // del master.zip
	echo goto http://localhost to do web gui install part. Come back and press enter to continue after that.
	pause
	
	
	cd "C:/nginx-1.9.9"
	
	pause
	REM // next part need to configure nginx.conf, php.ini(might have this pre-done and cp it from release download)
	
	REM // next part create databases for postgresql
	
    	REM // start nginx etc
    	
    	REM // goto gui to install
