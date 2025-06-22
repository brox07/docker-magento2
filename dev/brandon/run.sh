#!/bin/bash

# A more advanced helper script for common Magento and Docker tasks.

# --- Style Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[0;33m'

# --- Configuration ---
MAGENTO_USER="www-data"

# --- Helper Functions ---

## --- MODIFIED --- ##
# Runs Magento commands as the correct web server user to prevent permissions errors.
m() {
    echo -e "${C_BLUE}Running as user '${MAGENTO_USER}': bin/magento $@${C_RESET}"
    docker-compose exec --user "${MAGENTO_USER}" php bin/magento "$@"
}

## --- MODIFIED --- ##
# Fixes file permissions from within the PHP container. No sudo needed on the host.
fix_permissions() {
    echo -e "\n${C_YELLOW}Fixing filesystem ownerships and permissions inside the container...${C_RESET}"
    # This command now includes making bin/magento executable
    docker-compose exec php bash -c "chown -R www-data:www-data app/etc var generated pub/static pub/media && find . -type d -exec chmod 775 {} \; && find . -type f -exec chmod 664 {} \; && chmod +x bin/magento"
    echo -e "${C_GREEN}Permissions fixed!${C_RESET}"
}

# --- Main Script Logic ---

## --- NEW --- ##
# If arguments are passed directly to the script, run them as a custom command and exit.
if [ "$#" -gt 0 ]; then
    m "$@"
    exit 0
fi

# If no arguments are provided, show the interactive menu.
echo -e "${C_GREEN}=====================================${C_RESET}"
echo -e "${C_GREEN}  Brandon's Magento Dev Helper       ${C_RESET}"
echo -e "${C_GREEN}=====================================${C_RESET}"
echo "1. Run a custom 'bin/magento' command"
echo "2. Flush Magento Cache"
echo "3. Run Setup Upgrade"
echo "4. Run DI Compile"
echo "5. Fix File Permissions"
echo "6. Get a shell as '${MAGENTO_USER}'"
echo "7. Get a shell as 'root'"
echo "8. Restart Docker Environment (down and up)"
echo "9. Exit"
echo -e "-------------------------------------"
read -p "Please select an option [1-9]: " choice

case $choice in
    1)
        echo -e "${C_YELLOW}-------------------------------------${C_RESET}"
        read -p "Enter the 'bin/magento' command to run: " -a magento_args_array
        if [[ ${#magento_args_array[@]} -gt 0 ]]; then
            m "${magento_args_array[@]}"
        else
            echo -e "${C_RED}No command entered. Aborting.${C_RESET}"
        fi
        ;;
    2)
        m "cache:flush"
        ;;
    3)
        m "setup:upgrade"
        ;;
    4)
        m "setup:di:compile"
        ;;
    5)
        fix_permissions
        ;;
    6)
        echo -e "${C_BLUE}Opening a shell as '${MAGENTO_USER}'... Type 'exit' to leave.${C_RESET}"
        docker-compose exec --user "${MAGENTO_USER}" php bash
        ;;
    7)
        echo -e "${C_BLUE}Opening a shell as 'root'... Type 'exit' to leave.${C_RESET}"
        docker-compose exec php bash
        ;;
    8)
        echo -e "${C_YELLOW}-------------------------------------${C_RESET}"
        echo -e "${C_BLUE}Bringing Docker environment down...${C_RESET}"
        docker-compose down
        echo -e "\n${C_BLUE}Bringing Docker environment up...${C_RESET}"
        docker-compose up -d
        echo -e "\n${C_GREEN}Environment restarted!${C_RESET}"
        ;;
    9)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo -e "${C_RED}Invalid option. Please run the script again.${C_RESET}"
        exit 1
        ;;
esac
