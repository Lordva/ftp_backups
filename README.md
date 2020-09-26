# FTP Backup script

This bash script create an archive of the folder of your choice, saves your apache, php, and mysql config file as well as saving all your MySQL database.


## Installation

To use the script just clone the repo.
```
git clone https://github.com/Lordva/Download_manager

cd ftp_backups

sudo bash backftp
```
if you dont want the script to run everyday simply do:
```
sudo crontab -e

```
Add this line to the crontab file :
```
0 4 * * * bash /path/to/script/backftp.sh 2>$1 >/dev/null
```

Don't forget to fill the variables at the begining of the script


