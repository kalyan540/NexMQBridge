FROM debian:bookworm-slim

# Install Mosquitto with WebSockets support
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        gettext-base && \
    # Download Mosquitto directly from the official releases
    wget https://mosquitto.org/files/source/mosquitto-2.0.18.tar.gz -O /tmp/mosquitto.tar.gz && \
    tar xzf /tmp/mosquitto.tar.gz -C /tmp && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        libc-ares-dev \
        libssl-dev \
        libwebsockets-dev \
        libcjson-dev \
        uuid-dev && \
    cd /tmp/mosquitto-2.0.18 && \
    make -j$(nproc) && \
    make install && \
    # Cleanup
    apt-get remove -y build-essential cmake && \
    apt-get autoremove -y && \
    rm -rf /tmp/mosquitto* /var/lib/apt/lists/* && \
    mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log

# Copy JWT plugin (ensure it's compiled for ARM64)
COPY plugin/libmosquitto_jwt_auth.so /usr/lib/libmosquitto_jwt_auth.so

# Copy config, certs, and startup script
COPY mosquitto/mosquitto.conf /mosquitto/config/mosquitto.conf
COPY certs /mosquitto/certs
COPY start.sh /start.sh

# Make startup script executable
RUN chmod +x /start.sh

# Run Mosquitto with startup script
CMD ["/start.sh"]