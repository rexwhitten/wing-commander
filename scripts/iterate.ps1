function iterateFiles{
    param
    (
        [string]$directory
    )

    foreach($file in Get-ChildItem $directory)
    {
        # Processing code goes here
        Write-Host $file.FullName
        if ($file.Attributes -eq "Directory") {
            iterateFiles($file.FullName)
        }
    }
}
