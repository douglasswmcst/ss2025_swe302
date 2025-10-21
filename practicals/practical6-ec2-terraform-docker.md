# Practical 6 EC2: Deploying Next.js Application on AWS EC2 using Terraform and Docker with LocalStack

**Learning Outcomes:**
1. Deploy virtual machines (EC2 instances) using Terraform and LocalStack
2. Understand the difference between S3 static hosting and EC2 compute instances
3. Configure and use Docker on remote servers
4. Navigate nested container networking (LocalStack → EC2 → Docker)
5. Troubleshoot port forwarding and network access in containerized environments

**Duration:** 2-3 hours

**Prerequisites:**
- Completed Practical 5 (Docker fundamentals)
- Basic understanding of Linux command line
- Familiarity with Git and GitHub
- Next.js application created (or use the starter from Step 5)

**Note**: This is an alternative approach to Practical 6. While Practical 6 deploys a static Next.js site to S3, this practical deploys a full Next.js application server to EC2. Both are valid deployment strategies with different use cases.

---

### Prerequisites Verification

Before starting, verify all required tools are installed:

```bash
# Check Docker Desktop
docker --version
# Expected: Docker version 20.x or higher

# Check Terraform
terraform --version
# Expected: Terraform v1.x or higher

# Check terraform-local
tflocal --version
# Expected: Should show same version as terraform

# Check LocalStack
localstack --version
# Expected: Version 3.x or higher

# Check AWS Local CLI
awslocal --version
# Expected: aws-cli/2.x or higher

# Check Node.js
node --version
# Expected: v18.x or higher
```

If any command fails, please install the missing tool using the installation steps below.

---

### Required Installation

1. Docker Desktop
2. Terraform Local
3. LocalStack
4. AWS Local CLI

### Step 1: Setting Up Docker Desktop and Terraform

1. Install Docker Desktop from https://docs.docker.com/engine/install/
2. Install Terraform from https://learn.hashicorp.com/tutorials/terraform/install-cli
3. Note: you are to install terraform-local for it to work with localstack. You can install it using pip:
   ```bash
   pip install terraform-local
   ```
   OR
   You can navigate to the following link for more installation details: https://github.com/localstack/terraform-local

**Note for LocalStack**: Docker Desktop must be running before starting LocalStack, as LocalStack itself runs as a Docker container.

### Step 2: Setting Up LocalStack

1. Navigate to localstack website https://app.localstack.cloud/sign-in and create an account
2. Navigate to the localstack documentation https://docs.localstack.cloud/aws/getting-started/installation/ and follow the instructions to install LocalStack on your machine.

**LocalStack Free vs Pro**:
- Free tier: Supports most AWS services including EC2, S3, IAM
- Pro tier: Advanced features, persistence, extended API coverage
- This practical uses only free-tier features

### Step 3: Setting up AWS LOCAL CLI

1. Navigate to https://github.com/localstack/awscli-local and follow the instructions to install AWS LOCAL CLI on your machine.

### Step 4: Understanding the LocalStack + Terraform + EC2 Workflow

Before we start creating infrastructure, it's important to understand how these tools work together:

1. **LocalStack** - Emulates AWS services locally on your machine
2. **Terraform-Local (tflocal)** - Automatically configures Terraform to use LocalStack endpoints
3. **AWS CLI Local (awslocal)** - AWS CLI wrapper configured for LocalStack
4. **EC2 Instances in LocalStack** - Run as Docker containers within the LocalStack container

**Key Concept**: When you create an EC2 instance with LocalStack, it creates a nested Docker container. This means:
- The EC2 instance is a container within the LocalStack container
- IP addresses are internal to LocalStack, not your host machine
- You need port forwarding to access services running on the EC2 instance

We'll address how to access your deployed application in later steps.

#### LocalStack vs Production AWS - Key Differences

| Aspect | LocalStack | Production AWS |
|--------|-----------|----------------|
| **Cost** | Free (for basic features) | Pay per use |
| **AMI IDs** | Special IDs like `ami-000001` | Real AMIs like `ami-0c55b159cbfafe1f0` |
| **Networking** | Containers within containers | Real VMs with public IPs |
| **Access** | Port forwarding required | Direct access via public IP |
| **Default User** | Usually `root` | `ec2-user`, `ubuntu`, etc. |
| **Persistence** | Data lost when stopped | Persistent unless terminated |
| **Speed** | Instant (uses Docker) | 1-2 minutes to launch |

**Important**: This practical uses LocalStack, so we use LocalStack-specific configurations. In production, you would adjust AMI IDs, networking, and access methods.

### Step 5: Creating a Next.js Application with the Starter CLI Command

1. Navigate to the Next.js documentation https://nextjs.org/docs/app/getting-started/installation and follow the instructions to create a Next.js application using the starter CLI command.
2. ```bash
   npx create-next-app@latest my-app --yes
   cd my-app
   npm run dev
   ```

### Step 6: Writing Terraform Configuration Files

We are going to define and provision our virtual infrastructure using Terraform. This approach is called Infrastructure as Code (IaC).

**Why is this important?** Before IaC was introduced, system administrators had to manually configure physical hardware and software. This was time-consuming, error-prone, and difficult to scale. With IaC, we can version control our infrastructure, reproduce it reliably, and automate deployments.

Create a new directory for your Terraform configuration:

```bash
mkdir terraform-ec2
cd terraform-ec2
```

**1. Create `main.tf` - Provider Configuration**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"

  # Skip AWS-specific validations for LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # S3 configuration for LocalStack
  s3_use_path_style = true

  # Configure service endpoints to point to LocalStack
  endpoints {
    ec2    = "http://localhost:4566"
    s3     = "http://localhost:4566"
    iam    = "http://localhost:4566"
    sts    = "http://localhost:4566"
  }
}
```

**2. Create `ec2.tf` - EC2 Instance Configuration**

```hcl
# Upload the public key to AWS
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Launch an EC2 instance
resource "aws_instance" "my_instance" {
  # LocalStack uses special AMI IDs
  # This resolves to ubuntu-noble image in LocalStack
  ami           = "ami-000001"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "My-NextJS-Instance"
    Environment = "development"
  }
}

# Output the instance details
output "instance_id" {
  value = aws_instance.my_instance.id
}

output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}
```

**Note**: The Terraform configuration describes:

A. **Virtual Machine (Server)** - The EC2 instance resource we want to create
B. **Operating System** - Specified via AMI-ID (Amazon Machine Image). LocalStack uses special AMI IDs like `ami-000001` which map to Docker images (e.g., Ubuntu Noble)
C. **Instance Type** - `t3.micro` represents the virtual resources allocated. See: https://aws.amazon.com/ec2/instance-types/
D. **Key Pair** - Used for secure SSH access to the server

### Step 7: Create an SSH Key Pair for the EC2 Instance

SSH keys allow secure authentication to your EC2 instance without passwords.

**Generate an SSH key pair:**

```bash
# Generate SSH key pair (if you don't already have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

This command:
- `-t rsa` - Creates an RSA key
- `-b 4096` - Uses 4096 bits for strong encryption
- `-f ~/.ssh/id_rsa` - Saves the key to the default location
- `-N ""` - No passphrase (empty string)

**Verify your keys were created:**

```bash
ls -la ~/.ssh/id_rsa*
```

You should see:
- `~/.ssh/id_rsa` - Private key (keep this secret!)
- `~/.ssh/id_rsa.pub` - Public key (this will be uploaded to EC2)

**Important**: Never share your private key. Terraform will read your public key (`.pub` file) to upload to AWS.

### Step 8: Run and Initialise your LocalStack Instance

Navigate to the following website for more details: https://docs.localstack.cloud/aws/getting-started/auth-token/

To get your AUTH-TOKEN you are required to create an account on localstack website.
Navigate to the settings page on your localstack account and copy your AUTH-TOKEN from the Auth Token Tab.

```bash
localstack auth set-token <YOUR_AUTH_TOKEN>
localstack start
```

**Optional but Recommended**: While LocalStack can run without an auth token, registering provides:
- Access to LocalStack Web UI for visualizing resources
- Better support and documentation
- Extended service coverage

If you skip this step, LocalStack will still work for this practical.

### Step 9: Deploying the Infrastructure with Terraform-Local

1. Intialise Terraform with tflocal in your project directory
   ```bash
   tflocal init
   ```
2. Validate your terraform configuration files by using Terraform Plan
   ```bash
   tflocal plan
   ```
3. Apply the terraform configuration to deploy the infrastructure with Terraform Apply
   ```bash
   tflocal apply
   ```

You should observe in the terminal that the EC2 instance has been created successfully.

Navigate to your LocalStack dashboard to verify that the EC2 instance is running.

### Step 10: Understanding LocalStack EC2 Networking

**Key Concept**: LocalStack EC2 instances are Docker containers running inside the LocalStack container. This creates a networking challenge.

#### How It Works

```
Your Machine
    │
    └─> LocalStack Container (port 4566)
            │
            └─> EC2 Instance Container
                    │
                    └─> Next.js App (port 3000)
```

#### Finding Your EC2 Instance Port

When LocalStack creates an EC2 instance, it automatically maps the SSH port (22) to a random port on your host machine.

**Option 1: Use Docker Desktop** (Recommended for beginners)
1. Open Docker Desktop
2. Find the container named like `localstack-ec2/ubuntu-noble-ami:ami-000001`
3. Click on the container
4. Look at the "Ports" section
5. Find the mapping: `0.0.0.0:XXXXX->22/tcp`
6. `XXXXX` is your SSH port

**Option 2: Use Docker CLI**
```bash
# List all containers and their port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep localstack-ec2

# Example output:
# localstack-ec2/ubuntu-noble-ami:ami-000001    0.0.0.0:54321->22/tcp
#                                               ^^^^^ This is your SSH port
```

#### Connecting via SSH

Once you have the port number (e.g., 54321), connect using:

```bash
ssh -i ~/.ssh/id_rsa -p 54321 root@127.0.0.1
```

Breakdown:
- `-i ~/.ssh/id_rsa` - Use your private key
- `-p 54321` - Connect to port 54321 (replace with your actual port)
- `root@127.0.0.1` - Connect as root user to localhost

**Note**: LocalStack EC2 instances typically use `root` as the default user, not `ec2-user` as in production AWS.

**First connection**: You may see a message about host authenticity. Type `yes` to continue.

#### Troubleshooting Connection Issues

**Problem**: "Connection refused"
```bash
# Check if LocalStack is running
curl http://localhost:4566/_localstack/health

# Check if EC2 instance is running
awslocal ec2 describe-instances
```

**Problem**: "Permission denied (publickey)"
```bash
# Verify your public key was uploaded
awslocal ec2 describe-key-pairs

# Check your private key permissions (should be 600)
ls -la ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa  # Fix if needed
```

### Step 11: Install Docker & Git on your EC2 Instance

Once connected to your EC2 instance, install the required software:

**Note**: LocalStack EC2 instances typically use Ubuntu, so we'll use `apt` package manager. If you see errors, the instance might use a different OS.

```bash
# Update package lists
sudo apt update

# Install Git
sudo apt install -y git

# Install Docker
sudo apt install -y docker.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (avoid needing sudo for docker commands)
sudo usermod -aG docker $USER

# Verify installations
git --version
docker --version

# If docker requires sudo, either logout/login or use:
newgrp docker
```

**For Amazon Linux instances** (if Ubuntu commands don't work):
```bash
sudo yum update -y
sudo yum install -y git docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

### Step 12: Prepare your Next.js Application for Docker Deployment

**IMPORTANT**: Do these steps in your local machine, in your Next.js application directory.

#### A. Configure Next.js for Standalone Output

Edit `next.config.js` (or create it if it doesn't exist):

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
}

module.exports = nextConfig
```

The `output: 'standalone'` setting tells Next.js to create a self-contained build that includes only necessary files, making it perfect for Docker deployments.

#### B. Create Dockerfile

Create a file named `Dockerfile` in the root of your Next.js application directory:

```dockerfile
# syntax=docker.io/docker/dockerfile:1

FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi


# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN \
  if [ -f yarn.lock ]; then yarn run build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

#### C. Create .dockerignore

Create a `.dockerignore` file to exclude unnecessary files from the Docker build:

```
node_modules
.next
.git
*.md
.env*.local
```

#### D. Push to GitHub

**In your local machine**, push your Next.js application to a Git repository:

```bash
# Initialize git if not already done
git init

# Add files
git add .

# Commit
git commit -m "Add Dockerfile and standalone config"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push
git push -u origin main
```

#### E. Clone on EC2 Instance

**In your EC2 instance** (via SSH), clone your repository:

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

### Step 13: Build and Run your Next.js Application using Docker

1. Navigate to your next.js application directory on your EC2 instance.
2. Build the Docker image for your Next.js application:
   ```bash
   docker build -t my-nextjs-app .
   ```
3. Run the Docker container for your Next.js application:
   ```bash
   docker run -d -p 3000:3000 my-nextjs-app
   ```

You have completed the deployment of your Next.js application on an AWS EC2 instance using Terraform and Docker with LocalStack emulation!

You can access your application by navigating to `http://<EC2_INSTANCE_IP>:3000` in your web browser.

SIKE, it doesn't work like that. Why? Since we are using LocalStack, the EC2 instance is not assigned a public IP address that is accessible over the internet. The port in Next.js application is mapped to PORT 3000 on your EC2 machine.

But the LocalStack container which is hosting the EC2 instance has a PORT forwarding from your localhost/3000 to the EC2 instance.

Therefore, you cannot access the application using the EC2 instance IP address.

Instead, you can access the application by forwarding the port from your localhost to the LocalStack container.

How it looks like:

```Next.js Docker container (localhost:3000)-> EC2 PORT 3000 -> LocalStack Container IP -> LocalStack Container PORT (random port on localhost) -> Local Machine (localhost:random port)```

---

### Challenge Tasks

#### Challenge 1: Access Your Next.js Application from Your Browser

**Problem**: Your Next.js application is running on port 3000 inside the EC2 instance, but you can't access it from your browser at `http://localhost:3000`.

**Why?** Remember the nested container architecture:
```
Browser → ??? → LocalStack Container → EC2 Container → Next.js (port 3000)
```

**Your Task**: Implement a solution to access the Next.js application from your physical host machine's web browser.

### Understanding the Networking Challenge

Before attempting the challenge, let's visualize the problem:

```
┌─────────────────────────────────────────────────────────────┐
│ Your Computer (Host Machine)                                │
│                                                              │
│  Browser wants: http://localhost:3000                       │
│                     ↓                                        │
│                     ✗ (Nothing listening here!)             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ LocalStack Container (localhost:4566)                │  │
│  │                                                       │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ EC2 Container (ami-000001)                     │  │  │
│  │  │                                                │  │  │
│  │  │  SSH: 22 ─────> forwarded to host:54321       │  │  │
│  │  │                                                │  │  │
│  │  │  ┌──────────────────────────────────────────┐ │  │  │
│  │  │  │ Docker Container (my-nextjs-app)         │ │  │  │
│  │  │  │                                          │ │  │  │
│  │  │  │  Next.js Server: http://localhost:3000  │ │  │  │
│  │  │  │                                          │ │  │  │
│  │  │  └──────────────────────────────────────────┘ │  │  │
│  │  │                                                │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**The Challenge**: Create a path from your browser to the Next.js app through all these layers.

**What you know**:
- SSH port 22 on the EC2 container is already forwarded (you used this to connect via SSH)
- Next.js runs on port 3000 inside the Docker container
- Docker container runs inside EC2 container
- EC2 container runs inside LocalStack container

**What you need**: A way to forward port 3000 through all these layers to your browser.

**Hints**:

<details>
<summary>Hint 1: Understanding the Problem</summary>

The Next.js app listens on port 3000 inside the EC2 container. The EC2 container is inside the LocalStack container. You need to create a "tunnel" from your browser all the way through to the Next.js app.

Think about:
- How did you access the EC2 instance via SSH? (port forwarding from LocalStack)
- Can you create a similar port forwarding for port 3000?
</details>

<details>
<summary>Hint 2: Solution Approaches</summary>

There are several valid approaches:

1. **SSH Port Forwarding** (Local Port Forwarding)
   - Use SSH's `-L` flag to forward a local port to a remote port
   - Format: `ssh -L local_port:localhost:remote_port user@host`

2. **Docker Port Mapping**
   - Modify LocalStack's docker-compose.yml to expose additional ports
   - Map EC2 container ports to your host machine

3. **Terraform Configuration**
   - Some Terraform providers support port mapping configuration
   - Check LocalStack's Terraform provider documentation
</details>

<details>
<summary>Hint 3: SSH Port Forwarding Command Pattern</summary>

If you choose SSH port forwarding, the command pattern looks like:

```bash
ssh -i <key> -p <ssh_port> -L <local_port>:localhost:<app_port> <user>@<host>
```

Example breakdown:
- `<key>`: Your private key path (~/.ssh/id_rsa)
- `<ssh_port>`: The port you found for SSH (e.g., 54321)
- `<local_port>`: Port on your machine (e.g., 8080)
- `<app_port>`: Port where Next.js runs (3000)
- `<user>@<host>`: root@127.0.0.1

After connecting, you could access the app at `http://localhost:<local_port>`
</details>

<details>
<summary>Hint 4: Verification</summary>

Once you have a solution:
1. Keep the SSH connection open (with port forwarding)
2. Open your browser
3. Navigate to `http://localhost:XXXX` (where XXXX is your local port)
4. You should see your Next.js application!
</details>

**Deliverable**: Document your solution including:
- The approach you chose
- Complete commands used
- Screenshot of the working application in your browser
- Any challenges you encountered and how you solved them

---

## Troubleshooting Common Issues

### Issue 1: "Error: No valid credential sources found"

**Symptom**: Terraform fails with credential errors

**Solution**:
```bash
# Verify LocalStack is running
curl http://localhost:4566/_localstack/health

# Check terraform provider configuration includes:
# access_key = "test"
# secret_key = "test"
```

### Issue 2: EC2 Instance Not Created

**Symptom**: `tflocal apply` succeeds but no EC2 instance appears

**Solution**:
```bash
# Check LocalStack EC2 service
awslocal ec2 describe-instances

# View LocalStack logs
localstack logs

# Ensure you're using a valid AMI ID for LocalStack
# Use: ami-000001 (ubuntu), ami-000002 (alpine), etc.
```

### Issue 3: Cannot SSH to EC2 Instance

**Symptom**: "Connection refused" or "Connection timeout"

**Solution**:
```bash
# Find the correct SSH port
docker ps | grep localstack-ec2

# Verify your key permissions
chmod 600 ~/.ssh/id_rsa

# Try with verbose output to see error details
ssh -v -i ~/.ssh/id_rsa -p <port> root@127.0.0.1
```

### Issue 4: Docker Build Fails on EC2

**Symptom**: "docker: command not found" or permission errors

**Solution**:
```bash
# Verify Docker is installed
docker --version

# Check Docker service is running
sudo systemctl status docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo
sudo docker build -t my-nextjs-app .
```

### Issue 5: Next.js Container Runs But Shows Error

**Symptom**: Docker container runs but accessing port shows error

**Solution**:
```bash
# Check container logs
docker logs <container-id>

# Verify the build created server.js
docker exec <container-id> ls -la /app/

# Check if next.config.js has output: 'standalone'
cat next.config.js
```

### Issue 6: Port 3000 Already in Use on EC2

**Symptom**: "Address already in use" when running Docker container

**Solution**:
```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill the process or use a different port
docker run -d -p 8080:3000 my-nextjs-app
```

---

### Submission Requirements

Upon completion of the practical, submit the following:

#### 1. Screenshots (Required)

Capture screenshots showing:

**a. Terraform Infrastructure**
- [ ] Successful `tflocal plan` output showing resources to be created
- [ ] Successful `tflocal apply` completion message
- [ ] LocalStack UI showing the EC2 instance (navigate to http://app.localstack.cloud)

**b. SSH Connection**
- [ ] Terminal showing successful SSH connection to EC2 instance
- [ ] Terminal showing the EC2 instance OS information (run `uname -a` and `cat /etc/os-release`)

**c. Docker Deployment**
- [ ] Output of `docker images` showing your built Next.js image
- [ ] Output of `docker ps` showing your running Next.js container
- [ ] Docker logs showing Next.js started successfully (`docker logs <container-id>`)

**d. Working Application**
- [ ] Browser screenshot showing your Next.js application running
- [ ] URL bar must be visible showing the access method (e.g., `localhost:8080`)
- [ ] Application must be functional (not just showing an error page)


#### 2. Documentation (Required)

Create a document (PDF or Markdown) containing:

**a. Setup Process**
- Commands you ran to set up infrastructure
- Any issues encountered and how you resolved them

**b. Challenge Solution**
- Detailed explanation of how you solved the port forwarding challenge
- Complete commands used with explanations
- Why you chose your specific approach
- Alternative approaches you considered

**c. Architecture Diagram**
- Draw a diagram showing the complete network path from your browser to the Next.js application
- Include: Host machine → LocalStack container → EC2 container → Docker container → Next.js app
- Label all port numbers and port mappings

#### 3. Code Files (Required)

Submit the following files:

- [ ] `main.tf` - Your Terraform provider configuration
- [ ] `ec2.tf` - Your EC2 instance resource configuration
- [ ] `Dockerfile` - Your Next.js Dockerfile
- [ ] `next.config.js` - Your Next.js configuration
- [ ] `README.md` - Instructions for running your setup

#### 4. Reflection Questions (Required)

Answer these questions in your documentation:

1. **Infrastructure as Code**: Why is defining infrastructure in Terraform better than manually creating EC2 instances through a web console?

2. **Deployment Comparison**: Compare deploying to EC2 (this practical) vs deploying to S3 (Practical 6). What are the pros and cons of each approach?

3. **Container Challenges**: What was the most challenging aspect of the nested container networking (LocalStack → EC2 → Docker)? How did you overcome it?

4. **Production Differences**: This practical uses LocalStack for local development. What would be different if deploying to real AWS EC2 in production?

5. **Docker Benefits**: Why use Docker to run Next.js on EC2 instead of running Node.js directly on the EC2 instance?

#### 5. Optional Enhancements (Bonus)

For extra credit, implement any of these enhancements:

- [ ] Set up automatic deployment from GitHub to EC2 (similar to Practical 6a)
- [ ] Configure multiple EC2 instances with a load balancer
- [ ] Add monitoring/logging for your Next.js application
- [ ] Implement a CI/CD pipeline for automated testing and deployment
- [ ] Use Terraform modules to make your configuration reusable

---
