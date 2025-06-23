#!/bin/bash

show_menu() {
    file=$1

    dialog --clear --title "Disk Cleanup Assistant" \
    --menu "What do you want to do with this file?\n$file" 15 60 3 \
    1 "Delete" \
    2 "Move" \
    3 "Skip" 2>temp_choice.txt

    choice=$(<temp_choice.txt)
    rm -f temp_choice.txt

    case $choice in
        1)
            rm "$file"
            log_action "Deleted" "$file"
            ;;
        2)
            dialog --inputbox "Enter target directory:" 10 60 2>temp_target.txt
            target_dir=$(<temp_target.txt)
            rm -f temp_target.txt

            mkdir -p "$target_dir"
            mv "$file" "$target_dir"
            log_action "Moved" "$file" "to $target_dir"
            ;;
        3)
            echo "Skipped $file"
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}
