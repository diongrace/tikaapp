$utf8 = [System.Text.UTF8Encoding]::new($false)
$files = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart'
$fixed = 0
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    # Replace Icon(FontAwesomeIcons -> FaIcon(FontAwesomeIcons (but not FaIcon already)
    $new = $content -creplace '(?<!Fa)Icon\(FontAwesomeIcons', 'FaIcon(FontAwesomeIcons'
    if ($new -ne $content) {
        [System.IO.File]::WriteAllText($file.FullName, $new, $utf8)
        Write-Host "Fixed: $($file.FullName)"
        $fixed++
    }
}
Write-Host "Done: $fixed files fixed"
