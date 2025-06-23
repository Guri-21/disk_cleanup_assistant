#!/bin/bash

disk_summary() {
    echo "Disk Usage Summary:"
    df -h /
    echo
    echo "Directory Usage:"
    du -sh * 2>/dev/null
    echo
}
