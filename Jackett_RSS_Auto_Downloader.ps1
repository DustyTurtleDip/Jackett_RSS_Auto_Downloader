########################SET YOUR PARAMETERS###############################
$DownloadPath = "\\ServerNameOrIP\Folder\FileName.torrent"
$Indexer1 = "Your 1st Jackett RSS feed"
$Indexer2 = "Your 2nd Jackett RSS feed"
$Feeds = $Indexer1,$Indexer2 # ADD AS MANY INDEXERS YOU WANT BY ADDING ,$Indexer3,$Indexer4 ETC..
$CheckInterval = "60" #IN SECONDS - MINIMUM 5 SECONDS PER INDEXERS
$DownloadVolumeFactor = "0" # FREELEECH 0 | HALF 0.5 | FULL 1
########################SET YOUR PARAMETERS###############################



#PREPARE ERROR LOGGING
$ErrorLog = Join-Path -path "$env:ProgramData\Jackett_RSS\" -ChildPath "Error-$(Get-date -f 'yyyy-MM-dd-HH"h"mm').log";
Try
{
    if (Get-Module -ListAvailable -Name PSFramework -ErrorAction Stop)
    {
    Write-Host "Module exists"}else {install-module PSFramework -ErrorAction Stop
    }
}
catch
{
"ERROR installing PSFramework module : $_" | Add-Content $ErrorLog
}

Try
{
$OldErrorLogs = Get-ChildItem $env:ProgramData\Jackett_RSS\Error-*
foreach ($log in $OldErrorLogs.name) {Move-Item "$env:ProgramData\Jackett_RSS\$log" "$env:ProgramData\Jackett_RSS\OldLogs\$log"}
}
catch
{
"Failed deleting old error.log file : $_" | Add-Content $ErrorLog
}

#PREPARE VERBOSE LOGGING
Try
{
$VerboseLog = Join-Path -path "$env:ProgramData\Jackett_RSS\" -ChildPath "Verbose-$(Get-date -f 'yyyy-MM-dd-HH"h"mm').log";
Set-PSFLoggingProvider -Name logfile -FilePath $VerboseLog -Enabled $true -ErrorAction Stop;
}
catch
{
"ERROR Prepare Verbose Logging : $_" | Add-Content $ErrorLog
}
Try
{
Write-PSFMessage -Level Verbose -Message "Check interval is set to : $checkInterval seconds" -ErrorAction Stop
}
catch
{
"ERROR Prepare Verbose Logging : $_" | Add-Content $ErrorLog
}


#CREATE DIRECTORY IN PROGRAMDATA IF IT DOESN'T EXIST
Try
{
$WorkingDirectory = Test-Path $env:ProgramData\Jackett_RSS
Write-PSFMessage -Level Verbose -Message "%PROGRAMDATA%\Jackett_RSS EXIST: $WorkingDirectory"
    if ($WorkingDirectory -match "False")
    {
    New-Item -path $env:ProgramData -Name Jackett_RSS -ItemType directory
    }
    else
    {
    Write-PSFMessage -Level Verbose -Message "%programdata%\Jackett_RSS folder already exist"
    }
}
catch
{
"ERROR creating working directory in programdata : $_" | Add-Content $ErrorLog
}
Try
{
$WorkingDirectory = Test-Path $env:ProgramData\Jackett_RSS\OldLogs
Write-PSFMessage -Level Verbose -Message "%PROGRAMDATA%\Jackett_RSS\OldLogs EXIST: $WorkingDirectory"
    if ($WorkingDirectory -match "False")
    {
    New-Item -path $env:ProgramData\Jackett_RSS -Name OldLogs -ItemType directory
    }
    else
    {
    Write-PSFMessage -Level Verbose -Message "%programdata%\Jackett_RSS folder already exist"
    }
}
catch
{
"ERROR creating working directory in programdata : $_" | Add-Content $ErrorLog
}


# MOVING ALL OLD LOGS FILES
$logs = Get-ChildItem "$env:ProgramData\Jackett_RSS\*.log"
foreach ($log in $logs.name)
{
    Try
    { 
    Move-Item "$env:ProgramData\Jackett_RSS\$log" "$env:ProgramData\Jackett_RSS\OldLogs\$log" -force -ErrorAction Stop
    }
    catch
    {
    "ERROR creating working directory in programdata : $_" | Add-Content $ErrorLog
    }
}


#CLEAR VARIABLE BEFORE STARTING SCRIPT
$last = ""
$lastChecked = ""
$lastCheckedNoMatch = ""
$downloaded = ""
$LastAdded = ""
$movie = ""
$timer = ""
$CheckInterval = $CheckInterval/$Feeds.Count


#CLEAN THE SCRIPT PANEL
cls
Write-Host ""
Write-Host "If you encounter issue, please check the logs in" "$env:ProgramData\Jackett_RSS" -ForegroundColor Red
write-host "Version 1.1.0" -ForegroundColor Yellow
Write-Host ""

#START INFINITE LOOP
while ($true)
{

#WAIT XX SECONDS BEFORE CHECKING AGAIN
if ($timer -ge "2")
{
Try
{
Start-Sleep -Seconds $CheckInterval -ErrorAction Stop
}
catch
{
"ERROR : $_" | Add-Content $ErrorLog
}
}

foreach($JackettRSSFeed in $feeds)
{
    #RESET RESULT VARIABLES
    $Movie = ""
    #RETREIVE RSS FEED FROM JACKETT INSTANCE AND CREATE XML FROM IT
    Try
    {
    Invoke-WebRequest -Uri $JackettRSSFeed -OutFile $env:ProgramData\Jackett_RSS\jackett.xml -ErrorAction Stop
    }
    catch
    {
    "ERROR retreiving rss from jackett : $_" | Add-Content $ErrorLog
    }
    Try
    {
    [xml]$Content = (get-content $env:ProgramData\Jackett_RSS\jackett.xml -ErrorAction Stop)
    $Feed = $Content.rss.channel
    }
    catch
    {
    "ERROR retreiving rss from jackett : $_" | Add-Content $ErrorLog
    }
    #RETREIVE FIRST ITEM IN RSS AND TEST VALUE IS VALID
    #######
    Try
    {
    $test = $feed.item.GetValue(0)
    }
    catch
    {
    "ERROR retreiving first item : $_" | Add-Content $ErrorLog
    }
    if($test -eq $null)
    {
    write-host "Cannot find First Movie in RSS" -ErrorAction Stop
    }
    else
    {
    #######
#if ($lastChecked -ne $test.title)
#{
    foreach ($item in $feed.item.GetValue(0))
        {
        $lastChecked = $item.title
        #IF DOWNLOADVOLUMEFACTOR IS EQUAL TO XX

        ##############################################################
				    $Factor = "not correct"
				    $Movie = $item.guid
				    $index++
				    #GET THE DOWNLOADVOLUMEFACTOR
				    foreach ($attribute in $item.attr)
				    {
					    #Write-PSFMessage -Level Verbose -Message $attribute.value
					    if ($attribute.name -eq "downloadvolumefactor")
					    {
						    $Factor = $attribute.value
					    }
				    }
        ##############################################################

        if ($Factor -eq $DownloadVolumeFactor)
            {
            Try
            {
            if($downloaded -ne $true -or $null)
                {
                Write-PSFMessage -Level Verbose -Message $item.Title
                Write-PSFMessage -Level Verbose -Message "Is matching your parameter for DownloadVolumeFactor : $downloadvolumefactor"
                }
            $Movie = $item.guid
            }
            catch
            {
            "ERROR comparing DownloadVolumeFactor : $_" | Add-Content $ErrorLog
            }
                Try
                {
                $Size_GB = [math]::Round($item.size / 1GB, 3)
                $LastAdded = $item.title
                $WebClient = New-Object System.Net.WebClient -Verbose -ErrorAction Stop
                }
                catch
                {
                "ERROR downloading file : $_" | Add-Content $ErrorLog
                $downloaded = $false
                }
                Try
                {
                if($downloaded -ne $true -or $null)
                    {
                    $webClient.DownloadFile($item.link,"$DownloadPath")
                    #Invoke-WebRequest -Uri $item.link -OutFile $downloadPath
                    }
                if($downloaded -ne $true -or $null)
                    {
                    Write-PSFMessage -Level Verbose -Message "Adding it to $DownloadPath"
                    $downloaded = $true
                    }
                }
                catch
                {
                Write-Host $_
                $downloaded = $false
                "ERROR downloading file : $_" | Add-Content $ErrorLog
                Write-PSFMessage -Level Verbose -Message "FAILED - Adding it to $DownloadPath - WILL BE TRIED AGAIN"
                }
            }
            else
            {
            if($lastCheckedNoMatch -ne $item.title)
                {
                Write-PSFMessage -Level Verbose -Message $item.Title
                Write-PSFMessage -Level Verbose -Message "Does not match your parameter for DownloadVolumeFactor : $downloadvolumefactor"
                $lastCheckedNoMatch = $item.title
                $downloaded = ""
                }
            }
        }
        #}
#else
#{
cls
    if ($last -notcontains $lastAdded)
    {
    $last = ($last,"`n"," - ",$LastAdded,"`n")
    }
$lastChecked = $test.title
Write-Host ""
Write-Host "If you encounter issue, please check the logs in" "$env:ProgramData\Jackett_RSS" -ForegroundColor Red
write-host "Version 1.1.0" -ForegroundColor Yellow
Write-Host ""
write-host "ADDED : " -ForegroundColor Green "`n" $Last #= ""
write-host "JUST CHECKED : " -ForegroundColor Yellow "`n"                 ""- $item.title "`r`n    Published :"$item.pubDate "`r`n    Web page :"$item.guid "`r`n    Size :"$Size_GB "GB" "`r`n    Number of files :"$item.files "`r`n    Seeders :"$item.attr.value.GetValue(3) "`r`n    Leechers :"$item.attr.value.GetValue(4) "`r`n    VolumeFactor : $Factor "#= ""
#}
}

    ### LOGS ROTATION
    Try
    {
        if(test-path $VerboseLog) 
        {
        $filesize=((Get-Item $VerboseLog).length/1MB)
        }
        else
        {
        }
    }
    catch
    {
    "ERROR : $_" | Add-Content $ErrorLog
    }
    if($filesize -ge "1")
    {
        Try
        {
        $VerboseLog = Join-Path -path "$env:ProgramData\Jackett_RSS\" -ChildPath "Verbose-$(Get-date -f 'yyyy-MM-dd-HH"h"mm').log" -ErrorAction Stop;
        }
        catch
        {
        "ERROR : $_" | Add-Content $ErrorLog
        }
        Try
        {
        Set-PSFLoggingProvider -Name logfile -FilePath $VerboseLog -Enabled $true -ErrorAction Stop;
        }
        Catch
        {
        "ERROR : $_" | Add-Content $ErrorLog
        }
    }

    Try
    {
        if(test-path $ErrorLog) 
        {
        $filesize=((Get-Item $ErrorLog).length/1MB)
        }
        else
        {
        }
    }
    catch
    {
    "ERROR : $_" | Add-Content $ErrorLog
    }
    if($filesize -ge "1")
    {
    Try
    {
    $ErrorLog = Join-Path -path "$env:ProgramData\Jackett_RSS\" -ChildPath "Error-$(Get-date -f 'yyyy-MM-dd-HH"h"mm').log" -ErrorAction Stop;
    }
    catch
    {
    "ERROR : $_" | Add-Content $ErrorLog
    }
    }
Start-Sleep -Seconds $CheckInterval
}
$timer = [int]$timer + [int]1
}