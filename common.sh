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

APP_SETUP(){
    id roboshop &>>$LOG_FILE
    if [ $? -ne  0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
        VALIDATE $? "Creating roboshop system user"
    else
        echo -e "System user roboshop is already created ... $Y SKIPPING $N"
    fi

    mkdir -p /app 
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $app_name"

    rm -rf /app/*
    cd /app 
    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "unzipping $app_name"
}

NODEJS_SETUP(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling default nodejs"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs:20"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs:20"

    npm install &>>$LOG_FILE
    VALIDATE $? "Installing Dependencies"
}

MAVEN_SETUP(){
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "Installing Maven and Java"

    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Packaging the shipping application"

    mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
    VALIDATE $? "Moving and renaming Jar file"
}

PYTHON_SETUP(){
    dnf install python3 gcc python3-devel -y &>>$LOG_FILE
    VALIDATE $? "Installing python3 packages"

    pip3 install -r requirements.txt &>>$LOG_FILE
    VALIDATE $? "Installing dependencies"

}

SYSTEMD_SETUP(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Copying $app_name service"

    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $app_name &>>$LOG_FILE
    systemctl start $app_name
    VALIDATE $? "Starting $app_name"
}

# checks whether it is root user or not
CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
        exit 1
    else
        echo "You are running with the root access" | tee -a $LOG_FILE
    fi
}

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

# prints the script execution time
PRINT_TIME(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))

    echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

}
