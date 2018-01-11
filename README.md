# Azure-EA-Billing-Data-for-Budget-Alerts
Uses PowerShell to download your EA billing data.  It then creates a CSV by Resource Group so you can then create billing alerts at this level.

## To use this script
Fill out your EA number, Billing API key and the month you want to download.  Two CSVs will be saved to your desktop (all items and a summary by resource group).

## Potential enhancements
* Save the CSV to blob storage (https://github.com/AdamPaternostro/Azure-Blob-Upload-Download) and then use PowerBI to create and share reports.
* Use Azure Automation to schedule the process
* Combine this with tagging (https://github.com/AdamPaternostro/Azure-Verify-Required-Tags) for building compliance/governance in your Azure subscription



