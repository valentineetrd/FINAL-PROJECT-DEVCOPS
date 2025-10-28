#!/bin/bash

# ============================================
#  LOCAL DOCKER DEPLOYMENT SCRIPT (LIVE MODE)
#  For testing website changes instantly
#  Author: Akinfe Ayomide
# ============================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
CONTAINER_NAME="local-site"
HOST_PORT=8002
CONTAINER_PORT=80

# ============================================
#  STEP 1: Check for Docker
# ============================================
if ! command -v docker &> /dev/null; then
  echo -e "${RED}❌ Docker is not installed or not in PATH.${NC}"
  exit 1
fi

# ============================================
#  STEP 2: Check and free port if needed
# ============================================
PORT_PIDS=$(sudo lsof -iTCP:${HOST_PORT} -sTCP:LISTEN -t 2>/dev/null)
if [ ! -z "$PORT_PIDS" ]; then
  echo -e "${YELLOW}⚠ Port ${HOST_PORT} is currently in use. Freeing it...${NC}"
  CONTAINER_ID=$(docker ps --filter "publish=${HOST_PORT}" --format "{{.ID}}")
  if [ ! -z "$CONTAINER_ID" ]; then
    docker rm -f "${CONTAINER_ID}" >/dev/null 2>&1
    echo -e "${GREEN}✔ Container using port ${HOST_PORT} removed.${NC}"
  else
    sudo kill -9 ${PORT_PIDS}
    echo -e "${GREEN}✔ Process using port ${HOST_PORT} terminated.${NC}"
  fi
else
  echo -e "${GREEN}✅ Port ${HOST_PORT} is free.${NC}"
fi

# ============================================
#  STEP 3: Remove old container (if exists)
# ============================================
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo -e "${YELLOW}🧹 Removing old container '${CONTAINER_NAME}'...${NC}"
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1
  echo -e "${GREEN}✔ Old container removed.${NC}"
fi

# ============================================
#  STEP 4: Run container with live mount
# ============================================
echo -e "${CYAN}🚀 Starting local development container '${CONTAINER_NAME}'...${NC}"

if docker run -d \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  -v "$(pwd)":/usr/share/nginx/html \
  --name "${CONTAINER_NAME}" \
  nginx:alpine; then

  echo -e "${GREEN}✅ Website running locally with live updates!${NC}"
  echo -e "${CYAN}🌐 Visit: http://localhost:${HOST_PORT}${NC}"
  echo -e "${YELLOW}✏ Any file changes in $(pwd) will reflect instantly in your browser.${NC}"
else
  echo -e "${RED}❌ Failed to start container.${NC}"
  exit 1
fi

# ============================================
#  STEP 5: Optional cleanup of unused images
# ============================================
echo -e "${YELLOW}🧽 Cleaning up unused Docker images...${NC}"
docker image prune -f >/dev/null 2>&1 && echo -e "${GREEN}✔ Cleanup done.${NC}"

echo -e "${GREEN}🎉 All done! Your site is live on localhost:${HOST_PORT}.${NC}"
