#!/bin/bash

# A more advanced helper script for common Magento and Docker tasks.

# --- Style Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[0;33m'

# --- Helper Functions ---

# Function to run Magento commands
m() {
    echo -e "${C_BLUE}Running: docker-compose exec php bin/magento $@${C_RESET}"
    docker-compose exec php bin/magento "$@"
}

# Function to fix file permissions on the src/ directory
fix_permissions() {
    echo -e "\n${C_YELLOW}Fixing filesystem ownerships and permissions...${C_RESET}"
    sudo chown -R www-data:www-data src/
    sudo find src/ -type d -exec chmod 775 {} \;
    sudo find src/ -type f -exec chmod 664 {} \;
    sudo chmod +x src/bin/magento
    echo -e "${C_GREEN}Permissions fixed!${C_RESET}"
}

# --- Main Script Logic ---
echo -e "${C_GREEN}=====================================${C_RESET}"
echo -e "${C_GREEN}  Brandon's Magento Dev Helper       ${C_RESET}"
echo -e "${C_GREEN}=====================================${C_RESET}"
echo "1. Run a custom 'bin/magento' command"
echo "2. Full Clean & Recompile (the works!)"
echo "3. Restart Docker Environment (down and up)"
echo "4. Fix File Permissions"
echo "5. Exit"
echo -e "-------------------------------------"
read -p "Please select an option [1-5]: " choice

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
        echo -e "${C_YELLOW}-------------------------------------${C_RESET}"
        echo -e "${C_BLUE}Starting full clean and recompile process...${C_RESET}"
        
        echo -e "\n${C_YELLOW}Step 1: Removing generated files...${C_RESET}"
        sudo rm -rf src/generated/* src/var/view_preprocessed/* src/pub/static/frontend/* src/pub/static/adminhtml/*
        echo -e "${C_GREEN}Generated files cleared.${C_RESET}"

        echo -e "\n${C_YELLOW}Step 2: Running setup:upgrade...${C_RESET}"
        m setup:upgrade

        echo -e "\n${C_YELLOW}Step 3: Running setup:di:compile...${C_RESET}"
        m setup:di:compile
        
        # Automatically fix permissions after generating code
        fix_permissions

        echo -e "\n${C_YELLOW}Step 4: Cleaning cache...${C_RESET}"
        m cache:clean
        
        echo -e "\n${C_GREEN}Process complete!${C_RESET}"
        ;;
    3)
        echo -e "${C_YELLOW}-------------------------------------${C_RESET}"
        echo -e "${C_BLUE}Bringing Docker environment down...${C_RESET}"
        docker-compose down
        echo -e "\n${C_BLUE}Bringing Docker environment up...${C_RESET}"
        docker-compose up -d
        echo -e "\n${C_GREEN}Environment restarted!${C_RESET}"
        ;;
    4)
        # New option to just fix permissions
        fix_permissions
        ;;
    5)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo -e "${C_RED}Invalid option. Please run the script again.${C_RESET}"
        exit 1
        ;;
esac