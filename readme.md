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

Makes use of build.ps1 scripts that are located in each git repository of the manifest. 


## Setup your development machine

Run  .\env\install.ps1   

## Setup a local cluster 
Run .\setup.ps1 

## Deploy a specific branch to your cluster 
