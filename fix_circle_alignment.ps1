$utf8 = [System.Text.UTF8Encoding]::new($false)
$files = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart'
$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    $new = $content

    # Fix: Container with shape: BoxShape.circle, no alignment, child is FaIcon or Icon(FontAwesomeIcons
    # Pattern: "shape: BoxShape.circle,\n            ),\n            child: [const ]FaIcon("
    # Add alignment before child

    # Pattern 1: ),\n              child: FaIcon( (14 spaces)
    $new = [regex]::Replace($new,
        '(shape: BoxShape\.circle,\r?\n(\s+)\),\r?\n\s+)(?!alignment)(child: (?:const )?(?:Fa)?Icon\((?:\r?\n\s+)?FontAwesomeIcons)',
        '$1alignment: Alignment.center,
$2child: FaIcon(
$2  FontAwesomeIcons')

    # Fix Icon( -> FaIcon( in these contexts (if not already FaIcon)
    $new = [regex]::Replace($new, '(?<!Fa)Icon\(\s*(FontAwesomeIcons)', 'FaIcon($1')

    if ($new -ne $content) {
        [System.IO.File]::WriteAllText($file.FullName, $new, $utf8)
        Write-Host "Fixed: $($file.FullName)"
        $fixed++
    }
}
Write-Host "Done: $fixed files"
