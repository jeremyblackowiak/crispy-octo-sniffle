# Crispy Octo Sniffle

Welcome to `pipeline-demo`!

overview

tools used

infrastructure deployed

what i'd do with more time: something else for manifests, stuff from notes, deploy proper image tags, changesets

## Todos

- Does the cluster check for "latest" image tag? How often? 
- Linting
- Apply manifests with Terraform? 
- Add a CI health check for pull requests
- Handle multiple environments, "configs" app directory, etc. 



### Prerequisites

- An AWS account
   - A Route53 zone to use for DNS record creation
   - An S3 bucket to use for storing Terraform state
   - An ECR repository to use for storing app image artifacts
   - Access keys for a "CI" AWS user with wide permissions (#TODO: Add policy needed)
- A *nix machine with Docker for Desktop or Rancher installed, if running locally
- Github Actions enabled on the Github repo 
- ASDF installed. Follow the instructions on the [ASDF GitHub page](https://github.com/asdf-vm/asdf) to install it.


## First Time Setup, Metadata and Infrastructure

### Basic Setup

1. **Clone the repository**

   Use your preferred method to clone the repository to your local machine.
2. Run `asdf install`.
2. Update [the terraform.tf backend configuration](./packages/infrastructure/terraform.tf#L6) to use your S3 bucket.
3. Update [the aws_route53_zone data block](./packages/infrastructure/ingress.tf#L101), the [externalDNS hostname configuration](./packages/manifests/ingress.yaml#L7), the [ci-cd workflow](./.github/workflows/ci-cd.yml#L42), and the [readme](./README.md#github-actions-app-deployment) to use your Route53 zone.
4. Update the [eks_admins_iam_group group_users array](./packages/infrastructure/main.tf#L206) to include your CI user's username, or simply comment out the line if you don't intend to use Github Actions. 
5. Replace [{ecrRepository}](./packages/app/project.json#L10) with your ECR repository name, and [{ecrRepoURL}](./packages/manifests/deployment.yaml#L17) with the full public URL of the ECR repository. 
6. Commit and push your changes to the main branch.
7. If only running locally, go to "Local Infrastructure Setup" section.


### Github Actions Infrastructure Setup

1. Set up the CI user AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY values as Github Actions secrets with the same name.
2. Run the "Infrastructure Deployment" Github Actions [workflow_dispatch workflow](https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow). This will deploy all the infrastructure resources described in the overview, and provide several outputs that you'll use in the next steps. 
3. Replace [{myCluster}](./packages/manifests/project.json#L206) with the name of the cluster created in step 3. 
4. Replace [{OutputArn}](./packages/manifests/ingress.yaml#L6) with the ACM certificate arn created in step 3
5. Commit and push your changes to the main branch.

### Local Infrastructure Setup

1. Set up the CI user AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION=us-east-1 values as environment variables of the same names in your terminal session. 
2. From the root of the repository, run `./nx build-infra infrastructure`. This will install the toolchain, init Terraform, and create a Terraform plan for the infrastructure. Type yes to continue creation. This will deploy all the infrastructure resources described in the overview, and provide several outputs that you'll use in the next steps. 
3. Replace [{myCluster}](./packages/manifests/project.json#L206) with the name of the cluster created in step 3. 
4. Replace [{OutputArn}](./packages/manifests/ingress.yaml#L6) with the ACM certificate arn created in step 3


## Deploying and Redeploying the App

Follow these steps for regular use of the project:

### Github Actions App Deployment

1. Create a pull request with your updates to the app.
2. Merge the pull request into the `main` branch.
3. The CI-CD workflow will build the app container, publish it to ECR, then apply the manifests to the EKS cluster.
4. Access the app at https://app.{myZone}

