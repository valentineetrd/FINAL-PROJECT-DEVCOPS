#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Starting deployment of dev-nginx container...${NC}"

# Stop existing container if running
if docker ps -q --filter "name=dev-nginx" | grep -q .; then
  echo -e "${CYAN}🛑 Stopping existing container...${NC}"
  docker stop dev-nginx && echo -e "${GREEN}✔ Container stopped.${NC}" || echo -e "${RED}✖ Failed to stop container.${NC}"
fi

# Remove existing container if exists
if docker ps -a -q --filter "name=dev-nginx" | grep -q .; then
  echo -e "${CYAN}🧹 Removing old container...${NC}"
  docker rm dev-nginx && echo -e "${GREEN}✔ Container removed.${NC}" || echo -e "${RED}✖ Failed to remove container.${NC}"
fi

# Run new container
echo -e "${CYAN}📦 Launching new dev-nginx container...${NC}"
docker run -d \
  --name dev-nginx \
  -p 80:80 \
  -v /home/ec2-user/your-project-folder:/usr/share/nginx/html \
  nginx:alpine \
  && echo -e "${GREEN}✅ Deployment successful!${NC}" \
  || echo -e "${RED}❌ Deployment failed.${NC}"