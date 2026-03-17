$utf8 = [System.Text.UTF8Encoding]::new($false)

# Map of invalid FontAwesomeIcons names -> correct ones
$fixes = @{
    # Suffix leftovers (_outlined / _rounded / _off suffixes)
    'calendarDay_outlined'         = 'calendarDays'
    'clock_outlined'               = 'clock'
    'mobileScreen_outlined'        = 'mobileScreen'
    'boxOpen_outlined'             = 'boxOpen'
    'xmark_outlined'               = 'xmark'
    'certificate_outlined'         = 'certificate'
    'shieldHalved_outlined'        = 'shieldHalved'
    'image_outlined'               = 'image'
    'map_outlined'                 = 'map'
    'inbox_outlined'               = 'inbox'
    'tag_outlined'                 = 'tag'
    'solidStar_outlined'           = 'star'
    'solidBell_outlined'           = 'bell'
    'solidBell_off_outlined'       = 'bellSlash'
    'chartBar_outlined'            = 'chartBar'
    'download_outlined'            = 'download'
    'magnifyingGlass_off_rounded'  = 'magnifyingGlass'
    'magnifyingGlass_off'          = 'magnifyingGlass'
    'image_not_supported_outlined' = 'image'

    # Icons that had no mapping - partial match created garbage names
    'lock_reset'                   = 'lockOpen'
    'cartShopping_checkout_rounded' = 'cartArrowDown'
    'store_mall_directory_rounded' = 'store'
    'image_library'                = 'images'
    'minus_shopping_cart_rounded'  = 'cartMinus'
    'plus_card_rounded'            = 'creditCard'
    'minus_circle_outline'         = 'circleMinus'
    'cameraswitch'                 = 'cameraRotate'
}

$files = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart'
$fixed = 0
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    $new = $content
    foreach ($bad in $fixes.Keys) {
        $new = $new.Replace("FontAwesomeIcons.$bad", "FontAwesomeIcons.$($fixes[$bad])")
    }
    if ($new -ne $content) {
        [System.IO.File]::WriteAllText($file.FullName, $new, $utf8)
        Write-Host "Fixed: $($file.FullName)"
        $fixed++
    }
}
Write-Host "Done: $fixed files fixed"
