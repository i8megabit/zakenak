FROM alpine:3.18

# Install required packages
RUN apk add --no-cache curl jq bash netcat-openbsd

# Set working directory
WORKDIR /app

# Copy scripts
COPY scripts/ /app/

# Make scripts executable
RUN chmod +x /app/*.sh

# Create directories
RUN mkdir -p /app/resume /app/config

# Set environment variables
ENV HH_API_TOKEN=""
ENV HH_RESUME_ID=""
ENV WEB_PORT="8080"
ENV SCHEDULE="0 12 * * *"

# Expose web port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/bin/bash", "-c"]

# Set default command
CMD ["./web-server.sh & while true; do echo 'Waiting for scheduled execution...'; sleep 3600; done"]