#!/bin/bash

# Fix Docker DNS configuration on DGX Spark
echo "Creating Docker daemon.json with DNS configuration..."

# Create daemon.json
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"],
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimesArgs": []
    }
  }
}
EOF

echo "Restarting Docker daemon..."
sudo systemctl restart docker

echo "Waiting for Docker to start..."
sleep 5

echo "Testing DNS resolution in container..."
sudo docker run --rm ubuntu:24.04 bash -c "apt-get update && echo 'DNS working!'"

echo "Docker DNS configuration complete!"