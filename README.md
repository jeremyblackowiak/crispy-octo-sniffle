# Crispy Octo Sniffle

Welcome to `pipeline-demo`!

## Overview

This project is meant to demonstrate an example web app deployment pipeline, including the deployment of the compute infrastructure to run it. 

The tools used are

- ASDF: Toolchain installation management. 
- NX of nx.dev: This is a monorepo orchestration tool that is typically used in node repositories, but can be used in others. I use it here to orchestrate command dependencies across the project to simplify the necessary inputs (either by local user or by CI) to get the operations done. 
- Terraform: I used Terraform to declare VPC, EKS, IAM, and AWS Load Balancer Controller/ExternalDNS deployments infrastructure.
- EKS: Rolling your own Kubernetes cluster is its own task, but EKS is a lot more turnkey!
- Github Actions: Everyone's favorite CI/CD platform! I created a `workflow_dispatch` conditioned infrastructure.yaml workflow for ad-hoc deployment of the infrastructure, and a cicd.yaml workflow that deploys app updates to the cluster when a pull request is merged into the main branch. 
- Github Copilot: I used Copilot as a kind of assistant search engine for first leads on how to declare certain infrastructure resources with Terraform. I think it probably saved me a ton of time crawling through documentation for Terraform and Kubernetes configuration, which I'm still acquainting myself with. 

### Things I'm Still Figuring Out

- Authentication with Kubernetes: I haven't worked with Kubernetes clusters in a while (mostly use ECS), and I hit several snags. I had to use `--insecure-skip-tls-verify` with kubectl on newly spawned EKS clusters in order to interact. Still don't know what's going on there. 
- AWS Load Balancer Controller and ExternalDNS: These declarations in Terraform and the related annotations in the manifests should be directionally correct if I'm understanding the documentation right, but my struggles with auth meant I didn't get them fully working. 
- A good tool for templating, versioning, and applying app manifests. I believe Helm is part of the equation, but not sure what the best in class solutions are yet. I considered just applying these manifests with Terraform, but I didn't want to lock in too hard! 

### What I'd Do With More Time

- Some tooling for bootstrapping the necessary user creation, s3 bucket creation, zone creation, etc. 
- Parameterize the Terraform, invoke as a module; consume and use app/configs values to support multiple environments; properly increment the app image tag for releasing, that kind of thing.
- Add a CI health check job for pull requests
- Add linting, prettier features. 


## Prerequisites

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

### Local App Deployment

1. From the root of the repository, run `./nx local-deploy app`. 
2. Access the app at https://app.{myZone}

