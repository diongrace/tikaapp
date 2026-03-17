Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart' | ForEach-Object {
    $f = $_.FullName
    $content = [System.IO.File]::ReadAllText($f)
    $new = $content.Replace('FontAwesomeFontAwesomeIcons', 'FontAwesomeIcons').Replace('FaFaIcon(', 'FaIcon(')
    if ($new -ne $content) {
        [System.IO.File]::WriteAllText($f, $new)
        Write-Host "Fixed: $f"
    }
}
Write-Host "Done"
