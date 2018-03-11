# wing-commander 

## Description

Creates an entire Environment with the following :

- Service Fabric 6.0 
- Windows Containers  ( uses service fabric for orchestration)
- Deploys Service FAbric Services from Source COntrol ( via a manifest )
- ELK Stack Container ( for complete integrated logging and monitoring)
- NGINX Container ( Reverse Proxy )
- Redis Container (Distirbuted cache and Pub/Sub)
- SQL Server 2017 Container

Makes use of install.ps1 scripts that are located in each git repository of the manifest. 

## Scripts 

### Parameters 

- by default a script with no parameters will assess the local environment, remove any current environment, and create a new one. 

- *-remove* - will simply remove and now recreate. 

## Powershell Scripts

- [ps\functions.ps1](ps\functions.ps1) - Utiliy/Capability functions used through out the scripts.

### Global Scripts 

- [.\install.ps1](.\install.ps1) - will execute all sub-system install.ps1's. 


### Sub-system folders
- [sys\install.ps1](sys\install.ps1) - Setups/Updates/Removes System dependencies,runtimes, and frameworks on the machine the script is executed on. 

- [container\install.ps1](container\install.ps1) - Setups/Updates/Removes Hyper-V, Docker, and Windows Container Features on the machine the script is executed on. 

- [cluster\install.ps1](cluster\install.ps1) - Setups/updates/removes  A Service Fabric Cluster on the machine the script is executed on.


## Activities

### Installing the Required SDK's

A few SDK's are required to use this tech stack. 
- Service Fabric SDK ( via Web Platform Installer)
- 

### Deploy a specific branch to your cluster

### Setup an Environment