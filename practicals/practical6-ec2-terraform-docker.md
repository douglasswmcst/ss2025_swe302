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

### Step 7: Create a RSA Key Pair for the EC2 Instance

Navigate and refer to the following documentation to create a RSA Key Pair for your EC2 Instance: https://auth0.com/docs/secure/application-credentials/generate-rsa-key-pair

1. Generate a private key and a public key in PEM. You should safeguard the private key and never share it, not even with Auth0:

```openssl genrsa -out key.pem 2048```

2. Extract the public key in PEM format using the following command. This command extracts the public key details so it can be safely shared without revealing the details of the private key:

```openssl rsa -in key.pem -outform PEM -pubout -out key.pem.pub```
