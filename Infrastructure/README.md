# Terraform Infrastructure for AWS Grocery App

## Overview

This modularized Terraform configuration provisions the infrastructure for a grocery web application using AWS. 
The setup includes an auto-scalable EC2 environment running Dockerized applications, a secure PostgreSQL database on RDS,
an Application Load Balancer for traffic distribution, and an S3 bucket for storing user avatars. 
The infrastructure is designed for high availability, scalability, and security.

## Project Diagrams
![Resources_v2](https://github.com/user-attachments/assets/379a8a3a-9270-4ce2-bc57-aed5c9747dd2)

![Recources](https://github.com/user-attachments/assets/26ab4fdc-c449-4e68-9ef3-a16afaf22977)

![Networking](https://github.com/user-attachments/assets/bac04d27-f24f-4156-a797-2f1b2f5232c3)

![Security_groups](https://github.com/user-attachments/assets/be4133e0-34ea-41e5-a27e-f03a5fbfc863)

## Project Structure

The Terraform configuration is modularized as follows:

```
/infrastructure
│── /modules
│   ├── alb
│   ├── asg
│   ├── cloudwatch_logging
│   ├── ec2_launch_template
│   ├── iam_role
│   ├── lambda
│   ├── rds
│   ├── s3_bucket
│   ├── security_groups
│   ├── vpc
│── main.tf
│── variables.tf
│── outputs.tf
│── terraform.tfvars
│── README.md
```
## Infrastructure Components

### 1. **Virtual Private Cloud (VPC)**
- **VPC Name**: `grocery-vpc`
- **Subnets**:
    - 3 Public Subnets for ALB and EC2 instances.
    - 3 Private Subnets for RDS to ensure security.
- **Internet Gateway**: Provides internet access to public subnets.
- **Route Table**: Configured for public subnets routing.

### 2. **Security Groups**
- ALB security group allows ports 80 and 443.
- EC2 security group allows SSH from a specific IP and ALB traffic over port 5000.
- RDS security group allows access only from EC2 instances.

### 3. **Compute Infrastructure (EC2 & Auto Scaling Group)**
- **Preconfigured AMI**: EC2 instances use a custom AMI with Docker, Docker Compose, and necessary configurations.
- **Auto Scaling Group (ASG)**:
  - Uses a **Launch Template** for EC2 configuration.
  - Deploys EC2 instances in public subnets.
  - **Scaling Settings**(adjustable as needed):
    - Minimum: 1
    - Maximum: 4
    - Desired: 3 
- **Docker Deployment**:
  - EC2 instances pull docker image from ECR.
  - Container start automatically using start.sh.

### 4. **Application Load Balancer (ALB)**
- Distributes incoming traffic across EC2 instances via Target Group.
- Listens on port 80 and 443.
- Health check path: `/health`

### 5. **Container Registry (ECR)**
- One ECR repository is provisioned:
  - `aws_grocery-app` (Application container image)
 

### 6. **Database (Amazon RDS - PostgreSQL)**
- **Engine**: PostgreSQL
- **Instance Type**: `db.t3.micro`
- **Multi-AZ Deployment**: Enabled
- **Storage**: 20 GB (gp2)
- **Backup**: A snapshot is used for data restoration.
- **Security**:
  - Deployed in private subnets for security.
  - Security Group allows access only from EC2 instances.

### 7. **Storage (S3 Bucket)**
- **Purpose**: Stores user avatar images.
- Public `avatars/` folder for GET and PUT requests.
- **Configuration**:
  - **Bucket Name**: Set via Terraform variables.
  - **Versioning**: Disabled.
  - **Lifecycle Policy**: Disabled.
  - **Public Access Control**:
    - Block Public ACLs: Disabled.
    - Block Public Policy: Disabled.
  - **CORS**: Configured for frontend access.
  - **Preloaded Avatar**: `user_default.png` is uploaded.

### 8. **IAM Roles & Policies**
- **IAM Role for EC2**:
  - Allows EC2 instances to pull images from **ECR**.
  - Grants **full access to S3** for avatar storage.
- **IAM Instance Profile**: Assigned to EC2 instances.

### 9. **CloudWatch Logging and Monitoring**
  - CloudWatch Log Group: /myapp/docker-logs
  - Log Retention: 30 days.
  - Log Collection:
    - Collects logs from /var/log/docker on EC2 instances.
    - Logs are streamed to CloudWatch for centralized monitoring.
  - IAM Role: Attaches the CloudWatchAgentServerPolicy to the EC2 role.

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

### 3. `cloudwatch_logging`
  - Creates a **CloudWatch Log Group** for application logs.
  - Attaches the **CloudWatchAgentServerPolicy** to the EC2 IAM role.

### 3. `ec2_launch_template`
- Defines the **EC2 Launch Template** with:
  - Custom **AMI ID**.
  - Instance type (`t2.micro`).
  - **IAM** instance **profile**.
  - **Security Group**.
  - Volume configuration (20GB `gp3`).

### 4. `iam_role`
- Creates an **IAM Role** for EC2 instances.
- Outputs IAM role and instance profile names.

### 5. `rds`
- Provisions an Amazon **RDS PostgreSQL** instance.
- Configures security groups and backup settings.
- Uses a snapshot for database restoration.
- Outputs **RDS Endpoint**.

### 6. `s3_bucket`
- Creates an **S3 Bucket** for storing user avatars.
- Configures lifecycle rules and permissions.

### 7. `security_groups`
- Defines **Security Groups** for ALB, EC2, and RDS.
- Outputs security group **IDs** for use in other modules.

### 8. `vpc`
- Provisions the **VPC**, **Subnets**, **Route Tables**, and **Internet Gateway**.
- Outputs **VPC ID**, **Public Subnet IDs**, and **Private Subnet IDs**.

## Variables
The following variables should be configured in `terraform.tfvars`:
```hcl
allowed_ssh_ip     = "YOUR_IP_ADDRESS"
ami_id             = "YOUR_CUSTOM_AMI_ID"
snapshot_id        = "YOUR_RDS_SNAPSHOT_ID"
key_name           = "YOUR KEY PAIR NAME"
bucket_name        = "YOUR_S3_BUCKET_NAME" Should be UNIQUE!!!
```
## Outputs
After deployment, Terraform provides the following outputs:
- **ALB ARN**
- **ALB DNS Name**
- **ALB Security Group ID**
- **Auto Scaling Group ID**
- **DB Instance Endpoint**
- **DB Subnet Group Name**
- **EC2 Security Group ID**
- **ECR Repository URL**
- **IAM Instance Profile Name**
- **IAM Role ARN**
- **IAM Role Name**
- **Internet Gateway ID**
- **Launch Template ID**
- **Launch Template Name**
- **Log Group Name**
- **Private Subnet IDs**
- **Public Subnet IDs**
- **RDS ID**
- **RDS Security Group ID**
- **S3 Bucket ARN**
- **S3 Bucket ID**
- **S3 Bucket Name**
- **Target Group ARN**
- **VPC ID**

## Deployment Steps
1. Install Terraform and AWS CLI.
2. Configure AWS credentials using `aws configure` or SSO.
3. Navigate to the Terraform directory and initialize Terraform:
   ```sh
   terraform init
   ```
4. Plan the deployment:
   ```sh
   terraform plan
   ```
5. Apply the configuration:
   ```sh
   terraform apply
   ```
6. Once deployed, note the outputs for connecting to your resources.

## Notes
- Ensure your AWS credentials have the necessary permissions before applying Terraform.
- Modify `terraform.tfvars` to customize variables for your deployment.
- To destroy the infrastructure, use:
  ```sh
  terraform destroy
  ```
## Troubleshooting

### Issue: Terraform Plan Fails
- **Cause**: Missing or incorrect variables in `terraform.tfvars`.
- **Solution**: Ensure all required variables are set in `terraform.tfvars`.

### Issue: EC2 Instances Not Starting
- **Cause**: Incorrect AMI ID or IAM role permissions.
- **Solution**: Verify the AMI ID and ensure the IAM role has the necessary permissions.

### Issue: CloudWatch Logs Not Appearing
- **Cause**: CloudWatch Logs Agent not installed or configured correctly.
- **Solution**: Check the EC2 instance logs and ensure the CloudWatch Logs Agent is running.

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

- Implement **CI/CD pipelines** for automated deployments.
- Integrate **AWS Lambda** for migration of local database to rds.


## Conclusion
This modular Terraform setup ensures a scalable and secure AWS infrastructure for a grocery web application. 
Each module can be reused and modified independently, making it easy to maintain and extend the architecture as needed.
The addition of CloudWatch Logging and Monitoring provides centralized logging for easier debugging and monitoring.
🚀

