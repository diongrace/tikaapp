$utf8 = [System.Text.UTF8Encoding]::new($false)
$files = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart'
$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    if (-not $content.Contains('BoxShape.circle')) { continue }
    $new = $content

    # Fix Icon(FontAwesomeIcons -> FaIcon(FontAwesomeIcons
    $new = [regex]::Replace($new, '(?<!Fa)Icon\((\s*FontAwesomeIcons)', 'FaIcon($1')

    # Add alignment: Alignment.center before child: FaIcon/Icon that follows BoxShape.circle closing
    # Matches: shape: BoxShape.circle,\n<spaces>),\n<spaces>child: [const ](Fa)?Icon(
    $new = [regex]::Replace($new,
        '(shape: BoxShape\.circle,\r?\n[ \t]+\),\r?\n)([ \t]+)(child: (?:const )?(?:Fa)?Icon\()',
        '$1$2alignment: Alignment.center,
$2$3')

    if ($new -ne $content) {
        [System.IO.File]::WriteAllText($file.FullName, $new, $utf8)
        Write-Host "Fixed: $($file.Name)"
        $fixed++
    }
}
Write-Host "Done: $fixed files fixed"
