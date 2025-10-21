## Practical 6: Deploying Next.js Application on AWS EC2 using Terraform and Docker with LocalStack Emulation

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
   You can navigate to the following link for more installtion details: https://github.com/localstack/terraform-local

### Step 2: Setting Up LocalStack

1. Navigate to localstack website https://app.localstack.cloud/sign-in and create an account
2. Navigate to the localstack documentation https://docs.localstack.cloud/aws/getting-started/installation/ and follow the instructions to install LocalStack on your machine.

### Step 3: Setting up AWS LOCAL CLI

1. Navigate to https://github.com/localstack/awscli-local and follow the instructions to install AWS LOCAL CLI on your machine.

### Step 5: Creating a Next.js Application with the Starter CLI Command

1. Navigate to the Next.js documentation https://nextjs.org/docs/app/getting-started/installation and follow the instructions to create a Next.js application using the starter CLI command.
2. ```bash
   npx create-next-app@latest my-app --yes
   cd my-app
   npm run dev
   ```

### Step 6: Writing Terraform Configuration Files

We are going to define and provision our physical infrastructure in the cloud uding terraform. This way of creating and defining our physical infrastructure is called Infrastructure as Code (IaC).

Why is this important? For the past decade before Infrastructure as Code (IaC) was introduced, system administrators and DevOps engineers had to manually configure physical hardware and software to set up servers, networks, and other infrastructure components. This manual process was time-consuming, error-prone, and difficult to scale.

```hcl
# Upload the public key to AWS
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Example: Launch an EC2 instance and attach the key pair
resource "aws_instance" "my_instance" {
  ami           = "ami-0e4c28f2c6814846c" # Use a valid AMI for your region
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "My-Terraform-Instance"
  }
}
```

Note: The terraform configuration describes

A. the virtual machine(server) we want to create,
B. the type of operating system we want to use on the server via the AMI-ID (Amazon Machine Image) We have selected the Amazon Linux 2023 Operating System,
C. the instance type (t3.micro) This represents the physical resources that will be virtualise for our server. You can view the list of instance types here: https://aws.amazon.com/ec2/instance-types/, and D. the key pair to be used for secure access to the server.

### Step 7: Create a RSA Key Pair for the EC2 Instance

Navigate and refer to the following documentation to create a RSA Key Pair for your EC2 Instance: https://auth0.com/docs/secure/application-credentials/generate-rsa-key-pair

1. Generate a private key and a public key in PEM. You should safeguard the private key and never share it, not even with Auth0:

`openssl genrsa -out key.pem 2048`

2. Extract the public key in PEM format using the following command. This command extracts the public key details so it can be safely shared without revealing the details of the private key:

`openssl rsa -in key.pem -outform PEM -pubout -out key.pem.pub`

### Step 8: Run and Initialise your LocalStack Instance

Navigate to the following website for more details: https://docs.localstack.cloud/aws/getting-started/auth-token/

To get your AUTH-TOKEN you are required to create an account on localstack website.
Navigate to the settings page on your localstack account and copy your AUTH-TOKEN from the Auth Token Tab.

```bash
localstack auth set-token <YOUR_AUTH_TOKEN>
localstack start
```

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

### Step 10: Connect to your EC2 Instance using SSH

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_INSTANCE_PUBLIC_IP>
```

Do note that the above command assumes that you are using the default production AWS Services.

To explain further, the LocalStack emulates AWS services locally on your machine for development and testing purposes. Therefore, when you create resources like EC2 instances using LocalStack, they are not assigned public IP addresses that are accessible over the internet.

However, the IP address that is created by Localstack of your EC2 instance is actually mapped to a PORT of the LocalStack Docker Container.

Navigate to your Docker Deskstop application, and find the LocalStack container. Click on the container to view its details, and look for the "Ports" section. Here, you will see a list of port mappings between your host machine and the LocalStack container.

Run ```docker ps``` in your terminal to view the port mappings. You should be able to see a mapping that looks something like this format: ```localstack-ec2/ubuntu-noble-ami:ami-000001```

Notice that there will be a PORT forwarding from yourlocalhost/127.0.0.1 tcp/22 to a random PORT on your host machine. This random PORT is the PORT that you will use to connect to your EC2 instance via SSH.

Run the following command to connect to your EC2 instance using SSH:

```bash
ssh -i ~/.ssh/id_rsa -p <RANDOM_PORT> root@127.0.0.1
```

### Step 11: Install Docker & Git on your EC2 Instance
```
yum install git
yum install docker
```

### Step 12: Push & Clone your Next.js Application Repository on your EC2 Instance

Ensure that a Dockerfile has already been created in your next.js application directory.

```docker
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

**IN YOUR LOCAL MACHINE** Push your next.js application to a Git repository (e.g., GitHub, GitLab).

**IN YOUR EC2 INSTANCE** Clone your next.js application repository from the Git repository to your EC2 instance.

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


SIKE, it doesnt work like that. Why? Since we are using localstack, the EC2 instance is not assigned a public IP address that is accessible over the internet. The port in Next.js application is mapped to PORT 3000 on your EC2 machine. 

But the Localstack container which is hosting the EC2 instance has a PORT forwarding from your localhost/3000 to the EC2 instance.

Therefore, you cannot access the application using the EC2 instance IP address. 

Instead, you can access the application by forwarding the port from your localhost to the LocalStack container.

How it looks like:

```Next.js Docker container (localhost:3000)-> EC2 PORT 3000 -> LocalStack Container IP -> LocalStack Container PORT (random port on localhost) -> Local Machine (localhost:random port)``` 

### Challenge Tasks

1. Implement a solution to ensure that the next.js application is able to be querid on your physicval host machine web browser.


### Submission Requirements
Upon completion of the practical, you are required to submit the following:
1. Taking screenshots of:
   - Successful Terraform apply in the terminal and localstack UI
   - Successful SSH connection to the EC2 instance (it should display the corresponsing OS terminal)
   - Successful Docker container run of the next.js app in EC2
   - Deployed website