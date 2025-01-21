# Use an official Terraform base image
FROM hashicorp/terraform:1.5.3
RUN apk add --no-cache bash

# Set a working directory inside the container
WORKDIR /app

# Copy your entire terraform folder into the container
COPY terraform/ /app/terraform

# Copy any extra scripts (e.g., deploy.sh) if you want to use them
COPY scripts/deploy.sh /app/scripts/deploy.sh
RUN chmod +x /app/scripts/deploy.sh

# Option 1: Directly run deploy.sh as entrypoint
ENTRYPOINT ["/app/scripts/deploy.sh"]
