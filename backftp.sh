##################################################
# Script de Backup FTP by Lordva for Gardenmc.fr #
##################################################

FTP_HOST=""
FTP_USER=""
FTP_PASS=""

PATH_SAVE="/srv"

MYSQL_USER="root"
MYSQL_PASS=""
MYSQL_NAME="sql"

DATE_JOUR=`date +%y%m%d` # Date du jour
DATE_MOINS3=`date --date '1 week ago' +%y%m%d` #date il y a une semaine
#DATE_MOIS=`date --date '3 month ago' +%y%m%d` #date il y a 3 mois
DATE_HIER=`date --date '1 day ago' +%y%m%d` # date de la veille
DATE_AHIER=`date --date '2 days ago' +%y%m%d` # date il y a 2 jours 

SAVE_LOCATION="/home/backup/server"
MYSQL_FILES="/home/backup/mysql"
CONF_FILES="/home/backup/config"
PATH_BACKUP_LOG="/home/backup/logs"

PATH_APACHE="/etc/apache2"
PATH_MYSQL="/etc/mysql"
PATH_PHP="/etc/php"
PATH_PHYMY="/etc/phpmyadmin"

FTP_SRV="server"

#########################################
#Fichier de logs / outputstream		#
#########################################
echo "Debut du script a `date +%X`" >> $LOGFILE

LOGNAME=${DATE_JOUR}"-backuplog.txt"
LOGFILE=${PATH_BACKUP_LOG}"/"${LOGNAME}

############################################
# Sauvegarde des diverses configurations   #
############################################

rm -rf $CONF_FILES
mkdir $CONF_FILES
echo "`date +%X` répertoire [${CONF_FILES}] vidé" >> $LOGFILE

# Préparation des paramètres de compression
CONFNAME=${DATE_JOUR}"-conf.tar.gz"

# Compression
echo "`date +%X` Debut de la compression --> [tar cvfz ${CONF_FILES}/${CONF_NAME} ${PATH_APACHE} ${PATH_MYSQL} ${PATH_PHP} ${PATH_PHPMY}]" >> $LOGFILE
tar cvfz $CONF_FILES"/"$CONFNAME $PATH_APACHE $PATH_MYSQL $PATH_PHP $PATH_PHPMY
RESULT=$?

if [ "$RESULT" != "0" ]; then
        echo "`date +%X` [$0] -->ERREUR TAR, Backup NON effectué." >> $LOGFILE
        echo "************************************************************" >> $LOGFILE
        echo "`date +%X` Fin du script de sauvegarde après erreur         " >> $LOGFILE
        echo "************************************************************" >> $LOGFILE
        exit $RESULT
else
        echo "`date +%X` Compression TAR effectuée avec succès" >> $LOGFILE
fi


####################################################
# Sauvegarde des DB mysql			   #
####################################################

# Préparation des paramétres
FILEMYSQL=${DATE_JOUR}"-sql.sql"

# Dump mysql
echo "`date +%X` Début de la sauvegarde 1 --> [mysqldump --opt -u $MYSQL_USER -p####### -A > $MYSQL_FILES"/"$FILE_MYSQL]" >> $LOGFILE
mysqldump --opt -u $MYSQL_USER -p$MYSQL_PASS -A > $MYSQL_FILES"/"$FILEMYSQL
RESULT=$?

if [ $RESULT != "0" ]; then
	echo "`date +%X` sql -->ERREUR Nr. $RESULT MYSQLDUMP, Dump NON effectué" >> $LOGFILE
	echo "*************************************************************" >> $LOGFILE
	echo "`date +%X` Fin du script de sauvegarde après erreur	   " >> $LOGFILE
	echo "*************************************************************" >> $LOGFILE
	exit $RESULT
else
	echo "`date +%X` Dump MYSQL effectuée avec succès" >> $LOGFILE
fi

####################################################
# Compression des fichiers avec Tar gz             #
####################################################

# Préparation des paramètres de compression
FILENAME=${DATE_JOUR}"-server.tar.gz"

#arret des servers dans /srv
systemctl stop "mcserver@*"
RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, les servers minecraft n'on pas été stoppés" >> $LOGFILE
else
        echo "`date +%X` Les servers minecraft ont été arreté" >> $LOGFILE
fi
systemctl stop bungeecord
RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, le proxy n'a pas été stoppé" >> $LOGFILE
else
        echo "`date +%X` Le proxy a été arreté" >> $LOGFILE
fi
systemctl stop "discord@*"
RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, les bots discord n'on pas été stoppés" >> $LOGFILE
else
        echo "`date +%X` Les bots discord ont été arreté" >> $LOGFILE

fi

# Compression
echo "`date +%X` Debut de la compression --> [tar cvfz $SAVE_LOCATION"/"$FILENAME $PATH_SAVE]" >> $LOGFILE
tar cvfz $SAVE_LOCATION"/"$FILENAME $PATH_SAVE
RESULT=$?

if [ "$RESULT" != "0" ]; then
	echo "`date +%X` [$0] --> ERREUR TAR, Le dossier $PATH_SAVE a surement été modifié lors de la compression." >> $LOGFILE
else
	echo "`date +%X` Compression TAR effectuée avec succès" >> $LOGFILE
	FILESIZE=`du -skh ${SAVE_LOCATION}"/"${FILENAME} | awk '{print $1}'`
	echo "`date +%X` Taille du fichier [${FILENAME}] esi de $FILESIZE" >> $LOGFILE
fi

# Allumage des serveurs
systemctl start "mcserver@*"

RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, les servers minecraft n'on pas été démarrés" >> $LOGFILE
else
        echo "`date +%X` Les servers minecraft ont été démarrés" >> $LOGFILE
fi

systemctl start bungeecord

RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, le proxy n'a pas été démarré" >> $LOGFILE
else
        echo "`date +%X` Le proxy a été démarré" >> $LOGFILE
fi

systemctl start "discord@*"

RESULT=$?
if [ "$RESULT" != "0" ]; then
        echo "`date +%X` Erreur, les bots discord n'on pas été démarrés" >> $LOGFILE
else
        echo "`date +%X` Les bots discord ont été démarrés" >> $LOGFILE
fi


FILE_TO_SAVE=${SAVE_LOCATION}"/"${DATE_JOUR}"-server.tar.gz"
SQL_TO_SAVE=${MYSQL_FILES}"/"${DATE_JOUR}"-sql.sql"
CONF_TO_SAVE=${CONF_FILES}"/"${DATE_JOUR}"-conf.tar.gz"

FTP_MYSQL="mysql"
FTP_CONF="config"

#####################################
# transfert des fichiers sur le ftp #
#####################################

echo "`date +%X` Debut du transfert FTP" >> $LOGFILE

ftp -inv $FTP_HOST << EOF

user $FTP_USER $FTP_PASS

cd $FTP_SRV
put $FILE_TO_SAVE $DATE_JOUR"-server.tar.gz"

cd "/"$FTP_MYSQL
put $SQL_TO_SAVE $DATE_JOUR"-sql.sql"

cd "/"$FTP_CONF
put $CONF_TO_SAVE $DATE_JOUR"-conf.tar.gz"
bye

EOF

EXIT_SAVE=$?

if [ "$EXIT_SAVE" != "0" ]; then
  echo "`date +%X` SAVE ERREUR Le transfert des saves n'a pas été effectué." >> $LOGFILE
	echo "************************************************************" >> $LOGFILE
	echo "`date +%X` Fin du script de sauvegarde après erreur         " >> $LOGFILE
	echo "************************************************************" >> $LOGFILE
	exit $RESULT
else
  echo "`date +%X` transfert de $FILE_TO_SAVE effectué!" >> $LOGFILE
fi

echo "`date +%X` Fin du transfert, on été transferé --> $FILE_TO_SAVE | $SQL_TO_SAVE | $CONF_TO_SAVE" >> $LOGFILE

############################################
# Suppression des vielle sauvegardes	   #
############################################

DELETENAME_MYSQL=${MYSQL_FILES}"/"${DATE_AHIER}"-sql.sql"
DELETENAME_SRV=${SAVE_LOCATION}"/"${DATE_AHIER}"-server.tar.gz"
echo "`date +%X` suppression des vielles DB MYSQL -->[rm $DELETENAME_MYSQL]" >> $LOGFILE
rm -f $DELETENAME_MYSQL
echo "`date +%X` suppression des backups d'hier -->[rm $DELETENAME_SRV"] >> $LOGFILE
rm -f $DELETENAME_SRV

# Compte rendu de fin


echo "************************************************************" >> $LOGFILE
echo "`date +%X` Fin du script de sauvegarde                      " >> $LOGFILE
echo "************************************************************" >> $LOGFILE
echo "" >> $LOGFILE
echo "" >> $LOGFILE

exit 0
