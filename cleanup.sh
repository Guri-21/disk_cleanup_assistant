#!/bin/bash

# === Disk Cleanup Assistant ===

# Check if dialog is installed
if ! command -v dialog &> /dev/null
then
    echo "Dialog is not installed. Please run: brew install dialog"
    exit 1
fi

# Temporary file for dialog inputs
tempfile=$(mktemp)

# Welcome message
dialog --title "Disk Cleanup Assistant" --msgbox "Welcome to Disk Cleanup Assistant!\n\nThis tool helps you clean up old or large files on your system. Press OK to begin." 10 50

# Disk usage summary
clear
echo "================================="
echo "     Disk Cleanup Assistant"
echo "================================="
echo ""
echo "Disk Usage Summary:"
df -h /
echo ""
echo "Directory Usage Overview:"
du -h --max-depth=1 "$HOME" 2>/dev/null | sort -hr | head -n 10

# Ask user how they want to select directory
dialog --title "Directory Selection" \
--menu "Choose how you want to select the directory to scan:" 15 60 2 \
1 "Enter directory manually" \
2 "Browse using file selector" 2> "$tempfile"

menu_choice=$(<"$tempfile")

case $menu_choice in
  1)
    dialog --inputbox "Enter the full directory path to scan (e.g., /Users/yourname/Downloads):" 10 60 2> "$tempfile"
    dir_to_scan=$(<"$tempfile")
    ;;
  2)
    dialog --title "Browse for Directory" --fselect "$HOME/" 15 60 2> "$tempfile"
    dir_to_scan=$(<"$tempfile")
    ;;
  *)
    dialog --msgbox "Invalid option or cancelled. Exiting." 8 40
    clear
    rm -f "$tempfile"
    exit 1
    ;;
esac

rm -f "$tempfile"

# Validate input
if [ ! -d "$dir_to_scan" ]; then
    dialog --title "Error" --msgbox "The selected path is not a valid directory. Exiting." 8 40
    clear
    exit 1
fi

# Clear screen and show scanning message
clear
echo "================================="
echo "Scanning directory: $dir_to_scan"
echo "================================="

# Scan and store matching files in temp
scan_results=$(mktemp)
find "$dir_to_scan" -type f -size +100M -o -type f -mtime +30 2>/dev/null > "$scan_results"

# Read files into array (compatible with macOS)
files_to_manage=()
while IFS= read -r line; do
    files_to_manage+=("$line")
done < "$scan_results"
rm -f "$scan_results"

# If no files found
if [ ${#files_to_manage[@]} -eq 0 ]; then
    dialog --title "No Files Found" --msgbox "No large or old files were found in the selected directory." 8 50
    clear
    exit 0
fi

# Interactive cleanup options
for file in "${files_to_manage[@]}"; do
    [[ -z "$file" ]] && continue  # skip empty lines

    dialog --title "File Action" \
    --menu "What would you like to do with:\n$file" 15 60 4 \
    1 "Delete" \
    2 "Move to another folder" \
    3 "Skip" \
    4 "Cancel and Exit Cleanup" 2> "$tempfile"

    choice=$(<"$tempfile")

    case $choice in
        1)
            dialog --yesno "Are you sure you want to delete:\n$file" 10 50
            if [ $? -eq 0 ]; then
                rm -f "$file" && echo "$(date): Deleted $file" >> deleted_files.log
                dialog --msgbox "File deleted." 6 40
            fi
            ;;
        2)
            dialog --fselect "$HOME/" 15 60 2> "$tempfile"
            target_dir=$(<"$tempfile")
            if [ -d "$target_dir" ]; then
                mv "$file" "$target_dir" && dialog --msgbox "File moved to $target_dir." 6 50
            else
                dialog --msgbox "Invalid target directory. Skipping." 6 40
            fi
            ;;
        3)
            # Skip
            ;;
        4)
            dialog --msgbox "Cleanup canceled by user." 6 40
            break
            ;;
        *)
            dialog --msgbox "No valid option selected. Skipping." 6 40
            ;;
    esac
done

rm -f "$tempfile"

dialog --title "Cleanup Complete" --msgbox "Disk cleanup complete!\n\nDeleted files logged in deleted_files.log." 10 50
clear
