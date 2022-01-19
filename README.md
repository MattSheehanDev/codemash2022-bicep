# Consistent cloud environments with Infrastructure as Code

This repo contains slides and resources for the talk _Consistent cloud environments with Infrastructure as Code_ given at CodeMash 2022.

## Abstract
Your SaaS app is doing great, but your cloud environment is growing more and more complex. After years of provisioning additional resources to keep it growing, nobody on the team remembers all of the dependencies anymore, and deployments are hitting snags because the development, testing, and production environments are inconsistent.

In this talk, you'll learn how to embrace Infrastructure as Code starting with Microsoft Azure. Together we'll create a robust Bicep script that can deploy to multiple environments, keeping them consistent. The days of your infrastructure being undocumented and inconsistent are over with a code-first, version-controlled method of managing cloud resources.

## Slides
Google Slides are available [here](https://docs.google.com/presentation/d/1JUkeS9w-hNgHlYq1b6NRgKHFX5Z_yqis1Zsb8eyXvRI/edit?usp=sharing).

## Code

To deploy the scripts to your own Azure Subscription.

```sh
# Create resource group
az group create -n $RG_Name -l $RG_Location

# Create deployment
az deployment group create -f <path-to-bicep> -g <resource-group-name> --parameters ./parameters.json
```