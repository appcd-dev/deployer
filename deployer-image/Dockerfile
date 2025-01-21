# Use an official Terraform base image
FROM hashicorp/terraform:1.5.3

# Install necessary dependencies
RUN apk add --no-cache bash

# Set a working directory inside the container
WORKDIR /app

# Copy Terraform configurations into the container
COPY terraform/ /app/terraform

# Copy the deploy.sh script into the container
COPY scripts/deploy.sh /bin/deploy.sh
RUN chmod +x /bin/deploy.sh

# Create the /data directory and copy schema.yaml
RUN mkdir -p /data
COPY marketplace/schema.yaml /data/schema.yaml

# Set the deploy.sh script as the entrypoint
ENTRYPOINT ["/bin/deploy.sh"]
