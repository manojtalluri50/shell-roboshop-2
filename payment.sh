#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with the root access" | tee -a $LOG_FILE
fi

# validate function takes inputs exit status as $1 and which command they try to install as $2
VALIDATE(){
        if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python3 packages"

id roboshop &>>$LOG_FILE
if [ $? -ne  0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop is already created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment"

rm -rf /app/* &>>$LOG_FILE
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

