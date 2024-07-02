# stage 1: builder stage
FROM hashicorp/terraform:1.9 AS builder

# Update package lists and install necessary build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

#cloud specific  cli installation
# Install AWS CLI
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Stage 2: Runtime stage
FROM ubuntu:22.04

# Copy necessary binaries from the builder stage
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform

COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

WORKDIR /app

# Copy the rest of your application
COPY . .

# Define the entry point
CMD ["/bin/bash", "-c", "chmod +x $SCRIPT && exec $SCRIPT"]
