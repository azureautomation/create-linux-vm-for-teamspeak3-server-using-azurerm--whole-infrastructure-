

########################
#####    Global Variables and variables
################################################

$TimeStart=Get-Date
$global:ScriptLocation = $(get-location).Path
$global:DefaultLog = "$global:ScriptLocation\Vm5Ts3.log"
#local variables 
$resourceGroup = "teamspeak"
$location = "South Central US"
$SSHUser="teamspeak"
$pwd=“Passw0rd”
$storageAccountName = "tsac"
$StorageAccountType= "Standard_LRS"
$FEsnName="TS3-SNet"
$vnetName= "TS3-VNet"
$nicName="FE-VmNIC"
$Allocation="Static"
$vmName ="TS3Ubuntu"

########################
#####    Functions
################################################
function ShowTimeMS{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True,position=0,mandatory=$true)]	[datetime]$timeStart,
        [parameter(ValueFromPipeline=$True,position=1,mandatory=$true)]	[datetime]$timeEnd
    )
    BEGIN {}
    PROCESS {
    write-Log -Level Info -Message  "Stamping time"
    
    $diff = New-TimeSpan $TimeStart $TimeEnd
    #Write-Verbose "Timediff= $diff"
    $miliseconds = $diff.TotalMilliseconds
    }
    END{
        Write-Log -Level Info -Message  "Total Time in miliseconds is: $miliseconds ms"
    }
}
function Write-Log{
        [CmdletBinding()]
        #[Alias('wl')]
        [OutputType([int])]
        Param
        (
            # The string to be written to the log.
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)] [ValidateNotNullOrEmpty()] [Alias("LogContent")] [string]$Message,
            # The path to the log file.
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,Position=1)] [Alias('LogPath')] [string]$Path=$DefaultLog,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,Position=2)] [ValidateSet("Error","Warn","Info","Load","Execute","Bright")] [string]$Level="Info",
            [Parameter(Mandatory=$false)] [switch]$NoClobber
        )

     Process{
        
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Warning "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist
        # to create the file include path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Now do the logging and additional output based on $Level
        switch ($Level) {
            'Error' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ERROR: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Warn' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") WARNING: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Info' {
                Write-Host $Message -ForegroundColor Cyan
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") INFO: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Load' {
                Write-Host $Message -ForegroundColor Magenta
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") LOAD: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Execute' {
                Write-Host $Message -ForegroundColor Green
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") EXEC: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Bright'{
                Write-Host $Message  -ForegroundColor Yellow -BackgroundColor DarkGreen
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") EXEC: `t $Message" | Out-File -FilePath $Path -Append
                }
            }
    }
}
function New-JCS-RG{ #new jcs resource group
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='What computer name would you like to target?')][ValidateLength(3,30)][string]$ReGr,
    [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Please get a valid location')][ValidateLength(3,20)][string]$location
  )
  BEGIN{
    $ts = new-object System.Diagnostics.stopwatch
    $ts.start()
    Write-Log -Level Execute  -Message "Creating Resource Group $ReGr in $location"
    
  }
  PROCESS{
    New-AzureRmResourceGroup -Name $ReGr -location $location
  }
  END{
    $ts.stop()
    $elapsed =$ts.elapsed
    write-Log -Level Info -Message "Ended after $elapsed"
  }
}
function New-JCS-SA{ #new jcs resource storage account
[CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the name of the Resource Group')][ValidateLength(3,30)][string]$ReGr,
        [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add a name for the Storage Account')][ValidateLength(3,30)][string]$Name,
        [Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Select a valid type')][ValidateLength(3,20)][string]$Type,
        [Parameter(Mandatory=$True,position=3,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Please get a valid location')][ValidateLength(3,20)][string]$Location
    )
  
    BEGIN{
		$ts = new-object System.Diagnostics.stopwatch
		$ts.start()
        $lower = $Name.ToLower()
    }
    PROCESS{
        Write-Log -Level Execute  -Message "Creating Storage Account: $lower`tType:$Type`tLocation:$Location"
        New-AzureRmStorageAccount -Name $lower -ResourceGroupName $ReGr -Type $Type -Location $location
    }
  END{
        $ts.stop()
        $elapsed =$ts.elapsed
		write-Log -Level Info -Message "Ended after $elapsed"
    }
}
function Print-Progress{
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the Progress number')][ValidateRange(0,100)][Int]$Progress,
    [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the add the id associated')][ValidateRange(0,100)][Int]$id,
    [Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the Name associated to the task')][String]$name

    #[Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the name of the Resource Group')][ValidateRange(0,100)][Int]$ProgressParent
    )
  BEGIN{}
  PROCESS{
    if($id -eq 1){
        if($Progress -lt 100){
            write-progress -id $id -activity "$name" -status "$Progress% Complete:" -percentcomplete $Progress
        }
        else{
            write-progress -id $id -activity "$name" -status 100 -percentcomplete 100 -Completed 
        }
    }
    else{
        if($Progress -lt 100){
            write-progress -id $id -ParentId 1 -activity "$name" -status "$Progress% Complete:" -percentcomplete $Progress
        }
        else{
            write-progress -id $id -ParentId 1 -activity "$name" -status 100 -percentcomplete 100 -Completed 
        }
    }
  }
  END{}
}
function Get-RandomLetters{
    [CmdletBinding()]
    #Source: https://blogs.technet.microsoft.com/heyscriptingguy/2015/11/05/generate-random-letters-with-powershell/
    param(
        [parameter(Mandatory=$true,Position=0)][ValidateRange(3,24)] [int]$length
    )
    BEGIN{
        [string]$str
    }
    process{
        $str= -join ((97..122)| Get-random -Count $length | %{ [char]$_})
    }
    END{
        return $str
    }
    

}


########################
#####    Loading/Installing AzureRM
################################################
Print-Progress -Progress 0 -id 1 -name "General Progress"

$AzureRMisTrue = (Get-Module -Name AzureRM -listAvailable).Count

Print-Progress -Progress 0 -id 2 -name "Loading/Installing AzureRM"
Write-Log -Level Execute  -Message "Loading/Installing AzureRM"
if($AzureRMisTrue -lt 1){
    Write-Log -Level Info -Message "Installing AzureRM"
	install-module azurerm -AllowClobber -Force
}
else{
    Write-Log -Level Info -Message "Loading AzureRM module"
    write-output "AzureRM Module is installed"
    import-module AzureRM
}

Print-Progress -Progress 100 -id 2 -name "Loading/Installing AzureRM" 
Print-Progress -Progress 10 -id 1 -name "General Progress"

Write-Log -Level Execute  -Message "Loggin Into AzureRM"
Print-Progress -Progress 0 -id 3 -name "Login into AzureRM"
Login-AzureRmAccount
#Get-AzureRmSubscription –SubscriptionName "Visual Studio Premium with MSDN" | Select-AzureRmSubscription

Print-Progress -Progress 100 -id 3 -name "Login into AzureRM"
Write-Log -Level Execute  -Message "Loggin Into AzureRM... Done"

Print-Progress -Progress 20 -id 1 -name "General Progress"

########################
#####    Create new ResourceGroup
################################################

Print-Progress -Progress 0 -id 4 -name "Creating Resource Group $resourceGroup"
New-JCS-RG -ReGr "$resourceGroup" -Location "$location"


Print-Progress -Progress 100 -id 4 -name "Creating Resource Group $resourceGroup"
Write-Log -Level Execute  -Message "Creating Resource Group $resourceGroup... Done"

Print-Progress -Progress 30 -id 1 -name "General Progress"
########################
#####    Create store account
################################################

Print-Progress -Progress 0 -id 5 -name "Creating Storage Account: $storageAccountName"
try{
    New-JCS-SA -ReGr $resourceGroup -Name $storageAccountName -Type $StorageAccountType -location $location -ea Stop
}
catch{
    Write-Log -Level Error -Message "There was an error while trying to set up the StorageAcountName $storageAccountName`nErrorMessage $_.Exception.Message"
     
    $RandomName= -join ((97..122)| get-random -Count 8 |  %{[char]$_})
    Write-Log -Level Warn -Message "The StorageACcountName has been automatically changed for $RandomName"
    $storageAccountName =$RandomName
    New-JCS-SA -ReGr $resourceGroup -Name $storageAccountName -Type $StorageAccountType -location $location
}

Print-Progress -Progress 100 -id 5 -name "Creating Storage Account: $storageAccountName"
Print-Progress -Progress 40 -id 1 -name "General Progress"

########################
#####    Virtual Network
################################################

########################  part 1 Subnet(s)
Write-Log -Level Execute -Message "Creating Virtual Network: $vnetName"
Print-Progress -Progress 0 -id 6 -name "Creating Virtual Network: $vnetName"

Write-Log -Level Info  -Message "Creating Subnet: $FEsnName"
$subnet1  = New-AzureRmVirtualNetworkSubnetConfig -Name $FEsnName -AddressPrefix 10.11.1.0/28
Write-Log -Level Info  -Message "Creating Subnet: $FEsnName... Done"

########################  part 2  Creating the new vnet
$vnet = New-AzureRmVirtualNetwork -Name "$vnetName" -ResourceGroupName $resourceGroup -Location $location -AddressPrefix 10.11.0.0/16 -Subnet $subnet1
Print-Progress -Progress 100 -id 6 -name "Creating Virtual Network: $vnetName"

Write-Log -Level Execute -Message "Creating Virtual Network: $vnetName... Done"


Print-Progress -Progress 55 -id 1 -name "General Progress"

########################
#####     NSG and rules FrontEnd
################################################
Write-Log -Level Execute -Message "Creating NSG and Rules"


######################## part 1 : Set Inbound Rules
Write-Log -Level Info -Message "Setting Inbound NSG and Rules"
$sshrule   =     New-AzureRmNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 150 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$ts3rule    =    New-AzureRmNetworkSecurityRuleConfig -Name ts3-rule -Description "Allow TS3 Traffic" -Access Allow -Protocol udp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 9987
$SQueryrule =    New-AzureRmNetworkSecurityRuleConfig -Name SrvQuery-rule -Description "Server Query Rule" -Access Allow -Protocol Tcp -Direction Inbound -Priority 250 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 10011
$FileTRule =     New-AzureRmNetworkSecurityRuleConfig -Name FileTransf-rule -Description "File Transfer Rule" -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 30033
$OutBoundInternet = New-AzureRmNetworkSecurityRuleConfig -Name Outbound-free -Description "Allow Internet" -Access Allow -Protocol * -Direction Outbound -Priority 100 -SourceAddressPrefix 10.11.0.0/16 -SourcePortRange * -DestinationAddressPrefix Internet -DestinationPortRange *

Write-Log -Level Info -Message "Setting Inbound NSG and Rules... Done"

######################## part 2 : Set the new Network Security Group and add the rules.
Write-Log -Level Info -Message "Adding the Rules to the Network Security Group"
$NSGName = "NSG-$vnetName" 
Print-Progress -Progress 0 -id 7 -name "Creating Network Security Group: $NSGName"
$nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $NSGName -SecurityRules $sshrule,$ts3rule,$SQueryrule,$FileTRule,$OutBoundInternet
Print-Progress -Progress 100 -id 7 -name "Creating Network Security Group: $NSGName"
Print-Progress -Progress 70 -id 1 -name "General Progress"
Write-Log -Level Info -Message "Adding the Rules to the Network Security Group... Done"

######################## part 3 : Set the NSG to the FrontEnd Virtual Network
Write-Log -Level Info -Message "Adding NSG to the virtual Network: $vnetName"
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $FEsnName -AddressPrefix 10.11.12.0/28 -NetworkSecurityGroup $nsg      
Write-Log -Level Info -Message "Adding NSG to the virtual Network: $vnetName... Done"
######################## part 4 : Save the information of the vnet 
Write-Log -Level Info -Message "Saving the information to the Virtual Network: $vnetName"
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
Write-Log -Level Info -Message "Saving the information to the Virtual Network: $vnetName... Done"

Write-Log -Level Execute -Message "Creating NSG and Rules...Done"


########################
#####    Network VMs devices
################################################
######################## part 1 Create Public IP
Write-Log -Level Execute -Message "Creating NICs for the Virtual Machine"


Print-Progress -Progress 0 -id 8 -name "Creating NICs for Linux VM: $nicName"
#public ip
Write-Log -Level Info -Message "Creating  Public NIC: $nicName"

[string]$DomainName = (Get-RandomLetters -length 3) + "-" + (Get-RandomLetters -length 3)
$DomainName = $DomainName.Replace(" ","")
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $resourceGroup -location $location -AllocationMethod $Allocation -DomainNameLabel $DomainName
$PublicIP= $pip.IpAddress

Write-log -Level Bright -Message "The Server will use the PublicIP $PublicIP"
Write-Log -Level Info -Message "Creating  Public NIC: $nicName... Done"

######################## part 2 Create Internal IP
Write-Log -Level Info -Message "Creating  Internal NIC: $nicName"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
Write-Log -Level Info -Message "Creating  Internal NIC: $nicName... Done"

######################## part 3 Creates the NIC
Print-Progress -Progress 100 -id 8 -name "Creating NICs for Linux VM: $nicName"
Print-Progress -Progress 80 -id 1 -name "General Progress"
Write-Log -Level Info -Message "Creating  new NICs... Done"

Write-Log -Level Execute -Message "Creating NICs for the Virtual Machine... Done"

########################
#Set Credentials for the VM
################################################
Write-Log -Level Execute -Message "Setting Credentials for the VM"

Print-Progress -Progress 0 -id 9 -name "Creating Credentials"

$localpwd=ConvertTo-SecureString $pwd -AsPlainText -Force
#before: $cred=Get-Credential -Message "Admin Credentials"
$SSHcred =New-Object System.Management.Automation.PSCredential ($SSHUser, $localpwd)
Print-Progress -Progress 100 -id 9 -name "Creating Credentials"
Print-Progress -Progress 90 -id 1 -name "General Progress"


Write-Log -Level Warn -Message "Username:$SSHUser  //    Pwd: $pwd"
Write-Log -Level Execute -Message "Setting Credentials for the VM... Done"
########################
#Create VM
################################################
Write-Log -Level Execute -Message "Creating the new VM"
Print-Progress -Progress 0 -id 10 -name "Creating VM"


######################## Part 1 Name and Size
Write-Log -Level Info -Message "Setting up new VM,  Name: $vmName - Size: Basic_A1"
$vm= New-AzureRmVMConfig -VMName $vmName -VMSize "Basic_A1"
Write-Log -Level Info -Message "Setting up new VM,  Name: $vmName - Size: Basic_A1... Done"


######################## Part 2 new OS 
Write-Log -Level Info -Message "Setting up new VM,  VMOffer from Canonical"
$ubuntuimages=Get-AzureRmVMImageOffer -Location $location -PublisherName 'Canonical'| where{$_.offer -eq "UbuntuServer"}
Write-Log -Level Info -Message "$ubuntuimages"
Write-Log -Level Info -Message "Setting up new VM,  VMOffer from Canonical... Done"

Write-Log -Level Info -Message "Setting up new VM,  Setting credentials into the VM"
$vm= Set-AzureRmVMOperatingSystem -Vm $vm -Linux -ComputerName $vmName -Credential $SSHcred
Write-Log -Level Info -Message "Setting up new VM,  Setting credentials into the VM... Done"


#Create new Source Image:
#check all the publishers available

Write-Log -Level Info -Message "Setting up new VM,  Setting lastest Image"
$Latest = Get-AzureRmVMImage -Location $location  -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "16.04.0-LTS" | select -Last 1
$latestUs= $latest.offer  + "  version: " + $Latest.Version

$vm= Set-AzureRmVMSourceImage -VM $vm -PublisherName $Latest.PublisherName -Offer $Latest.Offer -Skus $Latest.Skus -Version $Latest.Version
Write-Log -Level Info -Message "Setting up new VM,  Setting lastest Image. $latestUs... Done"



#configure source VM disk, Create the VM
Write-Log -Level Info -Message "Setting up new VM,  Adding Nics into the VMs"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
Write-Log -Level Info -Message "Setting up new VM,  Adding Nics into the VMs... Done"


Print-Progress -Progress 94 -id 1 -name "General Progress"

##Create Disk
#Get reference of the account we created before

#Create a full uri where the vhd will be located
Write-Log -Level Info -Message "Setting up new VM,  Creating Disk"
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName 
$diskName="OS-Ldisk"
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage


Write-Log -Level Info -Message "Setting up new VM,  Creating Disk... Done"
#Create the VM
Print-Progress -Progress 5 -id 10 -name "Creating VM"
Write-Log -Level Execute -Message "Creating VM, this operation can take a while (from 2 to 10 minutes)."
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm
Print-Progress -Progress 100 -id 10 -name "Creating VM"


Print-Progress -Progress 100 -id 1 -name "General Progress"

$TimeEnd=Get-Date
Write-Log -Level Execute -Message "Creating the new VM... Done"

ShowTimeMS $TimeStart $TimeEnd
#wget http://dl.4players.de/ts/releases/3.3.0/teamspeak3-server_linux_amd64-3.3.0.tar.bz2
#tar xvf teamspeak3-server_linux_amd64-3.0.12.4.tar.bz2
# cd teamspeak3-server_linux_amd64/
#./ts3server_startscript.sh start

#region Run SSH
$exist = (Get-Module -name "Posh-SSH" -ListAvailable).Count
if($exist -lt 1 ){
    Install-module -name Posh-ssh -confirm:$false
}
else{
    Write-Host "The SSH module is already installed 'Posh-SSH'"
}

try{
$FQDN= (Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup).DnsSettings.Fqdn

$sshsession = New-SSHSession -ComputerName $FQDN -Credential $SSHcred -Force
Write-Log -Level Execute -Message "Updating system 'apt-get update'"
Invoke-SSHCommand -Command {sudo apt-get update} -SSHSession $sshsession | select -ExpandProperty output
Write-Log -Level Execute -Message "Downloading Teamspeak3 on /home/teamspeak/"
Invoke-SSHCommand -Command {sudo wget http://dl.4players.de/ts/releases/3.3.0/teamspeak3-server_linux_amd64-3.3.0.tar.bz2} -SSHSession $sshsession | select -ExpandProperty output

start-sleep -Seconds 20 
Write-Log -Level Execute -Message "Uncompresing the file"
Invoke-SSHCommand -Command {sudo cd /home/teamspeak } -SSHSession $sshsession | select -ExpandProperty output
Invoke-SSHCommand -Command {sudo tar xvf teamspeak3-server_linux_amd64-3.3.0.tar.bz2} -SSHSession $sshsession | select -ExpandProperty output
Invoke-SSHCommand -Command {sudo sudo chmod 777 /home/teamspeak/teamspeak3-server_linux_amd64/logs/} -SSHSession $sshsession | select -ExpandProperty output
Invoke-SSHCommand -Command {sudo sudo echo ""license_accepted=1"" >> /home/teamspeak/teamspeak3-server_linux_amd64/.ts3server_license_accepted} -SSHSession $sshsession | select -ExpandProperty output


Write-Host -ForegroundColor Cyan -BackgroundColor Black "Public IP:$PublicIP  &nUser:$SSHUser´tPassword:$pwd"
Write-Log -Level Bright -Message "Now just login using Putty or any other SSH client. navegate to teamspeak3-server_linux_amd64 folder and run ./ts3server_startscript.sh start, get the password to connect the 1st time and enjoy"
}

catch{
    Write-Log -Level Bright -Message "$($_.Exception.Message)"
    $FQDN= (Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup).DnsSettings.Fqdn
    $sshsession = New-SSHSession -ComputerName $FQDN -Credential $SSHcred -Force
    Write-Log -Level Execute -Message "Updating system 'apt-get update'"
    Invoke-SSHCommand -Command {sudo apt-get update} -SSHSession $sshsession | select -ExpandProperty output
    Write-Log -Level Execute -Message "Downloading Teamspeak3 on /home/teamspeak/"
    Invoke-SSHCommand -Command {sudo wget http://dl.4players.de/ts/releases/3.3.0/teamspeak3-server_linux_amd64-3.3.0.tar.bz2} -SSHSession $sshsession | select -ExpandProperty output
    
    start-sleep -Seconds 15 
    Write-Log -Level Execute -Message "Uncompresing the file"
    Invoke-SSHCommand -Command {sudo cd /home/teamspeak } -SSHSession $sshsession | select -ExpandProperty output
    Invoke-SSHCommand -Command {sudo tar xvf teamspeak3-server_linux_amd64-3.3.0.tar.bz2} -SSHSession $sshsession | select -ExpandProperty output
    Invoke-SSHCommand -Command {sudo sudo chmod 777 /home/teamspeak/teamspeak3-server_linux_amd64/logs/} -SSHSession $sshsession | select -ExpandProperty output
    Invoke-SSHCommand -Command {sudo sudo echo ""license_accepted=1"" >> /home/teamspeak/teamspeak3-server_linux_amd64/.ts3server_license_accepted} -SSHSession $sshsession | select -ExpandProperty output
    
    Write-Host -ForegroundColor Cyan -BackgroundColor Black "Public IP: $PublicIP User:$SSHUser Password:$pwd"
    Write-Log -Level Bright -Message "Now just login using Putty or any other SSH client. navegate to teamspeak3-server_linux_amd64 folder and run ./ts3server_startscript.sh start, get the password to connect the 1st time and enjoy"
}
<#
#This command is not able to be done using Http-Post because the password is not captured to provide it to the user.
#Invoke-SSHCommand -Command {} -SSHSession $sshsession | select -ExpandProperty output
#$ret = $(Invoke-SSHCommand -SSHSession $sshsession -Command "sudo ./teamspeak3-server_linux_amd64/ts3server_startscript.sh start").Output
#$ret = $(Invoke-SSHCommand -SSHSession $sshsession -Command "sudo ./teamspeak3-server_linux_amd64/ts3server_minimal_runscript.sh createinifile=1").Output
#>