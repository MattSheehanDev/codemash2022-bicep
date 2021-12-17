# CodeMash 2022 - Consistent cloud environments with Infrastructure as Code - Code Examples

```sh
# Create resource group
az group create -n $RG_Name -l $RG_Location

# Create deployment
az deployment group create -f ./main.bicep -g $RG_Name --parameters ./parameters.json
```

Google Slides are available [here](https://docs.google.com/presentation/d/1QVMG_8eftTfOWO2hQtTs7wyS2bw-OVU2AQLeBsa_KGM/edit?usp=sharing).
