#!/bin/bash

source ./common.sh
app_name=catalogue

CHECK_ROOT

APP_SETUP

NODEJS_SETUP

SYSTEMD_SETUP

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying MongoDB Repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

# if the status is less than 1 means data is not loaded and we need to load the data and more than 1 means data is already loaded into the mongodb
STATUS=$(mongosh --host mongodb.daws84s.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.daws84s.online </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi

PRINT_TIME