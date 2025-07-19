FROM debian:bookworm-slim

# Install dependencies and Mosquitto (from Debian repo)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mosquitto \
        mosquitto-clients \
        libwebsockets-dev \
        ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create Mosquitto data directories
RUN mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log /mosquitto/certs

# Copy JWT plugin (make sure libmosquitto_jwt_auth.so is in build context)
COPY libmosquitto_jwt_auth.so /usr/lib/libmosquitto_jwt_auth.so

# Copy Mosquitto configuration
COPY mosquitto/mosquitto.conf /mosquitto/config/mosquitto.conf

# Copy certs (ensure 'certs' folder in build context)
COPY certs /mosquitto/certs

# Set entrypoint
CMD ["mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
