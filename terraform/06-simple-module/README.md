# Simple Terraform Module Example

This example demonstrates how to create and use a simple Terraform module to deploy web servers on AWS.

## What is a Terraform Module?

A **Terraform module** is a container for multiple resources that are used together. It's a way to organize and reuse Terraform code.

### Benefits of Modules:
- **Reusability**: Write once, use multiple times
- **Organization**: Keep related resources together
- **Abstraction**: Hide complexity behind simple interfaces
- **Consistency**: Ensure standardized deployments

## Project Structure

```
simple-example/
├── main.tf                    # Main configuration using the module
├── outputs.tf                 # Outputs from main configuration
├── README.md                  # This file
└── modules/
    └── web-server/            # Our custom module
        ├── main.tf            # Module resources
        ├── variables.tf       # Module inputs
        └── outputs.tf         # Module outputs
```

## Module Components

### 1. Module Definition (`modules/web-server/`)

**main.tf**: Contains the actual AWS resources
- Creates an EC2 instance
- Sets up a security group
- Installs Apache web server via user_data

**variables.tf**: Defines input parameters
- `ami_id`: Which AMI to use
- `instance_type`: Size of the instance
- `key_name`: SSH key for access
- `server_name`: Name tag for the server

**outputs.tf**: Defines what the module returns
- `instance_id`: The EC2 instance ID
- `public_ip`: Public IP address
- `public_dns`: Public DNS name

### 2. Module Usage (`main.tf`)

Shows how to use the module multiple times:
```hcl
module "web_server_1" {
  source = "./modules/web-server"
  
  ami_id        = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "my-key-pair"
  server_name   = "web-server-1"
}
```

## How It Works

1. **Module Creation**: The `web-server` module encapsulates the logic for creating a web server
2. **Module Instantiation**: In `main.tf`, we call the module twice to create two identical web servers
3. **Parameter Passing**: Each module call gets different parameters (like `server_name`)
4. **Output Collection**: We collect outputs from each module instance

## Usage Instructions

### Prerequisites
- AWS CLI configured with credentials
- Terraform installed
- An existing AWS key pair

### Steps

1. **Update Configuration**:
   ```bash
   # Edit main.tf and replace "my-key-pair" with your actual key pair name
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan Deployment**:
   ```bash
   terraform plan
   ```

4. **Apply Configuration**:
   ```bash
   terraform apply
   ```

5. **Access Web Servers**:
   ```bash
   # Get the URLs from outputs
   terraform output
   
   # Visit the URLs in your browser
   # You should see "Hello from web-server-1!" and "Hello from web-server-2!"
   ```

6. **Clean Up**:
   ```bash
   terraform destroy
   ```

## Key Concepts Demonstrated

### Module Reusability
- Same module code creates multiple servers
- Each instance can have different parameters
- No code duplication

### Input/Output Flow
```
main.tf → module inputs → module resources → module outputs → main outputs
```

### Module Source Types
- **Local**: `source = "./modules/web-server"` (this example)
- **Git**: `source = "git::https://github.com/user/repo.git"`
- **Registry**: `source = "terraform-aws-modules/vpc/aws"`

## Real-World Applications

This pattern is useful for:
- **Multi-environment deployments** (dev, staging, prod)
- **Standardized infrastructure** across teams
- **Complex infrastructure** broken into manageable pieces
- **Shared components** across multiple projects

## Next Steps

Try modifying the module to:
- Add more security group rules
- Include an Application Load Balancer
- Add CloudWatch monitoring
- Support multiple availability zones