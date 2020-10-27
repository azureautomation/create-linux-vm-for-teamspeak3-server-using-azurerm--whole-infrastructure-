Create Linux VM for TeamSpeak3 Server using AzureRM (Whole Infrastructure)
==========================================================================

            

Updated 08/13/2018


 


  *  Updated to Teamspeak Current Version, v3.3.0

  *  Added the file that accepts the free license into the correct directory

  *  Added new video tutorial on youtube, how to create a VM in Azure on less than 10 minutes. (Will be updated, shortly).

  *  Added try/catch in the Posh-ssh part. 

 

[https://youtu.be/1vBU7B2SCKQ](https://youtu.be/1vBU7B2SCKQ)


 


 






Updated 12/03/2017


 


The file has been updated. 


Bug Fixes:


 Now it won't fail if you have already a Storage Account with the same name.


 Failover of several things


 Added Try/Catch blocks.


 


For now, the only one bug is that you need to connect to it to get the initial key since the Posh-ssh is not able to get it.


 


 


What's new?


The script now will create the VM, and connect to it to download the latest version of Ts3, and uncompress it in the home folder of the user 'teamspeak', so the root is /home/teamspeak/teamspeak3-server_linux_amd64/


More Customization: You can change the variables at the top of the script and it won't break the script.


More colors in your console messages


 


 

 

![Image](https://github.com/azureautomation/create-linux-vm-for-teamspeak3-server-using-azurerm-(whole-infrastructure)/raw/master/screenshot_5.png)


 


 






 






 


This script will create a whole infrastructure to create a single server in windows azure with a static public IP. The idea of this script is to use a Linux server as TeamSpeak 3 server. 


 


*TeamSpeak 3 server offers 'the ideal tool for education, training, online gaming, internal business communication, and staying in touch with friends and family...'. 'It's capable of handling thousands of simultaneous users...'
 TeamSpeak's team.*


Basically, I have worked with windows server most of my time so I wanted to publish something different using Linux and exploring the gamer side.


***This script working can be seen on youtube in this link:

https://youtu.be/CVLODajWeic (Corrected URL).***


This is the Code:


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
