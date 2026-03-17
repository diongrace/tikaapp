# Find containers with BoxShape.circle that have FaIcon/Icon(FA) child but no alignment
$utf8 = [System.Text.UTF8Encoding]::new($false)
$files = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart'

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    if (-not $content.Contains('BoxShape.circle')) { continue }

    $lines = $content -split "`n"
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match 'BoxShape\.circle') {
            # Look ahead up to 5 lines for child: FaIcon/Icon(FontAwesome without alignment
            $window = ($lines[$i..([Math]::Min($i+8, $lines.Length-1))] -join "`n")
            $hasFA = $window -match 'child:\s*(const\s+)?(?:Fa)?Icon\('
            $hasAlignment = ($lines[[Math]::Max(0,$i-5)..$i] -join "`n") -match 'alignment:'
            if ($hasFA -and -not $hasAlignment) {
                Write-Host "$($file.Name):$($i+1) - MISSING alignment"
            }
        }
    }
}
Write-Host "Done"
