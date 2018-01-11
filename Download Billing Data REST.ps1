# Required for System.Web.HttpUtility
Add-Type -AssemblyName System.Web

#########################################
# Set these parameters 
#########################################
# You need to get there from your EA portal https://www.youtube.com/watch?v=u_phLs_udig 
$enrollmentNumber="<<REMOVED>> e.g. 0000000"
$enrollmentKey="<<REMOVED>> e.g. long string"
$month="<<REMOVED>> e.g. 2017-12"
$filename = [Environment]::GetFolderPath("Desktop") + "\BillingData-" + $month + ".csv"
$filenameByResourceGroup = [Environment]::GetFolderPath("Desktop") + "\BillingDataByResourceGroup-" + $month + ".csv"


# Encode any odd characters
$enrollmentNumberEncoded=[System.Web.HttpUtility]::UrlEncode($enrollmentNumber)
$enrollmentKeyEncoded=[System.Web.HttpUtility]::UrlEncode($enrollmentKey)
$monthEncoded=[System.Web.HttpUtility]::UrlEncode($month)


#########################################
# Call billing API
#########################################
# Specific the URL call
$Uri = "https://ea.azure.com/rest/" + $enrollmentNumberEncoded + "/usage-report?month=" + $monthEncoded + "&type=detail"
$HeaderValue = "bearer " + $enrollmentKeyEncoded

# Add headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-version", '1.0')
$headers.Add("authorization", $HeaderValue)

# Call to get the data
$response = Invoke-RestMethod $Uri -Method GET -Headers $headers 

# Remove any preceeding odd characters from the call.  AccountOwnerId is the first column in the file.
$position = $response.IndexOf("AccountOwnerId")
$response = $response.Substring($position-1)

# Write out the file (locally - or you can write to blob storage)
$response | Out-File $filename
Clear-variable -Name "response"


#########################################
# Compute cost by resource group
#########################################
# "AccountOwnerId","Account Name","ServiceAdministratorId","SubscriptionId","SubscriptionGuid","Subscription Name","Date","Month","Day","Year","Product","Meter ID","Meter Category","Meter Sub-Category","Meter Region","Meter Name","Consumed Quantity","ResourceRate","ExtendedCost","Resource Location","Consumed Service","Instance ID","ServiceInfo1","ServiceInfo2","AdditionalInfo","Tags","Store Service Identifier","Department Name","Cost Center","Unit Of Measure","Resource Group"
$billingObjects = Import-Csv $filename
$costByResourceGroup = @{}

foreach ($item in $billingObjects) {
    # Not all items have a resource group name (like bandwidth charges)
    if ($item.'Resource Group' -eq "")
    {
        $key = $item.SubscriptionGuid + "||" + $item.Product + ' (no resource group)'
    }
    else
    {
        $key = $item.SubscriptionGuid + "||" + $item.'Resource Group'
    }

    # Either update our value or insert a new item
    if ($costByResourceGroup.ContainsKey($key))
    {
        [double]$newCost = $item.ExtendedCost
        $newCost = $costByResourceGroup.Get_Item($key) + $newCost
        $costByResourceGroup.Set_Item($key, $newCost)
    }
    else
    {
        [double]$newCost = $item.ExtendedCost
        $costByResourceGroup.Add($key, $newCost)
    }
}
Clear-variable -Name "billingObjects"

#  Debug
#$costByResourceGroup | ft key,value | out-string -Width 160 | Out-File $filenameByResourceGroup


#########################################
# Write final CSV (Subscription, Resource Group and Amount)
#########################################
$costByResourceGroup.Keys | % {
    # Unparse hask key
    $string = $_
    $position = $string.IndexOf("||")
    $subscriptionId = $string.Substring(0,$position)
    $resourceGroup = $string.Substring($position+2)    
    $amount = $costByResourceGroup.$_

    New-Object -TypeName PSObject -Property @{
                SubscriptionId = $subscriptionId
                ResourceGroupName = $resourceGroup
                Amount = $amount                   
                } | Select-Object SubscriptionId, ResourceGroupName, Amount | Export-Csv -Path $filenameByResourceGroup -Append -Force -NoTypeInformation
}
Clear-variable -Name "costByResourceGroup"


#########################################
# TO DO (You customize from here on)
#########################################
# Load data (Subscription Id, Resource Group Name [not all items have a resource group], Amount)
$billingByResourceGroup = Import-Csv $filenameByResourceGroup

# You can now loop through your subscription or the $billingByResourceGroup collection
# If you have a monthly budget per resource group you can perform any test you would like.  
# Some customer put tags on their resource group (e.g. BusinessOwner=someone@somewhere.com and MonthlyBudget=10000)
# Then then test the current charges against the budget and send out email alerts if the budget is over

Clear-variable -Name "billingByResourceGroup"