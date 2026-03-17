# Fix 1: Add alignment: Alignment.center to Containers with BoxShape.circle that contain FaIcon
# The strategy: find Container(..., shape: BoxShape.circle, ...) without alignment, add it

$utf8 = [System.Text.UTF8Encoding]::new($false)

# Fix access_boutique_screen: Icon(FontAwesomeIcons -> FaIcon + IconButton constraints
$f = 'lib\features\access_boutique\access_boutique_screen.dart'
$c = [System.IO.File]::ReadAllText($f, $utf8)
# Fix Icon( -> FaIcon( for FA icons in IconButton
$c = [regex]::Replace($c, '(?<!Fa)Icon\(\s*(FontAwesomeIcons)', 'FaIcon($1')
# Add constraints to IconButton inside circles (padding: EdgeInsets.zero -> padding: EdgeInsets.zero, constraints: BoxConstraints(),)
$c = $c.Replace('padding: EdgeInsets.zero,
                      onPressed', 'padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed')
[System.IO.File]::WriteAllText($f, $c, $utf8)
Write-Host "Fixed: $f"

# Fix product_detail_screen: add alignment to circle containers
$f2 = 'lib\features\boutique\product\product_detail_screen.dart'
$c2 = [System.IO.File]::ReadAllText($f2, $utf8)
# The xmark container (44x44 circle, no alignment)
$c2 = $c2.Replace(
    "                  decoration: BoxDecoration(`r`n                    color: Colors.black54,`r`n                    shape: BoxShape.circle,`r`n                  ),`r`n                  child: const FaIcon(",
    "                  decoration: BoxDecoration(`r`n                    color: Colors.black54,`r`n                    shape: BoxShape.circle,`r`n                  ),`r`n                  alignment: Alignment.center,`r`n                  child: const FaIcon("
)
[System.IO.File]::WriteAllText($f2, $c2, $utf8)
Write-Host "Fixed: $f2"

Write-Host "Done"
