#!/usr/bin/env bash

LOG_FILE="${1:-log.log}"

tail -n 50 -f "$LOG_FILE"