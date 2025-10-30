
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD workflow (GitHub Actions)
├── assets/                      # Website assets (images, css, webfont ,js.)
├── vendor/                      # Third-party libraries
│   ├── bootstrap/               # Bootstrap CSS/JS files
│   └── jquery/                  # jQuery library files
├── index.html                   # Homepage
├── contact.html                 # Contact page
├── properties.html              # Properties listing page
├── property-details.html        # Property details page
├── Dockerfile                   # Docker build configuration
├── run-dev.sh                   # Local testing script (optional)
└── README.md                    # Project documentation


🐳 Dockerfile
# Use official Nginx lightweight image
FROM nginx:alpine

# Remove default Nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy website files into the container
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

✅ Purpose:
✔Uses Nginx to host the static website.

✔Cleans up the default page.

✔Copies your website files.

✔Keeps it running continuously inside the container.




⚙️ GitHub Actions Workflow (CI/CD)
name: CI/CD Pipeline with Email Notification

on:
  push:
    branches: [ project ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: akinfeayomide373/final-devops-project:latest

    - name: Send email notification
      if: success()
      run: |
        curl --request POST \
          --url https://api.sendgrid.com/v3/mail/send \
          --header "Authorization: Bearer ${{ secrets.SENDGRID_API_KEY }}" \
          --header "Content-Type: application/json" \
          --data '{
            "personalizations": [{
              "to": [
                { "email": "akinfeayomide0@gmail.com" },
                { "email": "omolanweshly@gmail.com" },
                { "email": "akinfeayomide6@gmail.com" }
              ],
              "subject": "✅ Deployment Successful: Villa Agency Website"
            }],
            "from": { "email": "'"${{ secrets.EMAIL_FROM }}"'" },
            "content": [{
              "type": "text/plain",
              "value": "Hello Team,\n\nYour static website has been successfully built and deployed via GitHub Actions.\n\nDocker Image: akinfeayomide373/final-devops-project:latest\nBranch: project\nTimestamp: '"$(date)"'\n\nVisit your EC2 instance to verify the deployment.\n\n— DevOps Bot"
            }]
          }'

| Secret Name                                        | Purpose                      |
| -------------------------------------------------- | ---------------------------- |
| `DOCKERHUB_USERNAME`                               | Your Docker Hub username     |
| `DOCKERHUB_TOKEN`                                  | Docker Hub access token      |
| `SENDGRID_API_KEY`                                 | API key for sending emails   |
| `EMAIL_FROM`                                       | Sender email address         |




🖥️ EC2 Deployment Script

#!/bin/bash
# ============================================
#  EC2 DEPLOYMENT SCRIPT 
# ============================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
CONTAINER_NAME="jolly_herschel"
HOST_PORT=8002
IMAGE_NAME="akinfeayomide373/final-devops-project:latest"

# ============================================
#  STEP 1: Pull latest Docker image
# ============================================
echo -e "${CYAN}🔄 Pulling latest image: ${IMAGE_NAME}...${NC}"
if docker pull "${IMAGE_NAME}"; then
  echo -e "${GREEN}✔ Latest image pulled successfully.${NC}"
else
  echo -e "${RED}❌ Failed to pull image. Check Docker Hub or internet connection.${NC}"
  exit 1
fi

# ============================================
#  STEP 2: Check and free up the port if needed
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
#  STEP 3: Remove old container if exists
# ============================================
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo -e "${YELLOW}🧹 Removing old container '${CONTAINER_NAME}'...${NC}"
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1
  echo -e "${GREEN}✔ Old container removed.${NC}"
fi

# ============================================
#  STEP 4: Run new container (production mode)
# ============================================
echo -e "${CYAN}🚀 Deploying new container '${CONTAINER_NAME}' on port ${HOST_PORT}...${NC}"

if docker run -d \
  -p ${HOST_PORT}:80 \
  --name "${CONTAINER_NAME}" \
  "${IMAGE_NAME}"; then

  echo -e "${GREEN}✅ Deployment successful!${NC}"
  echo -e "${CYAN}🌐 Visit your live site at: http://<your-ec2-public-ip>:${HOST_PORT}${NC}"
else
  echo -e "${RED}❌ Failed to start container.${NC}"
  exit 1
fi

# ============================================
#  STEP 5: Optional cleanup
# ============================================
echo -e "${YELLOW}🧽 Cleaning up unused Docker images...${NC}"
docker image prune -f >/dev/null 2>&1 && echo -e "${GREEN}✔ Cleanup done.${NC}"

echo -e "${GREEN}🎉 All done! Your website is now live on EC2.${NC}"


⚡ How to Deploy on EC2
# MAKE SURE YOUR SCRIPT FILE IS INSIDE YOUR EC2 INSTANCE 
# IF NOT COPY THE FILE FRO YOUR LOCAL COMPUTER TO THE EC2 INSTANCE USING:
✔scp -i /path/to/your-key.pem /path/to/local-file ec2-user@<your-ec2-public-ip>:/home/ec2-user/


1) SSH into your EC2 instance

ssh -i your-key.pem ec2-user@<your-ec2-public-ip>


2) Create and save the script

nano ec2-deploy.sh


3) Make it executable

chmod +x ec2-deploy.sh


4) Run deployment

./ec2-deploy.sh

✅ The website will be live at: http://<your-ec2-public-ip>:8002




🧪 Test Locally (Optional)

You can also test locally before pushing:

✔ docker build -t villa-agency:local .
✔ docker run -d -p 8080:80 villa-agency:local




[Pushed Code to Branch 'project']
          │
          ▼
[GitHub Actions Workflow Starts]
          │
          ▼
[Docker Image Built & Pushed to Docker Hub]
          │
          ▼
[EC2 Instance Pulls Latest Image]
          │
          ▼
[Website Updated & Live]
          │
          ▼
[Email Notification Sent]
