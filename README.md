# **Custom Magento 2 Docker Environment**

This project provides a complete, containerized local development environment for Magento 2 using Docker and Docker Compose. It is designed to be simple, robust, and easy to set up from a clean slate.  
The environment consists of the following services:

* **Nginx:** Web server for handling HTTP/HTTPS requests.  
* **PHP-FPM:** A custom-built PHP 8.2 image with all necessary extensions for Magento.  
* **MariaDB:** Database server, using a Magento-compatible version (10.6).  
* **OpenSearch:** The required search engine, configured for single-node development.  
* **Redis:** For high-performance caching and session storage.

## **Prerequisites**

Before you begin, ensure you have the following installed and configured on your machine.

1. **Git:** For cloning the repository and version control.  
2. **Docker & Docker Compose:** Docker Desktop is the recommended tool for Windows and macOS.  
3. **WSL 2 (Windows Users):** If you are on Windows, ensure Docker Desktop is configured to use the WSL 2 backend for optimal performance.  
4. **Adobe Commerce Marketplace Account:** You need an account to get authentication keys for downloading the Magento source code.  
5. **GitHub Account & SSH Key:** To push and pull this repository, your local machine needs an SSH key that has been added to your GitHub account.

## **Setup Instructions**

Follow these steps to build and launch a fresh Magento 2 instance.

### **1\. Clone the Repository**

Clone this repository to your local machine and navigate into the project directory.  
```bash
git clone git@github.com:brox07/docker-magento2.git  
cd docker-magento2
```

### **2\. Configure Composer Authentication**

To download the Magento source code, Composer needs your authentication keys from the Adobe Commerce Marketplace.

1. **Get Your Keys:**  
   * Log in to the [Adobe Commerce Marketplace](https://marketplace.magento.com/).  
   * Navigate to **My Profile \> Access Keys**.  
   * Copy your **Public Key** (this is your "username") and **Private Key** (the "password").  
2. **Create auth.json:**  
   * In the root of the project, create a new file named auth.json.  
   * Paste the following content into it, replacing the placeholders with your actual keys:  
   ```json
     {  
         "http-basic": {  
             "repo.magento.com": {  
                 "username": "YOUR_PUBLIC_KEY_HERE",  
                 "password": "YOUR_PRIVATE_KEY_HERE"  
             }  
         }  
     }
   ```

**Note:** This file is listed in .gitignore and will not be committed to the repository for security. It must be created manually on each new machine.

### **3\. Generate Local SSL Certificate**

This environment is configured to run on HTTPS. You need to generate a self-signed certificate for local development.

1. **Create SSL Directory:**  
   ```bash
   mkdir -p docker/nginx/ssl
   ```

2. **Generate Certificate:** Run this command from the project root.  
   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout docker/nginx/ssl/magento.test.key \
     -out docker/nginx/ssl/magento.test.crt \
     -subj "/C=US/ST=State/L=City/O=Development/CN=magento.test"
     ```

### **4\. Build and Start the Environment**

This command will build your custom PHP image and start all the services defined in docker-compose.yaml.  
```bash
docker-compose up -d --build
```

### **5\. Install Magento**

These commands execute inside the PHP container to download, set permissions for, and install the Magento application.

1. **Download Magento:**  
   ```bash
   docker-compose exec php composer create-project --repository-url=https://repo.magento.com magento/project-community-edition .
   ```

2. **Set Initial File Permissions:**  
   ```bash
   docker-compose exec php chown -R www-data:www-data .
   ```

3. **Run the Magento Installer:**  
   ```bash
   docker-compose exec php bin/magento setup:install \\  
      \--base-url=\[https://magento.test/\](https://magento.test/) \\  
      \--db-host=db \\  
      \--db-name=magento \\  
      \--db-user=magento \\  
      \--db-password=magento \\  
      \--admin-firstname=Admin \\  
      \--admin-lastname=User \\  
      \--admin-email=admin@example.com \\  
      \--admin-user=admin \\  
      \--admin-password=Password123 \\  
      \--language=en\_US \\  
      \--currency=USD \\  
      \--timezone=America/Chicago \\  
      \--use-rewrites=1 \\  
      \--search-engine=opensearch \\  
      \--opensearch-host=opensearch \\  
      \--opensearch-port=9200
   ```

### **6\. Post-Installation Configuration**

After the installation is complete, a few final commands are needed to configure the store correctly for a local development environment.

1. **Set Correct Base URLs:**  
   ```bash
   ./dev/brandon/run.sh
   # Then select option 1
   ```
   ```bash
   config:set web/unsecure/base_url https://magento.test
   ./dev/brandon/run.sh
   # Then select option 1
   ```
   ```
   config:set web/secure/base_url https://magento.test
   ```

2. **Deploy Static Content:**  
   ```
   ./dev/brandon/run.sh setup:static-content:deploy \-f
   ```

3. **Fix File Permissions:** This is crucial after generating static files. Use option 4 in the helper script.  
   ```bash
   ./dev/brandon/run.sh
   # Then select option 4
   ```

4. **Flush Cache:**  
   ```bash
   ./dev/brandon/run.sh
   # Then select option 1
   ```
   ```
   cache:flush
   ```

## **Accessing Your Store**

* **Storefront:** [https://magento.test/](https://magento.test/)  
* **Admin Panel:** The URL is randomized during installation. Check the output of the `setup:install` command for a line like `[SUCCESS]: Magento Admin URI: /admin\_XXXXX.`
* **Admin Credentials:** admin / Password123

**Important:** The site uses a self-signed SSL certificate. Your browser will show a security warning on the first visit. You must click **"Advanced"** and **"Accept the Risk and Continue"** to proceed.

## **Daily Workflow & Useful Commands**

A collection of convenient wrapper scripts are available in the bin directory to simplify common operations.

| Command | Description |
| :---- | :---- |
| `./bin/start` | Starts the Docker environment in the background (equivalent to `docker-compose up -d`). |
| `./bin/stop` | Stops the Docker environment (equivalent to `docker-compose down`). |
| `./bin/magento <command>` | A wrapper to run `bin/magento` commands inside the PHP container. All arguments are forwarded. Example: `./bin/magento cache:flush` |
| `./bin/bash` | Opens an interactive bash shell inside the PHP container as the `www-data` user to prevent file permissions issues. |

**Advanced Helper Script**
For more complex, multi-step tasks, a custom helper script is included at ./dev/brandon/run.sh

**Usage:** `./dev/brandon/run.sh`

| Option | Description |
| :---- | :---- |
| **1** | Run a custom `bin/magento` command (e.g., `indexer:reindex`). |
| **2** | "The Works": Cleans generated files and runs a full recompile. |
| **3** | Restarts the entire Docker environment (down and up \-d). |
| **4** | Fixes all file permissions in the src directory. |
| **5** | Exits the script. |

## **Troubleshooting**

* **Permission Denied / Not Writable:** This is the most common issue. It usually means file permissions are incorrect after a command was run.  
  * **Solution:** Use the helper script\! Run `./dev/brandon/run.sh` and choose option **4**.  
* **PR\_END\_OF\_FILE\_ERROR (SSL Error in Browser):** Your Nginx container is not configured for SSL or cannot find the certificates.  
  * **Solution:** Ensure you have generated the self-signed certificate and that the volume mount for it (`- ./docker/nginx/ssl:/etc/nginx/ssl:ro`) exists in the nginx service in your `docker-compose.yaml`.  
* **Unstyled Pages (404s on CSS/JS files):** The static content has not been deployed or Nginx can't read it.  
  * **Solution:** Run `./dev/brandon/run.sh`. Select option 1. Run `setup:static-content:deploy \-f`, then run `./dev/brandon/run.sh` again, select option **4** in the helper script to fix permissions.
