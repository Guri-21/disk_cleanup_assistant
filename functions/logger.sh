#!/bin/bash

log_action() {
    action=$1
    file=$2
    extra_info=$3
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $action: $file $extra_info" >> deleted_files.log
}
