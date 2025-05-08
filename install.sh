#!/bin/bash

SCRIPT_NAME="disk_space_analyzer"
SCRIPT_PATH="./${SCRIPT_NAME}.sh" # Path to the script within the repo
INSTALL_DIR="/usr/local/bin"

echo "Installing ${SCRIPT_NAME} to ${INSTALL_DIR}..."

# Check for sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script requires sudo privileges to install to ${INSTALL_DIR}."
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Make the script executable
echo "Making ${SCRIPT_PATH} executable..."
if chmod +x "${SCRIPT_PATH}"; then
    echo "${SCRIPT_PATH} is now executable."
else
    echo "Error making ${SCRIPT_PATH} executable."
    exit 1
fi

# Move the script to the installation directory
echo "Moving ${SCRIPT_PATH} to ${INSTALL_DIR}/${SCRIPT_NAME}..."
if cp "${SCRIPT_PATH}" "${INSTALL_DIR}/${SCRIPT_NAME}"; then
    echo "${SCRIPT_NAME} successfully installed to ${INSTALL_DIR}."
else
    echo "Error moving ${SCRIPT_PATH} to ${INSTALL_DIR}/${SCRIPT_NAME}."
    exit 1
fi

# Check if INSTALL_DIR is in PATH and provide instructions if not
if ! grep -q "${INSTALL_DIR}" <<< "$PATH"; then
    echo -e "\n${YELLOW}Warning:${RESET} The directory '${INSTALL_DIR}' is not in your PATH."
    echo -e "To use '${SCRIPT_NAME}' as a command, add the following line to your shell configuration file (~/.bashrc or ~/.zshrc):"
    echo -e "${BOLD}export PATH=\"${INSTALL_DIR}:\${PATH}\"${RESET}"
    echo -e "Then, source the file or open a new terminal."
fi

echo -e "\n${GREEN}Installation complete!${RESET} You can now run the script using the command: ${BOLD}${SCRIPT_NAME}${RESET}"

exit 0