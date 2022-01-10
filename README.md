# CodeMash 2022 - Consistent cloud environments with Infrastructure as Code - Code Examples

```sh
# Create resource group
az group create -n $RG_Name -l $RG_Location

# Create deployment
az deployment group create -f <path-to-bicep> -g <resource-group-name> --parameters ./parameters.json
```

Google Slides are available [here](https://docs.google.com/presentation/d/1JUkeS9w-hNgHlYq1b6NRgKHFX5Z_yqis1Zsb8eyXvRI/edit?usp=sharing).
