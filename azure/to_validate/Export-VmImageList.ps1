#==================| Satnaam Waheguru Ji |===============================   
#              
#            Author  :  Aman Dhally    
#            E-Mail  :  amandhally@gmail.com    
#            website :  www.amandhally.net    
#            twitter :   @AmanDhally    
#            blog    : http://newdelhipowershellusergroup.blogspot.in/   
#            facebook: http://www.facebook.com/groups/254997707860848/    
#            Linkedin: http://www.linkedin.com/profile/view?id=23651495    
#            File version : 1
#    
#---------------------------------------------------------------------------
#creates files in windows temp folder (html and csv)
#C:\Users\nbxxxxx\AppData\Local\Temp\AzureList.csv


function Export-AzureVMImageList
{
[cmdletbinding()]
param(
[switch]$CSV

)
BEGIN{  
      try
      {
        Write-Output "Importing Azure PowerShell Module."
        Import-Module -Name 'Azure' -ErrorAction Stop
        Write-Output "Getting the list of all Azure VM Images."
        $aVmList = Get-AzureVMImage -ErrorAction Stop
      }
      catch
      {
        Write-Output  "Exception Occured : $_.Exception"
      }  
    }

PROCESS{

        if ( $CSV.IsPresent -eq $true )
        {
            Write-Output "Exporting to CSV"
            $body1= "
                    S.no,OS Name,OS Family, OS Image, Image Size in GB, Publish Date
                    "
            $i = 1
            $body1 += "`n"

           Write-Output "Processing the downloaded data."
           foreach ( $image in $aVmList  )
	                {
                  
                        $counter = $i++
                        $body1 +=  "$counter" + "," + $image.Label + "," + $image.OS + "," + $image.ImageName + "," + $image.LogicalSizeInGB + "," + $image.PublishedDate + "`n"
                  
                   }
        
            Write-Output "Exporting file to : $env:temp\AzureVmList.csv"
            $body1 > "$env:temp\AzureVmList.csv"
        
            Write-Output "Opening the Exported CSV file."
            Invoke-Expression "$env:temp\AzureVmList.csv"

            }
        else
        {
                $body1 = @()
                $i = 1

                Write-Output "Processing the downloaded data."
                foreach ( $image in $aVmList  )
	            {
      
                    $counter = $i++
                    $body1 += "<tr>"
                    $body1 += "<td >" + $counter + "</td>"
                    $body1 += "<td >" +"<font color=blue face=Consolas>" + $image.Label + "</font>" + "</td>"
                    $body1 += "<td >" + "<font color=black face=Consolas>" + $image.OS + "</font>" + "</td>"
                    $body1 += "<td >" + "<font color=black face=Consolas>" + $image.ImageName + "</font>" + "</td>"
                    $body1 += "<td >" + "<font color=black face=Consolas>" + $image.LogicalSizeInGB + "</font>" + "</td>"
                    $body1 += "<td >" + "<font color=black face=Consolas>" + $image.PublishedDate + "</font>" + "</td>"
                    $body1 += "</tr>"
            }

	                $body2 = "<h2>List of New Azure VM Images.</h2>"
	                $body2 += "<br>"
	                $body2 +="<h2> Page generated at $(get-date) on machine $env:computername .</h2>"
	                $body2 += "<table border=1px black dotted >"
	                $body2 += "<tr>"
	                $body2 +=  "<th> S.No.</th>"
	                $body2 +=  "<th> OS Name  </th>"
                    $body2 +=  "<th> Operating System</th>"
	                $body2 +=  "<th> Image Name </th>"	
                    $body2 +=  "<th> OS Size (gb) </th>"	
                    $body2 +=  "<th> Date of Publish</th>"	
	                $body2 += "</tr>"
	                $body2 += $body1
	                $body2 += "</table>"
	
	                Write-Output "Generating HTML file."
	                $body2  > "$env:TEMP\AzureList.html"
    
                    Write-Output "Opening the generated HTML file to : $env:TEMP\AzureList.html ."
	                Invoke-Expression "$env:TEMP\AzureList.html"
            }

     }
END{
    
    Write-Host "Script run finishes at : $(get-date)"

    }


}


Export-AzureVMImageList 