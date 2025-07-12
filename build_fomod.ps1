

function CreateBuildFolders {
    
    New-Item -Path "build" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs" -ItemType Directory | Out-Null
    
}

function BuildMod {

    $target = "build/SEALs"
    Copy-Item -Recurse -Force -Path ".\Main\gamedata",".\Main\generators" -Destination $target -Exclude .bak
}

CreateBuildFolders
BuildMod

$compress = @{
    Path = "build/SEALs/*" 
    CompressionLevel = "Fastest"
    DestinationPath = "release/SEALs.zip"
}
Compress-Archive @compress -Force

Remove-Item -Force -Recurse -Path "./build"