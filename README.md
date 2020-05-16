# Jackett_RSS_Auto_Downloader
Simple powershell script to automate downloading torrent files from jackett RSS feed based on DownloadVolumeFactor


Simply fill the following parameters at the begining of the script :

########################SET YOUR PARAMETERS###############################
$DownloadPath = "\\ServerNameOrIP\Folder\FileName.torrent"
$JackettRSSFeed = "Your Jackett RSS feed URL"
$CheckInterval = "60" #IN SECONDS
$DownloadVolumeFactor = "0" # FREELEECH 0 | HALF 0.5 | FULL 1
########################SET YOUR PARAMETERS###############################

## Screenshots

![screenshot](https://github.com/max01986/Jackett_RSS_Auto_Downloader/blob/master/2020-05-16_14h24_48.png?raw=true)
