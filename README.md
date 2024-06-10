# Crispy Octo Sniffle

Welcome to `pipeline-demo`!

## First Time Setup

### Prerequisites

- An AWS account
   - A Route53 zone to use for DNS record creation
   - An S3 bucket to use for storing Terraform state
   - Access keys for a "CI" AWS user with wide permissions (#TODO: Add policy needed)
- A *nix machine with Docker for Desktop or Rancher installed, if running locally
- Github Actions enabled on the Github repo 

Follow these steps to set up the project for the first time:

0. Create an S3 Bucket for State
00. Create myZone 
You'll need Docker
If you want to deploy Infra locally
Setting AWS keys
Cluster name needs to be put into manifests commands.

Create a prereqs section

### Github Actions Execution

1. Set up your AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION as Github Actions secrets

### Local Execution

1. **Clone the repository**

   Use your preferred method to clone the repository to your local machine.

2. **Install ASDF for toolchain management**

   Follow the instructions on the [ASDF GitHub page](https://github.com/asdf-vm/asdf) to install it.

3. **Install the required tools**

   Run `asdf install` in the terminal to install the required tools.

4. **Set AWS Key Environment Variables**

    Set up your AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION as environment variables in your terminal session.

4. **Apply the VPC module**

   Run `terraform apply --target=module.vpc` in the terminal to apply the VPC module.

5. **Apply the remaining Terraform configuration**

   Run `terraform apply` in the terminal to apply the remaining Terraform configuration.

## Regular Use

Follow these steps for regular use of the project:

1. **Ensure the required tools are installed**

   Run `asdf install` in the terminal to ensure the required tools are installed.

2. **Update the cluster**

   Follow your established procedures to update the cluster.

3. **Update the service**

   Follow your established procedures to update the service.