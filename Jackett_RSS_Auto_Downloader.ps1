########################SET YOUR PARAMETERS###############################
$DownloadPath = "\\ServerNameOrIP\Folder\FileName.torrent"
$JackettRSSFeed = "Your Jackett RSS feed URL"
$CheckInterval = "60" #IN SECONDS
$DownloadVolumeFactor = "0" # FREELEECH 0 | HALF 0.5 | FULL 1
########################SET YOUR PARAMETERS###############################

#CREATE DIRECTORY IN PROGRAMDATA IF IT DOESN'T EXIST
$WorkingDirectory = Test-Path $env:ProgramData\Jackett_RSS
if ($WorkingDirectory -match "False") {New-Item -path $env:ProgramData -Name Jackett_RSS -ItemType directory}

#CLEAR VARIABLE BEFORE STARTING SCRIPT
$LastAdded = ""
$movie = ""

#CLEAN THE SCRIPT PANEL
cls

#START INFINITE LOOP
while ($true)
{
#WAIT XX SECONDS BEFORE CHECKING AGAIN
Start-Sleep -Seconds $CheckInterval
#RESET RESULT VARIABLES
$Movie = ""
#RETREIVE RSS FEED FROM JACKETT INSTANCE AND CREATE XML FROM IT
Invoke-WebRequest -Uri $JackettRSSFeed -OutFile $env:ProgramData\Jackett_RSS\jackett.xml
[xml]$Content = (get-content $env:ProgramData\Jackett_RSS\jackett.xml)
$Feed = $Content.rss.channel
#RETREIVE FIRST ITEM IN RSS
foreach ($item in $feed.item.GetValue(0))
    {
    #IF DOWNLOADVOLUMEFACTOR IS EQUAL TO XX
    if ($item.attr.value.GetValue(6) -eq $DownloadVolumeFactor)
        {
        $Movie = $item.title
        if ($LastAdded -contains $Movie)
            {
            #write-host "already added" $Movie
            }
            else
            {
            $AddTime = Get-Date
            Write-Host $AddTime" :" "Adding" $item.title "--- Seeders/Leechers :"$item.attr.value.GetValue(3)"/"$item.attr.value.GetValue(4)
            $LastAdded = $item.title
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($item.link,$DownloadPath)
            }
        }
    }
}