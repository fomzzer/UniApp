#!/bin/bash

echo "Fetching latest changes from GitHub..."
git pull

echo "Building new Docker image..."
sudo docker build -t uniapp-backend .

echo "Stopping existing container..."
sudo docker stop uniapp-server

echo "Removing existing container..."
sudo docker rm uniapp-server

echo "Starting new container instance..."
sudo docker run -d -p 8000:8000 --name uniapp-server --restart unless-stopped uniapp-backend

echo "Update completed successfully."