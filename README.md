# Mac Disk Space Analyzer

This is a bash script to analyze disk space usage on macOS, helping you identify large directories for cleanup.

## Features

* Scans a specified directory (defaults to root).
* Shows the top N directories consuming the most space.
* Displays the size in a human-readable format.
* Calculates the percentage of total scanned space.
* Provides common cleanup targets and usage examples.

## Installation

1.  Clone this repository:
    ```bash
    git clone [https://github.com/Ringish/mac-disk-space-analyzer.git](https://github.com/Ringish/mac-disk-space-analyzer.git)
    cd mac-disk-space-analyzer
    ```

2.  Run the installation script:
    ```bash
    sudo ./install.sh
    ```
    You will be prompted for your password as the script installs to `/usr/local/bin`.

3.  Ensure `/usr/local/bin` is in your system's PATH. The installer attempts to guide you, but you might need to manually add it to your `~/.bashrc` or `~/.zshrc` file if it's not already there:
    ```bash
    export PATH="/usr/local/bin:$PATH"
    ```
    Then, source your shell configuration file or open a new terminal.

## Usage

Once installed, you can run the script from anywhere using the command:

```bash
disk_space_analyzer [directory] [-d depth] [-t top]
```
* `[directory]` (optional): The starting directory for the scan. Defaults to the root directory (`/`) if not specified.
* `-d depth` (optional): An integer specifying how many levels of subdirectories to descend during the scan. Defaults to `3`.
* `-t top` (optional): An integer specifying the number of largest directories to display in the output. Defaults to `20`.

**Examples:**

* Scan your home directory:
    ```bash
    disk_space_analyzer ~
    ```

* Scan the `/Applications` directory, looking two levels deep and showing the top 10 largest directories:
    ```bash
    disk_space_analyzer /Applications -d 2 -t 10
    ```

* Scan the current directory:
    ```bash
    disk_space_analyzer .
    ```

* Scan the `/Library/Caches` directory with the default depth and top count:
    ```bash
    disk_space_analyzer /Library/Caches
    ```

## Common Cleanup Targets on macOS

Here are some common directories on macOS that often contain large files and can be targets for cleanup:

* `~/Library/Caches/` - Application cache files (often safe to delete).
* `~/Library/Application Support/` - Application-specific data, sometimes includes large caches.
* `~/Downloads/` - Downloaded files that may no longer be needed.
* `~/Library/Developer/Xcode/iOS DeviceSupport/` - Support files for older iOS simulator versions (if you use Xcode).
* `~/Library/Developer/Xcode/DerivedData/` - Xcode build products and caches (can often be cleaned).
* `~/Library/Containers/` - Data for sandboxed applications, can sometimes grow large.
* `~/Library/Application Support/MobileSync/Backup/` - Backups of your iOS devices (can be large; manage with Finder or iTunes/Finder).
* `~/Library/Mail/` - Local storage of email messages and attachments.
* `~/Library/Messages/` - Local storage of iMessage attachments.
* `~/Library/Application Support/Google/Chrome/` - Google Chrome browser data, including cache.
* `/Library/Caches/` - System-level cache files (generally do not delete without understanding the implications).
* `/private/var/log/` - System log files (can sometimes be large, but be cautious when deleting).
* `/Users/Shared/` - Files shared between users on the system.

**Note:** Be careful when deleting files and directories, especially those outside your home directory. Deleting important system files can lead to instability.

## Note on Disk Usage Values

macOS might report disk usage differently in Finder compared to this script. This script uses the `du` command, which typically measures the actual disk space occupied by files and directories, including overhead. Finder might sometimes display logical file sizes or aggregate sizes in a slightly different way. Therefore, the values reported by this script are generally a more accurate representation of the physical disk space being used. Additionally, this script follows through mounted volumes to provide a comprehensive assessment.