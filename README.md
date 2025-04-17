# Local Root CA & SSL Certificate Generator

# **Table of Contents**

1. [**Introduction**](#introduction)
2. [**Prerequisites**](#prerequisites)
3. [**Features**](#features)
4. [**Script Workflow**](#script-workflow)
5. [**Usage**](#usage)
   1. [Steps to Run the Script](#steps-to-run-the-script)
6. [**Example Output**](#example-output)
7. [**Log Directory**](#log-directory)
   1. [Log Example](#log-example)
8. [**How to Add and Trust the Root CA and SSL Certificates**](#how-to-add-and-trust-the-root-ca-and-ssl-certificates)
   1. [Windows](#windows)
   2. [Red Hat-based Systems (RHEL, CentOS, Fedora)](#red-hat-based-systems-rhel-centos-fedora)
   3. [Debian-based Systems (Ubuntu, Debian)](#debian-based-systems-ubuntu-debian)
9. [**Notes**](#notes)
10. [**License**](#license)

# Introduction
This script automates the process of creating a local Root Certificate Authority (CA) and generating SSL certificates for your domains. It supports both wildcard certificates and non-wildcard certificates. The script generates log files of all actions performed, which are saved in a `logs` directory.

## Prerequisites

- **`openssl`**: The script uses `openssl` to generate keys, certificates, and certificate signing requests (CSRs).
  - Install `openssl` by running:
    - On **Ubuntu/Debian**:
      ```bash
      sudo apt-get install openssl
      ```
    - On **Red Hat/CentOS/Fedora**:
      ```bash
      sudo yum install openssl
      ```
    - On **Windows**, you can download and install OpenSSL from [here](https://slproweb.com/products/Win32OpenSSL.html).

- **Bash Shell**: The script is written in Bash. Ensure you have a shell environment that supports Bash scripting.
  - On **Windows**, you can use **Git Bash** or **Windows Subsystem for Linux (WSL)**.

- **Sufficient permissions**: The script requires sufficient privileges to create directories and write files in the current working directory.

## Features

- **Root CA Creation**: 
  - Option to create a new Root CA or reuse an existing one.
  - Root CA certificates and keys are saved in the `Root_CA` directory.
  
- **SSL Certificate Generation**:
  - Generate SSL certificates for domains with the option to include wildcard certificates (`*.example.com`).
  - Generate certificate signing requests (CSRs) and private keys.
  - Automatically signs the certificate with the Root CA.
  
- **Logging**: 
  - Every action performed by the script is logged in the `logs` directory.
  - Logs include detailed timestamps for each action.
  
- **Validation**: 
  - The script checks if required fields are entered and prompts for input if any field is left blank.

## Script Workflow

1. **Root CA**:
   - The script checks if a Root CA already exists in the `Root_CA` directory.
   - If a Root CA exists, it prompts for the passphrase to access the Root CA key.
   - If no Root CA exists, it prompts for details (such as name, validity, and organization details) and creates a new Root CA.
   
2. **SSL Certificate Generation**:
   - The script prompts for domain-specific information, including the option to include a wildcard SAN (`*.domain.com`).
   - It creates a private key, CSR (Certificate Signing Request), and signs the certificate using the Root CA.
   - It saves the generated SSL certificate and private key in a folder named after the domain.

3. **Logs**:
   - The script logs all actions in a log file named based on the current date and time. These logs are saved in the `logs` directory.

## Usage

### Steps to Run the Script:

1. **Download or Copy the Script**:
   - Save the script to a file, for example `generate_certificates.sh`.

2. **Make the Script Executable**:
   - Run the following command to make the script executable:
     ```bash
     chmod +x generate_certificates.sh
     ```

3. **Run the Script**:
   - Execute the script by running:
     ```bash
     ./generate_certificates.sh
     ```

4. **Follow the Prompts**:
   - The script will prompt you for necessary information to create the Root CA and generate SSL certificates.

5. **View the Logs**:
   - The logs will be stored in the `logs` directory under the same directory where the script is located. The log filenames are timestamped and include details about each certificate generation.

## Example Output:

```
[+] Generating private key...
[+] Generating CSR...
[+] Signing certificate...
Certificate generated in example.com/
  - Key:        example.com/example.com_key.pem
  - Cert:       example.com/example.com_cert.pem
  - Full chain: example.com/example.com.chain.pem
```

## Log Directory

All logs will be stored in the `logs` directory. Each log file is named with the current date and time in the format:

```
logs/2025-04-17_12-30-45.log
```

### Log Example:

```
2025-04-17 12:30:45 - === Local Root CA & SSL Cert Generator Started ===
2025-04-17 12:30:47 - --- Creating New Root CA ---
...
```

## How to Add and Trust the Root CA and SSL Certificates

### **Windows**:

1. **Install the Root CA Certificate**:
   - Open the **Microsoft Management Console (MMC)** by pressing `Win + R`, typing `mmc`, and hitting **Enter**.
   - Go to **File > Add/Remove Snap-in...**
   - Add **Certificates** and choose **Computer account**.
   - In the **Certificates (Local Computer)** window, right-click **Trusted Root Certification Authorities** > **All Tasks** > **Import**.
   - Browse to the location of your `Root_CA/<your_root_ca_name>_cert.pem` file and import it.
   - Click **Next** and finish the import process.

2. **Trust the SSL Certificate**:
   - For each domain SSL certificate, you can either import the certificate manually into **Trusted Root Certification Authorities** or configure your web browser (Chrome, Firefox, etc.) to trust it.

### **Red Hat-based Systems (RHEL, CentOS, Fedora)**:

1. **Install the Root CA Certificate**:
   - Copy the `Root_CA/<your_root_ca_name>_cert.pem` file to the system:
     ```bash
     sudo cp Root_CA/<your_root_ca_name>_cert.pem /etc/pki/ca-trust/source/anchors/
     ```
   - Update the CA certificates store:
     ```bash
     sudo update-ca-trust extract
     ```

2. **Trust the SSL Certificate**:
   - For each domain SSL certificate, ensure the certificate chain is complete (`domain_cert.pem`, `intermediate_cert.pem`, and `root_cert.pem`).
   - Copy the SSL certificate into `/etc/pki/tls/certs/`:
     ```bash
     sudo cp /path/to/domain_cert.pem /etc/pki/tls/certs/
     ```
   - Update the CA certificates store:
     ```bash
     sudo update-ca-trust
     ```

### **Debian-based Systems (Ubuntu, Debian)**:

1. **Install the Root CA Certificate**:
   - Copy the `Root_CA/<your_root_ca_name>_cert.pem` file to the system:
     ```bash
     sudo cp Root_CA/<your_root_ca_name>_cert.pem /usr/local/share/ca-certificates/
     ```
   - Update the CA certificates store:
     ```bash
     sudo update-ca-certificates
     ```

2. **Trust the SSL Certificate**:
   - For each domain SSL certificate, ensure the certificate chain is complete (`domain_cert.pem`, `intermediate_cert.pem`, and `root_cert.pem`).
   - Copy the SSL certificate into `/usr/local/share/ca-certificates/` and update:
     ```bash
     sudo cp /path/to/domain_cert.pem /usr/local/share/ca-certificates/
     sudo update-ca-certificates
     ```

## Notes

- The script assumes that you have `openssl` installed on your system.
- The directory structure is as follows:
  - `Root_CA/` - Contains the Root CA certificates and keys.
  - `logs/` - Contains log files of the script execution.
  
## License

This script is licensed under the GNU General Public License v3.0 (GPL-3.0).

You can freely use, modify, and distribute this script under the terms of the GPL-3.0 license. You must ensure that any distributed version of this script (or any modified version) is also licensed under GPL-3.0, and the full text of the license is included with the distribution.
