

function CreateBuildFolders {
    
    New-Item -Path "build" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - 3DSS" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - GAMMA" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - demo" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - manufacturers" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - mods" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs Config - template" -ItemType Directory | Out-Null
    
}

function BuildMod {

    $target = "build/SEALs"
    Copy-Item -Recurse -Force -Path ".\Main\gamedata" -Destination $target -Exclude .bak

    $compress = @{
        Path = "build/SEALs/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs.zip"
    }
    Compress-Archive @compress -Force
}

function BuildConfigs {
    param (
        [string]$target
    )
    $targetPath = "build/SEALs Config - " + $target
    Copy-Item -Recurse -Force -Path ".\Modules\$target\gamedata" -Destination $targetPath -Exclude .bak

    $compress = @{
        Path = "$targetPath/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - $target.zip"
    }
    Compress-Archive @compress -Force    
}

function BuildGAMMAConfigs {


    $target = "build/SEALs Config - GAMMA"
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\generation" -Destination $target -Exclude .bak, "vfs_generate*"
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\generation\vfs_generate_3dss_grp.ps1" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\generation\vfs_generate_gamma_grp.ps1" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - GAMMA.zip"
    }
    Compress-Archive @compress -Force     
}

function Build3DSSConfigs {

    $target = "build/SEALs Config - 3DSS"
    Copy-Item -Recurse -Force -Path ".\Modules\3DSS\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\Modules\3DSS\generation" -Destination $target -Exclude .bak, "vfs_generate*"
    Copy-Item -Recurse -Force -Path ".\Modules\3DSS\generation\vfs_generate_3dss_grp.ps1" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - 3DSS.zip"
    }
    Compress-Archive @compress -Force         
}

CreateBuildFolders
BuildMod
BuildGAMMAConfigs
Build3DSSConfigs
BuildConfigs "demo"
BuildConfigs "manufacturers"
BuildConfigs "mods"
BuildConfigs "template"


Remove-Item -Force -Recurse -Path "./build"