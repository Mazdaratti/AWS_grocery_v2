# Deployment Guide for AWS Grocery App

## Introduction

This project is part of the **Cloud Track** in our Software Engineering bootcamp at Masterschool. 
The application was originally developed by **Alejandro Román**, our Track Mentor (huge thanks to him!). 
Our task was to design and deploy its **AWS infrastructure step by step**, implementing each component individually.  

Instead of a manual setup, I took the challenge further by **fully automating the provisioning and deployment** using 
**Terraform and GitHub Actions**. This ensures a **scalable, repeatable, and error-resistant deployment process**, 
eliminating the need for manual configurations.  

For details about the **application's features, functionality, and local installation**, refer to the original [`README.md`](README.md) by Alejandro.  

This document focuses exclusively on the **AWS infrastructure, deployment process, and automation**.

---
## Infrastructure Overview

This modularized Terraform configuration provisions the infrastructure for a grocery web application using AWS.
The setup includes:
- An auto-scalable high-available Multi-AZ EC2 environment running Dockerized applications.
- A secure PostgreSQL database on RDS with Failover Replica in private subnets.
- A Multi_AZ Application Load Balancer for traffic distribution.
- An S3 bucket for storing user avatars and database dumps.

The infrastructure is designed for **high availability, scalability, and security**.

---
## Architecture Diagrams

**Resource Overview** 
![Recources](https://github.com/user-attachments/assets/f602fc2d-3778-4e0a-98b0-92051f1e2aa1)


**Networking**
![Networking](https://github.com/user-attachments/assets/bac04d27-f24f-4156-a797-2f1b2f5232c3)

**Security groups**
![Security_groups](https://github.com/user-attachments/assets/be4133e0-34ea-41e5-a27e-f03a5fbfc863)


## Terraform configuration

The Terraform configuration is modularized as follows:

```
/infrastructure
│── /modules
│   ├── alb
│   ├── asg
│   ├── ec2_launch_template
│   ├── iam_ec2
│   ├── iam_lambda
│   ├── lambda
│   ├── rds
│   ├── s3_bucket
│   ├── security_groups
│   ├── vpc
│── main.tf
│── variables.tf
│── outputs.tf
│── terraform.tfvars
│── lambda_data
```

## Infrastructure Components

### **1. Virtual Private Cloud (VPC)**
- **Subnets:** 3 Public (for ALB, EC2) & 3 Private (for RDS).
- **Internet Gateway:** Provides internet access to public subnets.
- **Route Table**: Configured for public subnets routing.
- **VPC Endpoint Gateway:** Provides access to S3 bucket over AWS network.

### **2. Security Groups**
- ALB security group allows ports 80 and 443.
- EC2 security group allows SSH from a specific IP and ALB traffic over port 5000.
- RDS security group allows access only from EC2 instances.
- Lambda security allows outbound connection to RDS instance

### **3. Compute Infrastructure (EC2 & Auto Scaling Group)**
- **Auto Scaling Group (ASG)**:
  - Uses a **Launch Template** with user_data for EC2 configuration.
  - Deploys EC2 instances in public subnets.
  - **Scaling Settings**(adjustable as needed):
- **Docker Deployment**:
  - EC2 instances pull docker image from ECR.
  - Container start automatically.

### **4. Application Load Balancer (ALB)**
- Distributes incoming traffic across EC2 instances via Target Group.
- Listens on port 80 and 443.
- Health check path: `/health`

### **5. Container Registry (ECR)**
- Stores the **Docker image** of the application.
- EC2 instances pull the latest image during launching from the template.

### **6. Database (Amazon RDS - PostgreSQL)**
- **Instance Type:** `db.t3.micro` (free-tier eligible).
- **Multi-AZ Deployment:** Enabled.
- **Security:** Deployed in a **private subnet** with restricted access.

### **7. Storage (S3 Bucket)**
- **Purpose**: Stores user avatar images and db_dump files
- **Configuration**:
  - **Bucket Name**: Set via Terraform variables.
  - **Versioning**: Disabled.
  - **Lifecycle Policy**: Disabled.
  - **Public Access Control**:
    - Block Public ACLs: Disabled.
    - Block Public Policy: Disabled.
  - **Preloaded Avatar**: `user_default.png` is uploaded.
  - **Preloaded db_dump file**: `sqlite_dump_clean.sql` is uploaded
  - **Preloaded lambda_layer file**: `boto3-psycopg2-layer.zip` is uploaded

### **8. IAM Roles & Policies**
- **EC2 Role:** Allows pulling images from ECR and accessing S3.
- **Lambda Role:** Allows accessing S3, describing RDS, managing network.
- **Step Functions Role:** Grants permissions to interact with RDS, S3, and Lambda.
- **S3 Role**: Allows EC2 to access 'avatar' folder and Lambda 'db_dump' folder


### **9. Lambda Function & Step Functions**
- **Purpose**: Ensures the database is populated once the infrastructure is ready.
- **Step Functions**:
  - Monitors **RDS availability**.
  - Waits for the **database dump file to be uploaded to S3**.
  - Triggers the **Lambda function** when conditions are met.
- **Lambda Function**:
  - Retrieves the SQL dump file from **S3**.
  - Connects to **RDS**.
  - Executes the **SQL commands** to populate the database.
- **CloudWatch Logs**:
  - Logs execution of Step Functions and Lambda.
  - Enables debugging of potential issues.
- **EventBridge Triggers**:
  - **Monitors RDS availability** and starts Step Functions.
  - **Detects new database dump uploads** and triggers Step Functions.
  
#### **Workflow Diagram**  

![DB_populator Workflow Diagram](https://github.com/user-attachments/assets/2d925569-f26d-4e48-ac6e-60f37f90b35c)

#### **Workflow Description**
1. **EventBridge Rules**:
   - **RDS Availability Rule**: Monitors the RDS instance for the `RDS-EVENT-0088` event, which indicates that the RDS instance is available. When the RDS instance becomes available, this rule triggers the Step Function.
   - **S3 Upload Rule**: Monitors the specified S3 bucket for the upload of the SQL dump file (`var.db_dump_s3_key`). When the file is uploaded, this rule triggers the Step Function.

2. **Step Functions State Machine**:
   - **WaitForRDS**: Calls the `DescribeDBInstances` API to check the status of the RDS instance. If the RDS instance is not available, it transitions to `HandleRDSFailure`.
   - **CheckRDSStatus**: Checks if the RDS instance status is `available`. If not, it transitions to `HandleRDSFailure`. If available, it proceeds to `CheckS3File`.
   - **CheckS3File**: Calls the `headObject` API to check if the SQL dump file exists in S3. If the file does not exist, it transitions to `WaitForS3File` and retries after 60 seconds.
   - **CheckS3FileExists**: Checks if the `ContentLength` of the S3 object is greater than 0. If the file exists, it proceeds to `TriggerLambda`.
   - **TriggerLambda**: Invokes the Lambda function (`aws_lambda_function.db_populator`). If the Lambda invocation fails, it transitions to `HandleLambdaFailure`.
   - **HandleFailures**: Handles failures for RDS, S3, and Lambda with specific error messages.

3. **Lambda Function**:
   - **Retrieve SQL Dump from S3**: Downloads the SQL dump file from the specified S3 bucket and key. Stores the file in the `/tmp` directory.
   - **Connect to RDS**: Connects to the RDS PostgreSQL instance using the provided credentials (`POSTGRES_HOST`, `POSTGRES_PORT`, etc.).
   - **Execute SQL Commands**: Reads the SQL dump file and executes the SQL commands to populate the database.
   - **Logging**: Logs each step of the process (e.g., connecting to RDS, executing SQL commands) for debugging and monitoring.

4. **CloudWatch Logs**:
   - **Step Function Logs**: Logs the execution of the Step Function, including state transitions and errors. Stored in the `/aws/vendedlogs/states/db-restore-step-function` log group.
   - **Lambda Function Logs**: Logs the execution of the Lambda function, including connection attempts, SQL execution, and errors. Stored in the `/aws/lambda/db_populator` log group.

5. **Error Handling**:
   - **RDS Failure**: If the RDS instance is not available, the Step Function transitions to `HandleRDSFailure` and logs the error.
   - **S3 Failure**: If the SQL dump file is not found in S3, the Step Function transitions to `HandleS3Failure` and logs the error.
   - **Lambda Failure**: If the Lambda function fails to execute, the Step Function transitions to `HandleLambdaFailure` and logs the error.
---

## Terraform Modules

This infrastructure is modularized for reusability and maintainability:

### 1. `alb`
- Deploys an **Application Load Balancer**.
- Configures a **target group** for EC2 instances.

### 2. `asg`
- Configures the **Auto Scaling Group (ASG)** with:
  - Desired, min, and max instance counts.
  - Public subnet IDs for instance placement.
  - **Load balancer target group** attachment.

### 3. `lambda`
  - Step Functions, using CloudWatch and EventBridge, monitors RDS availability and 
    checks for the database dump file in S3.
  - Lambda Function:
    - Retrieves the SQL dump file from S3.
    - Connects to RDS.
    - Executes the SQL commands to populate the database.

### 4. `ec2_launch_template`
- Defines the **EC2 Launch Template** with:
  - Custom **AMI ID**.
  - Instance type (`t2.micro`).
  - **IAM** instance **profile**.
  - **Security Group**.
  - Volume configuration (20GB `gp3`).

### 5. `iam_ec2`
- Creates an **IAM Role** for EC2 instances.
- Outputs IAM role and instance profile names.

### 6. `iam_lambda`
- Creates an **IAM Role** for Lambda Function.
- Outputs IAM role arn and IAM role name.

### 7. `rds`
- Provisions an Amazon **RDS PostgreSQL** instance.
- Configures security groups and backup settings.
- Can optionally Use a snapshot for database restoration.
- Outputs **RDS Endpoint**.

### 8. `s3_bucket`
- Creates an **S3 Bucket** for storing user avatars, sql dump files and lambda layers.
- Configures lifecycle rules and permissions.

### 9. `security_groups`
- Defines **Security Groups** for ALB, EC2, RDS and Lambda.
- Outputs security group **IDs** for use in other modules.

### 10. `vpc`
- Provisions the **VPC**, **Subnets**, **Route Tables**, **Internet Gateway**, and **VPC Endpoint Gateway**.
- Outputs **VPC ID**, **Public Subnet IDs**, and **Private Subnet IDs**.

## Conclusion
This modular Terraform setup ensures a scalable and secure AWS infrastructure for the grocery web application. Each module can be reused and modified independently, 
making it easy to maintain and extend the architecture as needed. 
The addition of Lambda, Step Functions, and EventBridge automates the database population process, while S3 provides flexible storage for user avatars, database dumps, and lambda layers.

# Deployment Guide

This document provides a step-by-step guide to deploying the AWS infrastructure for the grocery web application using Terraform and GitHub Actions.

---

## **Automated Deployment Workflow Overview**

This project uses **GitHub Actions** to automate the infrastructure provisioning and deployment process. The workflow consists of two phases:

### **Phase 1: Provision Core Resources & Build the Docker Image**
1. Provisions core infrastructure:
   - **VPC, Subnets, and Security Groups**
   - **IAM Roles & Policies**
   - **Amazon RDS (PostgreSQL)**
   - **S3 bucket for storing user avatars**
   - **Elastic Container Registry (ECR)**
2. Retrieves Terraform outputs (e.g., `POSTGRES_HOST`, `ECR_REPOSITORY_URL`).
3. Generates a `.env` file for the application.
4. Builds and pushes the Docker image to ECR.

### **Phase 2: Deploy the Application & Populate Database**
1. Provisions the remaining infrastructure:
   - **Auto Scaling Group (ASG) and Launch Template**
   - **Application Load Balancer (ALB)**
   - **EC2 instances**
2. **Step Functions & Lambda Function**:
   - Step Functions **waits for RDS to become available**.
   - **Checks for the database dump file in S3**.
   - Triggers a **Lambda function** that retrieves the dump file and populates the database.
3. EC2 instances pull the Docker image from ECR and start the application.

This approach ensures **proper dependency management**, avoiding race conditions.

### **Workflow Steps**

1. **Checkout Repository**
2. **Configure AWS Credentials**
3. **Setup Terraform**
4. **Initialize Terraform**
5. **Set Terraform Variables**
6. **Apply Terraform (Phase 1)**
7. **Retrieve Terraform Outputs**
8. **Generate .env File**
9. **Build Docker Image**
10. **Tag and Push Docker Image**
11. **Delete .env File**
12. **Apply Terraform (Phase 2)**

### **Triggering the Workflow**
The workflow is automatically triggered on pushes to the `main` branch.

### **GitHub Secrets**
The following secrets must be configured in the GitHub repository:
(see *Step-by-Step Deployment Guide*)

---

## Step-by-Step Deployment Guide

Follow these steps to clone the repository and deploy the application:

### Step 1: Create an AWS Account
1. Go to [AWS Sign-Up](https://aws.amazon.com/) and create a new AWS account.
2. Complete the registration process and verify your email address.

### Step 2: Create an IAM User and Access Keys
1. Log in to the AWS Management Console.
2. Navigate to **IAM (Identity and Access Management)** > **Users** > **Create User**.
3. Enter a username (e.g., `terraform-user`) and enable **Programmatic access**.
4. Attach the following policies:
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `CloudWatchFullAccess`
5. Review and create the user.
6. Download the **Access Key ID** and **Secret Access Key**.

### Step 3: Install and Configure AWS CLI
1. Install the AWS CLI:
   - [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. Configure the AWS CLI with your credentials:
   ```bash
   aws configure
   ```
   - Enter the Access Key ID and Secret Access Key from Step 2.
   - Set the default region (e.g., `eu-central-1`).
   - Leave the default output format as `json`.

### Step 4: Create an SSH Key Pair for EC2 Instances
1. Navigate to **EC2 > Key Pairs > Create Key Pair**.
2. Enter a name (e.g., `grocery-key`) and choose `pem` as the format.
3. Download the `.pem` file and store it securely.

### Step 5: Clone the Repository
```bash
git clone https://github.com/Mazdaratti/AWS_grocery_v2.git
cd AWS_grocery_v2
```

### Step 6: Set Variables in GitHub Secrets
1. Go to your GitHub repository.
2. Navigate to **Settings > Secrets and variables > Actions**.
3. Click **New repository secret** and add the following secrets:

#### AWS Authentication Variables
| Secret Name       | Description             | Example Value         |
|-------------------|-------------------------|-----------------------|
| aws_access_key_id | AWS Access Key ID       | `AKIAXXXXXXXXXXXXXXXX` |
|aws_secret_access_key | AWS Secret Access Key   | `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` |

#### Terraform Variables
| Secret Name            | Description                         | Example Value         |
|------------------------|-------------------------------------|-----------------------|
| TF_VAR_region         | AWS region                          | `eu-central-1` |
| TF_VAR_db_user        | RDS database username               | `admin` |
| TF_VAR_db_password    | RDS database password               | `SecurePassword123!` |
| TF_VAR_db_name        | RDS database name                   | `grocery_db` |
| TF_VAR_bucket_name    | S3 bucket name (unique!!!)          | `my-grocery-bucket-v5` |
| TF_VAR_key_name       | SSH key pair name                   | `grocery-key` |
| TF_VAR_ami_id         | AMI ID for EC2 instances (optional) | `ami-06ee6255945a96aba` |
| TF_VAR_allowed_ssh_ip | IP address allowed for SSH          | `192.168.1.1/32` |
| TF_VAR_snapshot_id    | RDS snapshot ID (optional)          | `snap-0123456789abcdef0` |

#### Environment Variables
| Secret Name         | Description                   | Example Value         |
|--------------------|-----------------------------|-----------------------|
| JWT_SECRET_KEY    | Secret key for JWT token generation | `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`|

### Step 7: Deploy the Infrastructure

1. Push your changes to the main branch to trigger the GitHub Actions workflow.
2. The workflow will:

    - Create the VPC, subnets, and security groups.
    - Provision the RDS instance and S3 bucket.
    - Build and push the Docker image to ECR.
    - Launch EC2 instances using the Auto Scaling Group (ASG).
    - Configure the Application Load Balancer (ALB) and attach the EC2 instances.

### Step 8: Verify the Deployment

1. After the workflow completes, check the outputs in the GitHub Actions logs.
2. Use the ALB DNS Name output to access the application in your browser.
3. SSH into an EC2 instance using the key pair created earlier:

    ```bash
    ssh -i path/to/your-key.pem ec2-user@<EC2_PUBLIC_IP>
    ```
---
## Conclusion

This GitHub Actions driven fully automated deployment of the Grocery App on AWS ensures continuous deployment with minimal manual intervention. 
The modular structure allows for easy scaling and customization, making it adaptable for future enhancements.

🚀 Happy Deploying!

---

## Troubleshooting

**Issue: Terraform Plan Fails**
- **Cause:** Missing or incorrect variables in GitHub Secrets.
- **Solution:** Ensure all required variables are set.

**Issue: EC2 Instances Not Starting**
- **Cause:** Incorrect IAM role permissions or issues with `user_data`.
- **Solution:** Verify IAM permissions and check EC2 logs.

**Issue: Lambda Function Fails to Populate Database**
- **Cause:** Incorrect S3 permissions or RDS security group.
- **Solution:** Verify Lambda IAM role and RDS security group were created and attached.

---

## FAQ

### Q: How do I change the instance type?
A: Update the `instance_type` variable in `terraform.tfvars`.

### Q: How do I access the RDS database?
A: Use the **RDS Endpoint** output to connect to the database from an EC2 instance.

### Q: How do I extend the infrastructure?
A: Add new modules or modify existing ones in the `modules` directory.

## Glossary

- **VPC**: Virtual Private Cloud.
- **ALB**: Application Load Balancer.
- **ASG**: Auto Scaling Group.
- **ECR**: Elastic Container Registry.
- **RDS**: Relational Database Service.
- **IAM**: Identity and Access Management.

## Future Enhancements

- ✅Implement **CI/CD pipelines** for automated deployments.
- ✅Integrate **AWS Lambda** for migration of local database to rds.
- Implement **Terraform Remote Backend**

## Creating the AWS Lambda Layer for Boto3 and Psycopg2

To ensure the AWS Lambda function has the required dependencies (`boto3` and `psycopg2`), a Lambda layer is built using Docker. This approach ensures compatibility with AWS Lambda’s execution environment.

### 1. Setting Up a Separate Project for Layer Creation

A dedicated project directory is used to build the layer separately. The directory structure is as follows:
```
Lambda_layer_docker_project/
│── lambda_layer/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── python/
│── output/
│   ├── lambda-layer.zip
│── .venv/
└── lambda_function/
    └── lambda_function.py
```

- **`lambda_layer/`**: Contains the `Dockerfile`, `requirements.txt` and python/ directory where dependencies are installed.  
- **`output/`**: Stores the generated Lambda layer ZIP file.  
- **`lambda_function/`**: Contains the actual Lambda function that utilizes the layer.  

### 2. Dockerfile for Layer Creation

The Lambda layer is built using the official Amazon SAM Python 3.12 build container image:

**Base Image:**  
`public.ecr.aws/sam/build-python3.12:1.135.0-20250310201002-x86_64`
https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-image-repositories.html
https://gallery.ecr.aws/sam/build-python3.12

#### **Dockerfile**

```dockerfile
# Use AWS SAM Python 3.12 build image
FROM public.ecr.aws/sam/build-python3.12:1.135.0-20250310201002-x86_64

# Set the working directory
WORKDIR /var/task

# Install dependencies in a format compatible with AWS Lambda
COPY requirements.txt .
RUN pip install -r requirements.txt -t python/

# Zip the layer for deployment
RUN zip -r /output/lambda-layer.zip python/ 

```  
### 3. Dependencies for the Layer

The required dependencies are listed in requirements.txt:

``` requirements.txt
boto3
psycopg2-binary
```

The `Dockerfile` performs the following steps:

1. **Starts from the Amazon SAM Python 3.12 image.**
2. **Installs required dependencies (`boto3` and `psycopg2`).**
3. **Packages them in a ZIP file under `python/` (AWS Lambda Layer format).**

### 4. Building the Lambda Layer with Docker

To create the layer, run the following commands inside the `Lambda_layer_docker_project` directory:

```sh
# Build the Docker container
docker build -t lambda-layer .

# Create a container from the image
docker run --rm -v $(pwd)/output:/output lambda-layer
```
### 4. Expected Output

After running the above commands, the output/ directory will contain lambda-layer.zip, 
which is ready to be deployed as an AWS Lambda Layer; 
ensure the created layer is renamed meaningfully (e.g., boto3-psycopg2-layer.zip) before deploying.

This version keeps the focus on how the layer is created using Docker. 
Let me know if you need any tweaks! 🚀

### **Contributing**

We welcome contributions! Follow these steps:
- **Fork** the repository
- **Create a feature branch**: git checkout -b feature/your-feature
- **Implement changes & commit**
- **Push & create a Pull Request (PR)**

### **License**

This project is licensed under the MIT License and is free for non-commercial use.
