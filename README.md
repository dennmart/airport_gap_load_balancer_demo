# Deploy Secure Load Balancers on Hetzner Cloud with Terraform

This repository contains the demo configuration used in the video "Deploy Secure Load Balancers on Hetzner Cloud with Terraform" on the [Dev Tester YouTube channel](https://www.youtube.com/@DevTesterBlog).

## Resources created

The Terraform configuration in this project ([`main.tf`](/main.tf)) creates the following resources on [Hetzner Cloud](https://www.hetzner.com/cloud) in the Hillsboro, Oregon network zone:

- A firewall
- A private network and subnet
- Six cloud servers
- A load balancer
- Targets for the load balancer
- A service for the load balancer
- A managed SSL certificate

## API token

If you want to reuse this configuration for deploying these resources on your Hetzner Cloud account, you'll first need to [create an API token on Hetzner Cloud](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/). Once you have a token, create a `terraform.tfvars` file in the root of this repository with the following content:

```
hetzner_cloud_api_token = "<Your Hetzner Cloud API token>"
```

## Deploying the resources

- First, set up the Terraform project by running the `terraform init` command,.
- Run the `terraform validate` command to ensure the configuration syntax is valid.
- Check that your API token is set up properly by running `terraform plan` to verify which resources will be created.
- When you're ready to deploy, run `terraform apply` to create the resources on your Hetzner Cloud project.

For an example on using Terraform to deploy your infrastructure on Hetzner Cloud, check out the video ["Rails Deployments Made Easy with Terraform and Kamal"](https://youtu.be/uVGo7eZr6wU) on the [Dev Tester YouTube channel](https://www.youtube.com/@DevTesterBlog).
https://youtu.be/uVGo7eZr6wU
