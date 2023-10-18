#scheduled task oneliner
schtasks /create  /tr "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/PortoNL/wingetupdater/main/winget-update.ps1'))" /tn "Winget Updater"   /SC ONLOGON
