Add-Type -AssemblyName System.Drawing
$imagePath = "C:\Users\MUZAFFAR\.gemini\antigravity\brain\3f52d00f-5c08-4206-a9e5-6aa56b1481ce\netscope_icon_v3_1775809332761.png"
$outputPath = "d:\Projects\AI\v15\assets\app_icon.png"

$bmp = New-Object System.Drawing.Bitmap $imagePath

# We will remove ALL pixels that are close to white. 
# For a clean vector image on white, this will strip the background perfectly.
for ($x = 0; $x -lt $bmp.Width; $x++) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        $pixel = $bmp.GetPixel($x, $y)
        if ($pixel.R -gt 230 -and $pixel.G -gt 230 -and $pixel.B -gt 230) {
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
        }
    }
}

$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Made background perfectly transparent for the new V3 icon!"
