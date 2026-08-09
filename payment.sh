#!/bin/bash

source ./common.sh
app_name=payment

CHECK_ROOT

PYTHON_SETUP

APP_SETUP

SYSTEMD_SETUP

PRINT_TIME