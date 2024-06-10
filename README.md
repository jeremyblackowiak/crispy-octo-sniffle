# Crispy Octo Sniffle

Welcome to `pipeline-demo`!

overview

tools used

infrastructure deployed

what i'd do with more time: something else for manifests, stuff from ntoes

## Todos

- Linting
- Apply manifests with Terraform? 
- Handle multiple environments, "configs" app directory, etc. 

## First Time Setup

### Prerequisites

- An AWS account
   - A Route53 zone to use for DNS record creation
   - An S3 bucket to use for storing Terraform state
   - An ECR repository to use for storing app image artifacts
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

## First Time Setup

### Github Actions / Local Shared Steps

1. **Clone the repository**

   Use your preferred method to clone the repository to your local machine.
2. Update [the terraform.tf backend configuration](./packages/infrastructure/terraform.tf#L6) to use your S3 bucket.
3. Update [the aws_route53_zone data block](./packages/infrastructure/ingress.tf#L101) and the [externalDNS hostname configuration](./packages/manifests/ingress.yaml#L7) to use your Route53 zone.
4. Update the [eks_admins_iam_group group_users array](./packages/infrastructure/main.tf#L206) to include your CI user's username, or simply comment out the line if you don't intend to use Github Actions. 
5. Replace [{ecrRepository}](./packages/app/project.json#L10) with your ECR repository. 


### Github Actions Execution

1. Commit and push your changes to the main branch.
2. Set up the CI user AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY values as Github Actions secrets with the same name.
3. Run the "Infrastructure Deployment" Github Actions [workflow_dispatch workflow](https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow). This will deploy all the infrastructure resources described in the overview, and provide several outputs that you'll use in the next steps. 
4. Replace [{myCluster}](./packages/manifests/project.json#L206) with the name of the cluster created in step 3. 
5. Replace [{OutputArn}](./packages/manifests/ingress.yaml#L6) with the ACM certificate arn created in step 3

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