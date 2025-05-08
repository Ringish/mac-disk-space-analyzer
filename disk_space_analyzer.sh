#!/bin/bash

# disk_space_analyzer.sh - Mac directory space usage analyzer
# Shows directories taking up significant space to help with cleanup

# Default settings
SCAN_DIR="${1:-/}"        # First argument: directory to scan, default is /
DEPTH="${2:-3}"           # Second argument: scan depth, default is 3
TOP_ENTRIES="${3:-20}"    # Third argument: number of entries to show, default is 20

# Check if terminal supports colors
if [ -t 1 ]; then
    # Text formatting
    BOLD="\033[1m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    RED="\033[31m"
    RESET="\033[0m"
else
    # No color if not in terminal
    BOLD=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RED=""
    RESET=""
fi

# Check if running as root if scanning from root directory
if [[ "$SCAN_DIR" == "/" && $(id -u) -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Not running as root. Some system directories may be inaccessible.${RESET}"
    echo -e "For complete results, consider running with sudo: ${BOLD}sudo $0${RESET}\n"
fi

# Print header
echo -e "${BOLD}${GREEN}===== Mac Disk Space Analyzer =====${RESET}"
echo -e "Scanning disk space in ${BOLD}$SCAN_DIR${RESET} (Depth: $DEPTH, Top: $TOP_ENTRIES entries)"

# Spinner and progress tracker
show_progress() {
    local total=$1
    local progress_file=$2
    local delay=0.1
    local spinstr='|/-\'
    local count=0
    tput civis
    while true; do
        local done=$(wc -l < "$progress_file")
        local temp=${spinstr#?}
        printf "\r  [%c] Scanning directory %d of %d..." "$spinstr" "$done" "$total"
        local spinstr=$temp${spinstr%"$temp"}
        if [ "$done" -ge "$total" ]; then
            break
        fi
        sleep $delay
    done
    printf "\r  [✓] Scanning complete!                            \n"
    tput cnorm
}

TEMP_FILE=$(mktemp)
PROGRESS_FILE=$(mktemp)

# Get list of first-level directories (ignore hidden)
if [ "$SCAN_DIR" == "/" ]; then
    DIRS=(/*)
else
    DIRS=("$SCAN_DIR"/*)
fi

TOTAL_DIRS=${#DIRS[@]}

# Start progress spinner
show_progress "$TOTAL_DIRS" "$PROGRESS_FILE" &

# Start scanning in background
for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        {
            if [[ "$SCAN_DIR" == "/" ]]; then
                sudo du -h -d "$DEPTH" "$dir" 2>/dev/null
            else
                du -h -d "$DEPTH" "$dir" 2>/dev/null
            fi
        } | grep -v "^0" >> "$TEMP_FILE"
        echo "$dir" >> "$PROGRESS_FILE"
    else
        echo "$dir" >> "$PROGRESS_FILE"  # Still count it
    fi
done

# Wait for all background jobs to finish
wait

# Sort and take top entries
sort -hr "$TEMP_FILE" > "${TEMP_FILE}_sorted"

# Extract total size from first line
TOTAL_LINE=$(head -n 1 "${TEMP_FILE}_sorted")
TOTAL_SIZE=$(echo "$TOTAL_LINE" | awk '{print $1}')

to_bytes() {
    local size="$1"
    local num=$(echo "$size" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed 's/[0-9.]//g')
    case "$unit" in
        K|k) echo "scale=0; $num * 1024" | bc ;;
        M|m) echo "scale=0; $num * 1024 * 1024" | bc ;;
        G|g) echo "scale=0; $num * 1024 * 1024 * 1024" | bc ;;
        T|t) echo "scale=0; $num * 1024 * 1024 * 1024 * 1024" | bc ;;
        *) echo "$num" ;;
    esac
}

calculate_percentage() {
    local size="$1"
    local total="$2"
    local size_bytes=$(to_bytes "$size")
    local total_bytes=$(to_bytes "$total")

    local total_int=${total_bytes%%.*}

    if [ "$total_int" -ne 0 ]; then
        echo "scale=1; $size_bytes * 100 / $total_bytes" | bc
    else
        echo "N/A"
    fi
}

print_line() {
    printf "+%14s+%52s+%17s+\n" | tr ' ' '-'
}

print_line
printf "| %-12s | %-50s | %-15s |\n" "Size" "Directory" "% of Total"
print_line

head -n "$TOP_ENTRIES" "${TEMP_FILE}_sorted" | while read -r size dir; do
    percent=$(calculate_percentage "$size" "$TOTAL_SIZE")
    # Truncate directory path if too long
    [[ ${#dir} -gt 50 ]] && dir="...${dir: -47}"
    # Print table row
    printf "| %-12s | %-50s | %14s |\n" "$size" "$dir" "${percent}%"
done

print_line

# Show summary
echo -e "\n${BOLD}Summary:${RESET}"
echo -e "Total scanned size: ${BOLD}${BLUE}$TOTAL_SIZE${RESET}"
echo -e "Scan depth: $DEPTH directories deep"
echo -e "Showing top $TOP_ENTRIES largest directories\n"

# Cleanup
rm "$TEMP_FILE"
rm "$PROGRESS_FILE"

# Tips section
echo -e "${BOLD}${GREEN}Common cleanup targets:${RESET}"
echo -e "• ${BOLD}~/Library/Caches/${RESET} - Application caches"
echo -e "• ${BOLD}~/Library/Application Support/${RESET} - App data, often includes caches"
echo -e "• ${BOLD}~/Downloads/${RESET} - Downloaded files often forgotten"
echo -e "• ${BOLD}~/Library/Developer/Xcode/iOS DeviceSupport/${RESET} - Old iOS simulator files"
echo -e "• ${BOLD}~/Library/Developer/Xcode/DerivedData/${RESET} - Xcode build files"
echo -e "• ${BOLD}~/Library/Containers/${RESET} - App container data, can be large"
echo -e "• ${BOLD}~/Library/Application Support/MobileSync/Backup/${RESET} - iPhone backups"
echo -e "• ${BOLD}~/Library/Mail/${RESET} - Mail attachments and data"
echo -e "• ${BOLD}~/Library/Messages/${RESET} - Messages attachments"
echo -e "• ${BOLD}~/Library/Application Support/Google/Chrome/${RESET} - Chrome browser data"
echo -e "• ${BOLD}/Library/Caches/${RESET} - System-wide caches"
echo -e "• ${BOLD}/private/var/log/${RESET} - System logs (be careful!)"
echo -e "• ${BOLD}/Users/Shared/${RESET} - Shared user files\n"

echo -e "${BOLD}Usage:${RESET}"
echo -e "• Basic usage: ${BOLD}$0 [directory] [depth] [entries]${RESET}"
echo -e "• Examples:"
echo -e "  - Default (root, depth 3, top 20): ${BOLD}sudo $0${RESET}"
echo -e "  - Scan home with depth 2, show top 10: ${BOLD}$0 ~/ 2 10${RESET}"
echo -e "  - Scan Library with depth 4, show top 30: ${BOLD}$0 ~/Library 4 30${RESET}"
echo -e "  - For system directories, use sudo: ${BOLD}sudo $0 / 3 20${RESET}\n"

echo -e "${BOLD}${YELLOW}Note:${RESET} MacOS may show different values than Finder because this script"
echo -e "measures actual disk usage rather than logical file sizes. This script"
echo -e "follows through mounted volumes to give you the most accurate assessment."

exit 0