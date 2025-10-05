#!/bin/bash

# Script to generate device certificates for MQTT clients
# Usage: ./generate-device-cert.sh <device_name> [hostname]
# Example: ./generate-device-cert.sh device01 mqtt.example.com

set -e

# Check if device name is provided
if [ $# -eq 0 ]; then
    echo "Error: Device name is required"
    echo "Usage: $0 <device_name> [hostname]"
    echo "Example: $0 device01 mqtt.example.com"
    exit 1
fi

# Default values
DEVICE_NAME="$1"
HOSTNAME="${2:-localhost}"
CERT_DIR="./certs"
DEVICE_CERT_DIR="$CERT_DIR/devices"

# Certificate settings
COUNTRY="IN"
STATE="Gujarat"
CITY="Vadodara"
ORGANIZATION="Prahari Technologies"
ORG_UNIT="Prahari Technologies"
DEVICE_COMMON_NAME="$DEVICE_NAME"

# Certificate validity (in days)
DEVICE_VALIDITY=365 # 1 year

# Key size
KEY_SIZE=2048

echo "=== MQTT Device Certificate Generation ==="
echo "Device Name: $DEVICE_NAME"
echo "Hostname: $HOSTNAME"
echo "Certificate Directory: $CERT_DIR"
echo "Device Certificate Directory: $DEVICE_CERT_DIR"
echo "============================================"

# Check if CA certificates exist
if [ ! -f "$CERT_DIR/ca.crt" ] || [ ! -f "$CERT_DIR/ca.key" ]; then
    echo "Error: CA certificates not found!"
    echo "Please run './generate-ca-server-certs.sh' first to create CA certificates."
    exit 1
fi

# Create device certificate directory if it doesn't exist
mkdir -p "$DEVICE_CERT_DIR"

# Check if device certificate already exists
if [ -f "$DEVICE_CERT_DIR/$DEVICE_NAME.crt" ]; then
    echo "Warning: Device certificate for '$DEVICE_NAME' already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

cd "$CERT_DIR"

echo "Step 1: Generating device private key..."
openssl genrsa -out "devices/$DEVICE_NAME.key" $KEY_SIZE

echo "Step 2: Generating device certificate signing request..."
openssl req -new -key "devices/$DEVICE_NAME.key" -out "devices/$DEVICE_NAME.csr" -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$DEVICE_COMMON_NAME"

echo "Step 3: Creating device certificate extensions file..."
cat > "devices/$DEVICE_NAME.extensions.conf" << EOF
[v3_req]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DEVICE_NAME
DNS.2 = $DEVICE_NAME.local
EOF

echo "Step 4: Signing device certificate with CA..."
openssl x509 -req -in "devices/$DEVICE_NAME.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "devices/$DEVICE_NAME.crt" -days $DEVICE_VALIDITY -extensions v3_req -extfile "devices/$DEVICE_NAME.extensions.conf"

echo "Step 5: Creating device certificate bundle..."
cat "devices/$DEVICE_NAME.crt" ca.crt > "devices/$DEVICE_NAME.bundle.crt"

echo "Step 6: Setting appropriate permissions..."
chmod 600 "devices/$DEVICE_NAME.key"
chmod 644 "devices/$DEVICE_NAME.crt"
chmod 644 "devices/$DEVICE_NAME.bundle.crt"

echo "Step 7: Cleaning up temporary files..."
rm -f "devices/$DEVICE_NAME.csr" "devices/$DEVICE_NAME.extensions.conf"

echo ""
echo "=== Device Certificate Generation Complete ==="
echo "Files generated for device '$DEVICE_NAME':"
echo "  - Device Certificate: $(pwd)/devices/$DEVICE_NAME.crt"
echo "  - Device Private Key: $(pwd)/devices/$DEVICE_NAME.key"
echo "  - Device Certificate Bundle: $(pwd)/devices/$DEVICE_NAME.bundle.crt"
echo ""
echo "=== Certificate Information ==="
openssl x509 -in "devices/$DEVICE_NAME.crt" -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:)"
echo ""
echo "=== Usage Instructions ==="
echo "For MQTT client configuration:"
echo "  - CA Certificate: $(pwd)/ca.crt"
echo "  - Client Certificate: $(pwd)/devices/$DEVICE_NAME.crt"
echo "  - Client Private Key: $(pwd)/devices/$DEVICE_NAME.key"
echo ""
echo "Example mosquitto_pub command:"
echo "mosquitto_pub -h $HOSTNAME -p 8883 --cafile $(pwd)/ca.crt --cert $(pwd)/devices/$DEVICE_NAME.crt --key $(pwd)/devices/$DEVICE_NAME.key -t test/topic -m 'Hello from $DEVICE_NAME'"
echo ""
echo "Example mosquitto_sub command:"
echo "mosquitto_sub -h $HOSTNAME -p 8883 --cafile $(pwd)/ca.crt --cert $(pwd)/devices/$DEVICE_NAME.crt --key $(pwd)/devices/$DEVICE_NAME.key -t test/topic"
echo "============================================" 