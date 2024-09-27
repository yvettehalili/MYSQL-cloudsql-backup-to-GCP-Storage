#!/bin/bash
TMP_PATH="/backup/dumps/"
BACKUPS_PATH="/root/cloudstorage/Backups/Current/"
BUCKET_PATH="/root/cloudstorage/" #
BUCKET="ti-sql-02"
SSL_PATH="/ssl-certs/"

# Unmount bucket if it's already mounted.
#fusermount -u  $BUCKET_PATH

# Mount bucket
#gcsfuse --key-file=/root/jsonfiles/ti-ca-infrastructure-d1696a20da16.json $BUCKET $BUCKET_PATH

# Build dump and send to bucket
DB_USR=GenBackupUser
DB_PWD=DBB@ckuPU53r*

LDUMP_DATE=$(date +"%Y-%m-%d %H:%M:%S") # This must be the value of the last time backup/dump was executed.
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
CUR_DATE=$(date +"%Y-%m-%d")
DAY=$(date +"%u")

SERVERS_LIST="/backup/configs/ti-mysql-us-we-14.csv"
#if mount | grep -q /root/cloudstorage;
#then
readarray -t lines < "${SERVERS_LIST}"

printf "================================== ${CUR_DATE} =============================================\n"

for line in "${lines[@]}"; do
        column_values=$(echo $line | tr "," "\n")
        I=0
        for value in $column_values
        do
                if [ $I == 0 ]
                then
                        SERVER=$value
                elif [ $I == 1 ]
                then
                        HOST=$value
                elif [ $I == 2 ]
                then
                        SSL=$value
                fi
                I=$((I+1))
        done

        DB_HOST=$HOST
        printf "${TIMESTAMP}: DUMPING SERVER: ${SERVER}\n"
        if [ "$SSL" != "y" ]; then
                DB_LIST=$(mysql -u$DB_USR -p$DB_PWD -h $DB_HOST --default-auth=mysql_native_password -Bs -e "SHOW DATABASES")
        else
                #printf "${SSL_PATH}${SERVER}/${SERVER}-server-ca.pem\n"
                #printf "${SSL_PATH}${SERVER}/${SERVER}-client-cert.pem\n"
                #printf "${SSL_PATH}${SERVER}/${SERVER}-client-key.pem\n"

                DB_LIST=$(mysql -u$DB_USR -p$DB_PWD -h $DB_HOST \
                        --ssl-ca="${SSL_PATH}${SERVER}/server-ca.pem" \
                        --ssl-cert="${SSL_PATH}${SERVER}/client-cert.pem" \
                        --ssl-key="${SSL_PATH}${SERVER}/client-key.pem" \
                        --default-auth=mysql_native_password \
                        -Bs -e "SHOW DATABASES")
        fi
        #printf "DB_LIST: $DB_LIST"

        # change directory to backup folder first
        #cd "${BACKUPS_PATH}/"

        # change directory to bucket
        #cd "${BACKUPS_PATH}"
        cd "${TMP_PATH}"

        # If instance's folder does not exists, create it.
        if [ ! -d "${SERVER}" ]; then
                mkdir $SERVER
        fi

        # change directory to server
        cd $SERVER


        for DB in $DB_LIST;
        do
                if [ "$DB" != "information_schema" ] && [ "$DB" != "performance_schema" ] && [ "$DB"  != "sys"  ] && [ "$DB" != "mysql" ]; then
                        #printf "DB: $DB"
                        # Generate dump
                        printf "Dumping DB $DB\n"
                        if [ "$SSL" != "y" ]; then
                                #mysqldump --set-gtid-purged=OFF --triggers --events --routines -u$DB_USR -p$DB_PWD \
                                #       -h$DB_HOST $DB | gzip > "${CUR_DATE}_${DB}.sql.gz"
                                mysqldump --defaults-extra-file=/etc/mysql/mysqldump.cnf --set-gtid-purged=OFF  \
                                        --single-transaction --lock-tables=false --quick  \
                                        --triggers --events --routines -h$DB_HOST $DB \
                                                        | gzip > "${CUR_DATE}_${DB}.sql.gz"
                        else
                                if [ "$DB" == "db_hr_osticket_us" ] || [ "$DB" == "db_hr_osticket_ph" ] \
                                        || [ "$DB" == "db_osticket_workday_global" ] || [ "$SERVER" == "isdba-cloudsql-us-we1-a-08" ]; then

                                        if [ "$DAY" == "6" ] && [ "$DB" == "db_hr_osticket_ph" ]; then
                                                mysqldump --defaults-extra-file=/etc/mysql/mysqldump.cnf --set-gtid-purged=OFF \
                                                        --ssl-ca="${SSL_PATH}${SERVER}/server-ca.pem" \
                                                        --ssl-cert="${SSL_PATH}${SERVER}/client-cert.pem" \
                                                        --ssl-key="${SSL_PATH}${SERVER}/client-key.pem" \
                                                        --single-transaction --max_allowed_packet=2147483648 --hex-blob --net_buffer_length=4096 \
                                                        --triggers --events --lock-tables=false --routines --quick -h$DB_HOST $DB \
                                                        | gzip > "${CUR_DATE}_${DB}.sql.gz"
                                        else
                                                if [ "$DB" == "db_hr_osticket_ph" ]; then
                                                        mysqldump --defaults-extra-file=/etc/mysql/mysqldump.cnf --set-gtid-purged=OFF \
                                                                --ssl-ca="${SSL_PATH}${SERVER}/server-ca.pem" \
                                                                --ssl-cert="${SSL_PATH}${SERVER}/client-cert.pem" \
                                                                --ssl-key="${SSL_PATH}${SERVER}/client-key.pem" \
                                                                --single-transaction --max_allowed_packet=2147483648 --hex-blob --net_buffer_length=4096 \
                                                                --ignore-table=$DB.hr_file_chunk --lock-tables=false   \
                                                                --triggers --events --routines --quick -h$DB_HOST $DB  \
                                                                | gzip > "${CUR_DATE}_${DB}.sql.gz"
                                                else
                                                        mysqldump --defaults-extra-file=/etc/mysql/mysqldump.cnf --set-gtid-purged=OFF \
                                                                --ssl-ca="${SSL_PATH}${SERVER}/server-ca.pem" \
                                                                --ssl-cert="${SSL_PATH}${SERVER}/client-cert.pem" \
                                                                --ssl-key="${SSL_PATH}${SERVER}/client-key.pem" \
                                                                --single-transaction --max_allowed_packet=2147483648 --hex-blob --net_buffer_length=4096 \
                                                                --lock-tables=false --quick  \
                                                                --triggers --events --routines -h$DB_HOST $DB \
                                                                | gzip > "${CUR_DATE}_${DB}.sql.gz"
                                                fi
                                        fi
                                else
                                        mysqldump --defaults-extra-file=/etc/mysql/mysqldump.cnf --set-gtid-purged=OFF \
                                                --ssl-ca="${SSL_PATH}${SERVER}/server-ca.pem" \
                                                --ssl-cert="${SSL_PATH}${SERVER}/client-cert.pem" \
                                                --ssl-key="${SSL_PATH}${SERVER}/client-key.pem" \
                                                --single-transaction --max_allowed_packet=2147483648 --lock-tables=false --net_buffer_length=4096 \
                                                --triggers --events --routines --quick  -h$DB_HOST $DB \
                                                        | gzip > "${CUR_DATE}_${DB}.sql.gz"
                                fi
                        fi
                fi
        done
        gsutil -m -o GSUtil:parallel_composite_upload_threshold=150MB mv *.gz gs://${BUCKET}/Backups/Current/${SERVER}/
done

printf "============================================================================================\n\n"

# Go back to home and then unmount the bucket
cd ~

#fi
#fusermount -u $BUCKET_PATH

exit
