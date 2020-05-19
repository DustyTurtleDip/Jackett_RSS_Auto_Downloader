########################SET YOUR PARAMETERS###############################
$DownloadPath = "\\ServerNameOrIP\Folder\FileName.torrent"
$JackettRSSFeed = "Your Jackett RSS feed URL"
$CheckInterval = "60" #IN SECONDS
$DownloadVolumeFactor = "0" # FREELEECH 0 | HALF 0.5 | FULL 1
########################SET YOUR PARAMETERS###############################

#PREPARE LOGGING
if (Get-Module -ListAvailable -Name PSFramework) {
    Write-Host "Module exists"
} 
else 
{
try{install-module PSFramework}catch{"ERROR installing PSFramework : $_" | Add-Content $ErrorLog}
}
$ErrorLog = "$env:ProgramData\Jackett_RSS\errors.log"
$logFile = Join-Path -path "$env:ProgramData\Jackett_RSS\" -ChildPath "log-$(Get-date -f 'yyyy-MM-dd-HH-mm-ss').log";
Set-PSFLoggingProvider -Name logfile -FilePath $logFile -Enabled $true;
Write-PSFMessage -Level Verbose -Message "Check interval is set to : $checkInterval seconds"

#CREATE DIRECTORY IN PROGRAMDATA IF IT DOESN'T EXIST
$WorkingDirectory = Test-Path $env:ProgramData\Jackett_RSS
Write-PSFMessage -Level Verbose -Message "%PROGRAMDATA%\Jackett_RSS EXIST: $WorkingDirectory"
Try{if ($WorkingDirectory -match "False") {Write-PSFMessage -Level Verbose -Message New-Item -path $env:ProgramData -Name Jackett_RSS -ItemType directory} else {Write-PSFMessage -Level Verbose -Message "%programdata%\Jackett_RSS folder already exist"}}catch{{"ERROR creating folder : $_" | Add-Content $ErrorLog}}

#CLEAR VARIABLE BEFORE STARTING SCRIPT
$LastAdded = ""
$movie = ""

#CLEAN THE SCRIPT PANEL
cls

#START INFINITE LOOP
while ($true)
{
Try{
#RESET RESULT VARIABLES
$Movie = ""
#RETREIVE RSS FEED FROM JACKETT INSTANCE AND CREATE XML FROM IT
Invoke-WebRequest -Uri $JackettRSSFeed -OutFile $env:ProgramData\Jackett_RSS\jackett.xml
[xml]$Content = (get-content $env:ProgramData\Jackett_RSS\jackett.xml)
$Feed = $Content.rss.channel
#RETREIVE FIRST ITEM IN RSS
foreach ($item in $feed.item.GetValue(0))
    {
    Write-PSFMessage -Level Verbose -Message $item.Title
    Write-PSFMessage -Level Verbose -Message "Checking it"
    #IF DOWNLOADVOLUMEFACTOR IS EQUAL TO XX
    if ($item.attr.value.GetValue(6) -eq $DownloadVolumeFactor)
        {
        Write-PSFMessage -Level Verbose -Message $item.Title
        Write-PSFMessage -Level Verbose -Message "Match your parameter for DownloadVolumeFactor : $downloadvolumefactor"
        $Movie = $item.title
        if ($LastAdded -contains $Movie)
            {
            Write-PSFMessage -Level Verbose -Message $item.Title
            Write-PSFMessage -Level Verbose -Message "Was already added"
            }
            else
            {
            $AddTime = Get-Date
            Write-Host $AddTime" :" "Adding" $item.title "--- Seeders/Leechers :"$item.attr.value.GetValue(3)"/"$item.attr.value.GetValue(4)
            $LastAdded = $item.title
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($item.link,"$DownloadPath")
            Write-PSFMessage -Level Verbose -Message $item.Title
            Write-PSFMessage -Level Verbose -Message "Adding it to $DownloadPath"
            }
        }
        else
        {
        Write-PSFMessage -Level Verbose -Message $item.Title
        Write-PSFMessage -Level Verbose -Message "Does not match your parameter for DownloadVolumeFactor : $downloadvolumefactor"
        }
    }
#WAIT XX SECONDS BEFORE CHECKING AGAIN
Start-Sleep -Seconds $CheckInterval
}catch{"ERROR : $_" | Add-Content $ErrorLog}
}