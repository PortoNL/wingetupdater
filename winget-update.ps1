<#PSScriptInfo
 
.VERSION 0.0.4
 
.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463
 
.AUTHOR asherto, 1ckov
 
.COMPANYNAME asheroto
 
.TAGS PowerShell Windows winget win get install installer fix script
 
.PROJECTURI https://github.com/asheroto/winget-installer
 
.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Implemented function to get the latest version of Winget and its license.
[Version 0.0.3] - Signed file for PSGallery.
[Version 0.0.4] - Changed URI to grab latest release instead of releases and preleases.
 
#>

<#
.SYNOPSIS
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.DESCRIPTION
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.EXAMPLE
    winget-install
.NOTES
    Version : 0.0.4
    Created by : asheroto
.LINK
    Project Site: https://github.com/asheroto/winget-installer
#>


function getNewestLink($match) {
    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    Write-Verbose "[$((Get-Date).TimeofDay)] Getting information from $uri"
    $get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
    Write-Verbose "[$((Get-Date).TimeofDay)] getting latest release"
    $data = $get[0].assets | Where-Object name -Match $match
    return $data.browser_download_url
}

$wingetUrl = getNewestLink("msixbundle")
$wingetLicenseUrl = getNewestLink("License1.xml")

function section($text) {
    <#
        .SYNOPSIS
        Prints a section divider for easy reading of the output.
 
        .DESCRIPTION
        Prints a section divider for easy reading of the output.
    #>
    Write-Output "###################################"
    Write-Output "# $text"
    Write-Output "###################################"
}

# Add AppxPackage and silently continue on error
function AAP($pkg) {
    <#
        .SYNOPSIS
        Adds an AppxPackage to the system.
 
        .DESCRIPTION
        Adds an AppxPackage to the system.
    #>
    Add-AppxPackage $pkg -ErrorAction SilentlyContinue
}

# Download XAML nupkg and extract appx file
section("Downloading Xaml nupkg file... (19000000ish bytes)")
$url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.1"
$nupkgFolder = "Microsoft.UI.Xaml.2.7.1.nupkg"
$zipFile = "Microsoft.UI.Xaml.2.7.1.nupkg.zip"
Invoke-WebRequest -Uri $url -OutFile $zipFile
section("Extracting appx file from nupkg file...")
Expand-Archive $zipFile

# Determine architecture
if ([Environment]::Is64BitOperatingSystem) {
    section("64-bit OS detected")

    # Install x64 VCLibs
    section("Downloading & installing x64 VCLibs... (21000000ish bytes)")
    AAP("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx")

    # Install x64 XAML
    section("Installing x64 XAML...")
    AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx")
} else {
    section("32-bit OS detected")

    # Install x86 VCLibs
    section("Downloading & installing x86 VCLibs... (21000000ish bytes)")
    AAP("https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx")

    # Install x86 XAML
    section("Installing x86 XAML...")
    AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x86\Release\Microsoft.UI.Xaml.2.7.appx")
}

# Finally, install winget
section("Downloading winget... (21000000ish bytes)")
$wingetPath = "winget.msixbundle"
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath
$wingetLicensePath = "license1.xml"
Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath
section("Installing winget...")
Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction SilentlyContinue

# Adding WindowsApps directory to PATH variable for current user
section("Adding WindowsApps directory to PATH variable for current user...")
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$path = $path + ";" + [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
[Environment]::SetEnvironmentVariable("PATH", $path, "User")

# Cleanup
section("Cleaning up...")
Remove-Item $zipFile
Remove-Item $nupkgFolder -Recurse
Remove-Item $wingetPath
Remove-Item $wingetLicensePath

# Finished
section("Installation complete!")
section("Please restart your computer to complete the installation.")
# SIG # Begin signature block
# MIIp9QYJKoZIhvcNAQcCoIIp5jCCKeICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDupndgv7NgC5Kn
# 3urzTCh+pSpPmQ1xh5kEpWX5VcgTJKCCDrkwggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wgggBMIIF6aADAgECAhAOyLAmjUpdRlQheQrwADJFMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjIwNDAxMDAwMDAwWhcNMjMwNDAx
# MjM1OTU5WjCB0zETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhPa2xhaG9tYTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEzARBgNV
# BAUTCjE5MTMwMjk2MDExCzAJBgNVBAYTAlVTMREwDwYDVQQIEwhPa2xhaG9tYTER
# MA8GA1UEBxMITXVza29nZWUxHDAaBgNVBAoTE0FzaGVyIFNvbHV0aW9ucyBJbmMx
# HDAaBgNVBAMTE0FzaGVyIFNvbHV0aW9ucyBJbmMwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCwsC6ZPJjALlD34NKQyBQp7LMwO61CnMijdMX5VdjqfbII
# 3bTcVIxd9c2VXA4CNHOySle9mwrUKg0/fuSMCL6v+YT+nlykdiGF+1JzF/xztPxi
# UYh/nosuzuJli1cKSqLklo1aJBSbaraI2d2uuEhuZs1bdtNEiDAqB9uzLM1sjdA9
# xMcGqa0a0fWHkiMTgcoTOXttegnjRaOfLjoOHMG885zCbivqvUi1PDw/denxiY8J
# USIlXrfRXG63+HOzp4CyX4BTOdhhljj9KB5WVo8671gBdFFjxG9sjlDpBqT11etn
# ZUS3WUNOx3RnAmUQeriDSlChZuDr4oGS5C2Czwv5tKp/lWsbmBzIlBek0IuxKv+B
# Ve5dIM8lx5o8FV+mHyt9OWPqh1G4I03vS4KQTKs79ck7msPUcWICBb9WUKSFiKbL
# 991jbjY8cviKvI7keQiY+kOP3kH83H8vNSe6cFoFEBFDlq3giO1BYV/36bSsM9xx
# ZgBXQqfMqjqX/HsCRMSRb6aS/GaETq0s9/5ExMJEoLPTN/xi4h+ErLTooX6DgY2Y
# 4Lg5zWeSX3rC9b2/h5SifXxhKDxL8B4V6Pba0mOhc36TcTmPIbz0rBn097i8kuCG
# h11jpqCgfi2jtyyEbsOvEcpnQAwb/SiWbznD0IpNwsnYk5t1hBYx4TTxU8FrNQID
# AQABo4ICODCCAjQwHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYD
# VR0OBBYEFNK8fnBc0Eyw1svglEaxakfmNIEzMDEGA1UdEQQqMCigJgYIKwYBBQUH
# CAOgGjAYDBZVUy1PS0xBSE9NQS0xOTEzMDI5NjAxMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JT
# QTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0
# MjAyMUNBMS5jcmwwPQYDVR0gBDYwNDAyBgVngQwBAzApMCcGCCsGAQUFBwIBFhto
# dHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgZQGCCsGAQUFBwEBBIGHMIGEMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKG
# UGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENv
# ZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3J0MAwGA1UdEwEB/wQCMAAw
# DQYJKoZIhvcNAQELBQADggIBABH5uRf88l9+NJ1427Htk3pDHtE1xpJjWI2GNx6H
# ML7PkUqt8VTYOBZcyN/GpQKbp4aA+YNvRK4r/YN3LelR5j+OItSiNcY9f/x0ODfZ
# 90pBvuo+1HCBaZAHhnuiMQFH80ej/vtQ6YtAhphOGjKWEeStCtFp5WD5NNZICBYF
# /omOktMibMWpbR+ya5bT1l/VmnBrMawljkZqy4aKWT4quKb5p1mHcVD2SJxqEKrt
# Ql8iHFR0j96vNnuhWRpYGs38AAx3vWrX/6sGTLXdyrjsHVVYOcRD/DuH2kGXFzmL
# T7/1RGEZJDIQkWDgDJEmjIC98O9uO+gFTwkqkyen3gHj7DzMMtHTnkVe8Efu7Vtf
# qE4EkcPk3eXIL/tEmtr3sXqBKLoNm+c1OUn9PdzZwNFqBgPHZvLKfBtOI1Q/2C88
# fTOEFofJIC2s95MAGMgzHbJOPSWhNRDNkIJbFaGeCxlddb7DoWtKoCZhFtEKtrSF
# h7kzXSvqQqJTsE8z9pB/pRyDNzSYMqDHifZy6rkMkqd7Nv3btUzlyzFxrok3+CDs
# XfwXbO2PJe6HUL2Cvq5lw+1/dsedOoNbdvmX0e84W8tFbJJPs3as1u6OdtRs7tmB
# A/VJxtkZp5vMH4Erdw3ZagCHUGRMX+a5rNzMElHFSkoR5cOt7sKXBzyKx/tI0XgV
# sCHhMYIakjCCGo4CAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNl
# cnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWdu
# aW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExAhAOyLAmjUpdRlQheQrwADJFMA0G
# CWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIOXuyjmCRRHLDn90SMJjk2BDuR1OdMAFnfFmcXyrVLvoMA0GCSqG
# SIb3DQEBAQUABIICAABwgUM4RyD+O1qOT/1ycKurS+HKa6lGAAWNa2CqJ7eiz/vO
# mS14hQaeuE1qqbK/GX10wBfDcDK+R3IPNGd5PK0mY50bMyY1KhxA28gO/oxrgb5F
# U5HaWlyj7zgQnraRKvV6nPwbdeSaLiROygwClC7sDN45kq1vwEQW8bbktjAQPrRw
# AJrvhihpPSZZpUppYr43XfI5K94MB2WZkoqxLB+t7cz+M5srem7QreXKXYTFasH2
# PXiTtBJPVGNvKoNOQ+BL/PP0TGuy1nfdvWaRBnmk81Ndj4M0wN8+3lZeLSaUd3Lm
# gj6YW89yANKFymI17ZqMcb54y+KpYX1QGFhDui8osne/Gi3jEwzDTGiPa2arG5qm
# /mlPv3QwyzVi0kbtFH4BZcnW6+MMFIUnlirGlhE5iKurs1HTy4AQG3IWpD7YCr3B
# l9SFPV6YQ8g2V4wWv94NvZqXJoZf6eC9Dte8Hon8qam4ynNSjTT8rJu7UFGhSr8W
# 9F387AS7bUcrY2+IyzC9a9+pZkMYqek9mj5xYTGQ+Gmlzor4xbtZWt1zF1M6zSkj
# TLt51DvfPUABDjxYTlLY/M7XmNMESwi2GzDU1w8Cc4/nzaMZSDdfyaTtTx47clqw
# oR50NkaaW6HHb34YnCsdkZT9Aw5xqt6xuw2oP58I1aDP6G5UF+EbLclr6seBoYIX
# aDCCF2QGCisGAQQBgjcDAwExghdUMIIXUAYJKoZIhvcNAQcCoIIXQTCCFz0CAQMx
# DzANBglghkgBZQMEAgEFADB4BgsqhkiG9w0BCRABBKBpBGcwZQIBAQYJYIZIAYb9
# bAcBMDEwDQYJYIZIAWUDBAIBBQAEIGXVcZ8q6207rYZIlXQh+Uz3bsU7uWXVj5+h
# dUa54z5gAhEAjW56Q4oPypZqHn+spYPAnRgPMjAyMjA3MDIyMTA5MjhaoIITMTCC
# BsYwggSuoAMCAQICEAp6SoieyZlCkAZjOE2Gl50wDQYJKoZIhvcNAQELBQAwYzEL
# MAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJE
# aWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBD
# QTAeFw0yMjAzMjkwMDAwMDBaFw0zMzAzMTQyMzU5NTlaMEwxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEkMCIGA1UEAxMbRGlnaUNlcnQgVGlt
# ZXN0YW1wIDIwMjIgLSAyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# uSqWI6ZcvF/WSfAVghj0M+7MXGzj4CUu0jHkPECu+6vE43hdflw26vUljUOjges4
# Y/k8iGnePNIwUQ0xB7pGbumjS0joiUF/DbLW+YTxmD4LvwqEEnFsoWImAdPOw2z9
# rDt+3Cocqb0wxhbY2rzrsvGD0Z/NCcW5QWpFQiNBWvhg02UsPn5evZan8Pyx9PQo
# z0J5HzvHkwdoaOVENFJfD1De1FksRHTAMkcZW+KYLo/Qyj//xmfPPJOVToTpdhiY
# mREUxSsMoDPbTSSF6IKU4S8D7n+FAsmG4dUYFLcERfPgOL2ivXpxmOwV5/0u7NKb
# AIqsHY07gGj+0FmYJs7g7a5/KC7CnuALS8gI0TK7g/ojPNn/0oy790Mj3+fDWgVi
# fnAs5SuyPWPqyK6BIGtDich+X7Aa3Rm9n3RBCq+5jgnTdKEvsFR2wZBPlOyGYf/b
# ES+SAzDOMLeLD11Es0MdI1DNkdcvnfv8zbHBp8QOxO9APhk6AtQxqWmgSfl14Zvo
# aORqDI/r5LEhe4ZnWH5/H+gr5BSyFtaBocraMJBr7m91wLA2JrIIO/+9vn9sExjf
# xm2keUmti39hhwVo99Rw40KV6J67m0uy4rZBPeevpxooya1hsKBBGBlO7UebYZXt
# PgthWuo+epiSUc0/yUTngIspQnL3ebLdhOon7v59emsCAwEAAaOCAYswggGHMA4G
# A1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAW
# gBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUjWS3iSH+VlhEhGGn6m8c
# No/drw0wWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNy
# bDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAgEADS0jdKbR9fjqS5k/AeT2DOSvFp3Zs4yX
# gimcQ28BLas4tXARv4QZiz9d5YZPvpM63io5WjlO2IRZpbwbmKrobO/RSGkZOFvP
# iTkdcHDZTt8jImzV3/ZZy6HC6kx2yqHcoSuWuJtVqRprfdH1AglPgtalc4jEmIDf
# 7kmVt7PMxafuDuHvHjiKn+8RyTFKWLbfOHzL+lz35FO/bgp8ftfemNUpZYkPopzA
# ZfQBImXH6l50pls1klB89Bemh2RPPkaJFmMga8vye9A140pwSKm25x1gvQQiFSVw
# BnKpRDtpRxHT7unHoD5PELkwNuTzqmkJqIt+ZKJllBH7bjLx9bs4rc3AkxHVMnhK
# SzcqTPNc3LaFwLtwMFV41pj+VG1/calIGnjdRncuG3rAM4r4SiiMEqhzzy350yPy
# nhngDZQooOvbGlGglYKOKGukzp123qlzqkhqWUOuX+r4DwZCnd8GaJb+KqB0W2Nm
# 3mssuHiqTXBt8CzxBxV+NbTmtQyimaXXFWs1DoXW4CzM4AwkuHxSCx6ZfO/IyMWM
# WGmvqz3hz8x9Fa4Uv4px38qXsdhH6hyF4EVOEhwUKVjMb9N/y77BDkpvIJyu2XMy
# WQjnLZKhGhH+MpimXSuX4IvTnMxttQ2uR2M4RxdbbxPaahBuH0m3RFu0CAqHWlkE
# dhGhp3cCExwwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3
# DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0
# ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGln
# aUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0Ew
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE
# 8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBML
# JnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU
# 5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLy
# dkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFk
# dECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgm
# f6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9a
# bJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwY
# SH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80Vg
# vCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5
# FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9
# Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0
# hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcN
# AQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp
# +3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9
# qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8
# ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6Z
# JxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnE
# tp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fx
# ZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV7
# 7QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT
# 1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkP
# Cr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvm
# fxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFsTCC
# BJmgAwIBAgIQASQK+x44C4oW8UtxnfTTwDANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwNjA5MDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBXjCCAVowDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHkGCCsGAQUF
# BwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMG
# CCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwIAYDVR0g
# BBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBDAUAA4IBAQCa
# FgKlAe+B+w20WLJ4ragjGdlzN9pgnlHXy/gvQLmjH3xATjM+kDzniQF1hehiex1W
# 4HG63l7GN7x5XGIATfhJelFNBjLzxdIAKicg6okuFTngLD74dXwsgkFhNQ8j0O01
# ldKIlSlDy+CmWBB8U46fRckgNxTA7Rm6fnc50lSWx6YR3zQz9nVSQkscnY2W1ZVs
# RxIUJF8mQfoaRr3esOWRRwOsGAjLy9tmiX8rnGW/vjdOvi3znUrDzMxHXsiVla3R
# y7sqBiD5P3LqNutFcpJ6KXsUAzz7TdZIcXoQEYoIdM1sGwRc0oqVA3ZRUFPWLvdK
# RsOuECxxTLCHtic3RGBEMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQg
# RzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAKekqInsmZQpAGYzhN
# hpedMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAcBgkqhkiG9w0BCQUxDxcNMjIwNzAyMjEwOTI4WjArBgsqhkiG9w0BCRACDDEc
# MBowGDAWBBSFCPOGUVyz0wd9trS3wH8bSl5B3jAvBgkqhkiG9w0BCQQxIgQgM8Mw
# 4ZsSsaGWy1vTGWNSO+VMpUe3rfgiEyl3HVbb30AwNwYLKoZIhvcNAQkQAi8xKDAm
# MCQwIgQgnaaQFcNJxsGJeEW6NYKtcMiPpCk722q+nCvSU5J55jswDQYJKoZIhvcN
# AQEBBQAEggIAskrLe1acQbHvvR2SRk89cE86QUFoyhVriApV6e2KnpYKFGvYPC6u
# 96NCIJlY6UStZLY8MYFhe++auPsmkGNFcZJoCl6k86IOvIixyc9cMy/1z0WVppLy
# 6sXBrILsZC6tVwHKmAxnMLE04h7qwtcBAJ773kK0szN27ZRuNOZrQtecrU/tNvE9
# 2UH7R1fI3RVg5w9EKFP1yqLFqHkSNfXM9ryKFtTkXGVOj7PXjuslgLPg2SW0ZBOL
# FLq6hz2zPN0eNdkgpl2Acl3eT5zwqh9zVTHTdjNRh8zaPGijkdd70V/5sK6aKvgP
# JiP/tyQOgEAfBqD1bvTD1sFSQYc0/CXSPdfZL6PajslqgKWWcATvgYzSUp1mPfMu
# ucKU1JlvDeVj48W3XHfxsWTmYBKcBGtQgvrsRzCCpmmKvqTWX2+fTPDxoqWq8qjq
# 6a2cFWfHxeJlJlVmFC9PPzHpGQcAac4yT9LQRE4RH/UzEhZ/fXXwbU/s+vjwlmYH
# a+qkOd7I+UlQQjSIKCcBfCwCtkbCiNxLVEgA8JzcIbqVG5iGTF5zMiD4qFKmsY4M
# fvjcqD7QZC+cAlJMJ5Kas+qqhCZFb6EIjlrpQgHXuJEQK3CJivz50ClxDUmk/Te4
# pMWyD7l55VI//OpbmChDACuAlJNDnrA1pOruqKvyysW8t6NbXcjCYTA=
# SIG # End signature block
