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

# Function to show a spinner animation
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    # Move cursor to position
    tput civis  # Hide cursor
    echo -n "  "
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r  [%c] Scanning... " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\r  [✓] Scan complete!     \n"
    tput cnorm  # Show cursor
}

# Function to count directories at first level (for progress estimation)
count_dirs() {
    local dir="$1"
    if [[ "$dir" == "/" ]]; then
        echo "$(ls -la / | grep -c "^d")"
    else
        echo "$(ls -la "$dir" | grep -c "^d")"
    fi
}

# Create temporary files
TEMP_FILE=$(mktemp)
PROGRESS_FILE=$(mktemp)

# Run du command with improved parameters for macOS
echo -e "Scanning disk space in ${BOLD}$SCAN_DIR${RESET}..."
echo -e "(Depth: $DEPTH, showing top $TOP_ENTRIES entries)"

# Count approximately how many directories we'll process
TOTAL_DIRS=$(count_dirs "$SCAN_DIR")
echo -e "Analyzing approximately $TOTAL_DIRS top-level directories...\n"

# Start the du command in background
if [ "$SCAN_DIR" = "/" ]; then
    # For root scanning, we want to ensure we get the real disk usage
    sudo du -h -d "$DEPTH" "$SCAN_DIR" 2>/dev/null | grep -v "^0" | sort -hr > "$TEMP_FILE" &
else
    # For specific directory scanning
    du -h -d "$DEPTH" "$SCAN_DIR" 2>/dev/null | grep -v "^0" | sort -hr > "$TEMP_FILE" &
fi

DU_PID=$!

# Show spinner while du is running
show_spinner $DU_PID

# Small delay to ensure file is written
sleep 0.5

# Get the first line to determine total size
TOTAL_LINE=$(head -n 1 "$TEMP_FILE")
TOTAL_SIZE=$(echo "$TOTAL_LINE" | awk '{print $1}')

# Function to convert human-readable size to bytes
to_bytes() {
    local size="$1"
    local number=$(echo "$size" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed 's/[0-9.]//g')
    
    case "$unit" in
        K|k) echo "scale=0; $number * 1024" | bc ;;
        M|m) echo "scale=0; $number * 1024 * 1024" | bc ;;
        G|g) echo "scale=0; $number * 1024 * 1024 * 1024" | bc ;;
        T|t) echo "scale=0; $number * 1024 * 1024 * 1024 * 1024" | bc ;;
        *) echo "$number" ;;
    esac
}

# Function to calculate percentage
calculate_percentage() {
    local size="$1"
    local total="$2"
    local size_bytes=$(to_bytes "$size")
    local total_bytes=$(to_bytes "$total")
    
    if [ -n "$size_bytes" ] && [ -n "$total_bytes" ] && [ "$total_bytes" -ne 0 ]; then
        echo "scale=1; $size_bytes * 100 / $total_bytes" | bc 2>/dev/null
    else
        echo "N/A"
    fi
}

# Function to print horizontal line
print_line() {
    printf "+%$((12+2))s+%$((50+2))s+%$((15+2))s+\n" | tr ' ' '-'
}

# Print table header
print_line
printf "| %-12s | %-50s | %-15s |\n" "Size" "Directory" "% of Total"
print_line

# Process and display results
cat "$TEMP_FILE" | head -n "$TOP_ENTRIES" | while read -r size dir; do
    # Calculate percentage
    percent=$(calculate_percentage "$size" "$TOTAL_SIZE")
    if [ "$percent" != "N/A" ]; then
        percent="${percent}%"
    fi
    
    # Truncate directory path if too long
    if [[ ${#dir} -gt 50 ]]; then
        dir="...${dir: -47}"
    fi
    
    # Print table row
    printf "| %-12s | %-50s | %14s |\n" "$size" "$dir" "$percent"
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