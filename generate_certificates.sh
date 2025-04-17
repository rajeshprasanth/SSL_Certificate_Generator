#!/bin/bash

# ============================================================
# Local Root CA & SSL Certificate Generator
# Created by Rajesh Prashanth Anandavadivel <rajeshprasanth@rediffmail.com>
# Date: Thu Apr 17 02:59:34 PM IST 2025
#
# This script automates the creation of a Local Root Certificate
# Authority (CA) and SSL certificate generation for domains.
# It supports wildcard and non-wildcard SSL certificates, and
# logs all actions in the 'logs' directory.
#
# License: GPL-3.0 License
# You may copy, modify, and distribute this script under the terms
# of the GNU General Public License, version 3.
# 
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script. If not, see <https://www.gnu.org/licenses/>.
# ============================================================

set -e

# Log directory
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Log file based on current date and time
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d_%H-%M-%S').log"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "=== Local Root CA & SSL Cert Generator Started ==="

# --- Reuse or Create Root CA ---
if [[ -d "Root_CA" ]] && ls Root_CA/*_key.pem &>/dev/null && ls Root_CA/*_cert.pem &>/dev/null; then
    log_message "Existing Root CA found."
    CA_KEY=$(ls Root_CA/*_key.pem)
    CA_CERT=$(ls Root_CA/*_cert.pem)
    read -s -rp "Enter passphrase for existing Root CA key: " CA_PWD
    echo
else
    log_message "--- Creating New Root CA ---"
    read -rp "Enter name for Root CA (e.g. MyRootCA): " CA_NAME
    read -rp "Enter number of days the Root CA certificate should be valid (e.g. 3650): " CA_DAYS

    read -rp "Country [C]: " CA_C
    read -rp "State [ST]: " CA_ST
    read -rp "City [L]: " CA_L
    read -rp "Organization [O]: " CA_O
    read -rp "Org Unit [OU]: " CA_OU
    read -rp "Common Name [CN]: " CA_CN

    while true; do
        read -s -rp "Set passphrase for Root CA key: " CA_PWD
        echo
        read -s -rp "Confirm passphrase: " CA_PWD2
        echo
        [[ "$CA_PWD" == "$CA_PWD2" ]] && break || echo "Passphrases don't match. Try again."
    done

    mkdir -p Root_CA || { log_message "Failed to create Root_CA directory."; exit 1; }

    log_message "[+] Generating Root CA key..."
    CA_KEY="Root_CA/${CA_NAME}_key.pem"
    openssl genrsa -aes256 -passout pass:"$CA_PWD" -out "$CA_KEY" 4096 || { log_message "Error generating Root CA key."; exit 1; }

    log_message "[+] Generating Root CA cert..."
    CA_CERT="Root_CA/${CA_NAME}_cert.pem"
    openssl req -x509 -new -key "$CA_KEY" -passin pass:"$CA_PWD" \
        -sha256 -days "$CA_DAYS" -out "$CA_CERT" \
        -subj "/C=$CA_C/ST=$CA_ST/L=$CA_L/O=$CA_O/OU=$CA_OU/CN=$CA_CN" || { log_message "Error generating Root CA certificate."; exit 1; }

    # Output DN summary for Root CA
    log_message "=== Root CA DN Summary ==="
    log_message "Country: $CA_C"
    log_message "State: $CA_ST"
    log_message "City: $CA_L"
    log_message "Organization: $CA_O"
    log_message "Org Unit: $CA_OU"
    log_message "Common Name: $CA_CN"

    log_message "New Root CA saved in Root_CA/"
fi

# --- SSL Certificate Loop ---
while true; do
    log_message "--- SSL Certificate Creation ---"
    read -rp "Domain name (e.g. example.local): " DOMAIN_NAME
    read -rp "Include wildcard SAN (*.${DOMAIN_NAME})? [y/N]: " WILDCARD
    read -rp "Number of days certificate should be valid: " CERT_DAYS

    read -rp "Country [C]: " CERT_C
    read -rp "State [ST]: " CERT_ST
    read -rp "City [L]: " CERT_L
    read -rp "Organization [O]: " CERT_O
    read -rp "Org Unit [OU]: " CERT_OU
    read -rp "Common Name [CN]: " CERT_CN

    if [[ -z "$DOMAIN_NAME" || -z "$CERT_C" || -z "$CERT_ST" || -z "$CERT_L" || -z "$CERT_O" || -z "$CERT_OU" || -z "$CERT_CN" ]]; then
        log_message "All fields must be filled out. Please try again."
        continue
    fi

    mkdir -p "$DOMAIN_NAME" || { log_message "Failed to create directory for domain: $DOMAIN_NAME"; exit 1; }

    log_message "[+] Generating private key..."
    openssl genrsa -out "$DOMAIN_NAME/${DOMAIN_NAME}_key.pem" 2048 || { log_message "Error generating private key for $DOMAIN_NAME"; exit 1; }

    log_message "[+] Generating CSR..."
    openssl req -new -key "$DOMAIN_NAME/${DOMAIN_NAME}_key.pem" \
        -out "$DOMAIN_NAME/${DOMAIN_NAME}.csr" \
        -subj "/C=$CERT_C/ST=$CERT_ST/L=$CERT_L/O=$CERT_O/OU=$CERT_OU/CN=$CERT_CN" || { log_message "Error generating CSR for $DOMAIN_NAME"; exit 1; }

    EXTFILE="$DOMAIN_NAME/${DOMAIN_NAME}_ext.cnf"
    cat > "$EXTFILE" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN_NAME}
EOF

    if [[ "$WILDCARD" =~ ^[Yy]$ ]]; then
        echo "DNS.2 = *.${DOMAIN_NAME}" >> "$EXTFILE"
    fi

    log_message "[+] Signing certificate..."
    CERT_FILE="$DOMAIN_NAME/${DOMAIN_NAME}_cert.pem"
    openssl x509 -req -in "$DOMAIN_NAME/${DOMAIN_NAME}.csr" \
        -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
        -out "$CERT_FILE" -days "$CERT_DAYS" -sha256 \
        -extfile "$EXTFILE" -passin pass:"$CA_PWD" || { log_message "Error signing certificate for $DOMAIN_NAME"; exit 1; }

    CHAIN_FILE="${DOMAIN_NAME}/${DOMAIN_NAME}.chain.pem"
    cat "$CERT_FILE" "$CA_CERT" > "$CHAIN_FILE" || { log_message "Error generating certificate chain."; exit 1; }

    rm -f "$DOMAIN_NAME/${DOMAIN_NAME}.csr" "$EXTFILE" Root_CA/*.srl

    # Output DN summary for SSL cert
    log_message "=== SSL Cert DN Summary ==="
    log_message "Country: $CERT_C"
    log_message "State: $CERT_ST"
    log_message "City: $CERT_L"
    log_message "Organization: $CERT_O"
    log_message "Org Unit: $CERT_OU"
    log_message "Common Name: $CERT_CN"

    log_message "Certificate generated in $DOMAIN_NAME/"
    log_message "  - Key:        ${DOMAIN_NAME}/${DOMAIN_NAME}_key.pem"
    log_message "  - Cert:       ${DOMAIN_NAME}/${DOMAIN_NAME}_cert.pem"
    log_message "  - Full chain: ${CHAIN_FILE}"

    read -rp "Generate another certificate? [y/N]: " REPEAT
    [[ "$REPEAT" =~ ^[Yy]$ ]] || break
done

log_message "=== Script Finished ==="
