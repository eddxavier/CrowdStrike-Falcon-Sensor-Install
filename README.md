# CrowdStrike-Falcon-Sensor-Install
Powershell script to retrieve sensor packages through API and install on Windows systems

Taking advantage of Sensor Download APIs by CrowdStrike, the script intends to illustrate that feature in a practical way.

# Overview:
The task verifies whether the sensor is installed by check the presence of CrowdStrike Falcon service, if not present, validates presence of an already created custom folder and downloaded package, otherwise creates a custom folder and downloads the sensor considering one version below the latest released (N-1), verifies the file integrity and, if valid, initiates installation.

Even though some functions are present on latest Powershell versions as native cmdlets, they are added to provide compatibility up to Powershell v2.0. 

Mechanims were added to prevent 

# Requirements:
- This script requires a minimum version 2.0 of PowerShell to run.
- API Keys with Sensor Download read permissions should be created at https://falcon.crowdstrike.com/support/api-clients-and-keys
- Customer ID information should be retrieved from https://falcon.crowdstrike.com/hosts/sensor-downloads
