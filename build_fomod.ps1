function BuildMod {
    
    New-Item -Path "build" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs" -ItemType Directory | Out-Null

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

    New-Item -Path $targetPath -ItemType Directory | Out-Null

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

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\generation" -Destination $target -Exclude .bak, "vfs_generate*"
    Copy-Item -Recurse -Force -Path ".\Modules\GAMMA\generation\vfs_generate_gamma_grp.ps1" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - GAMMA.zip"
    }
    Compress-Archive @compress -Force     
}

function BuildModlistConfigs {

    $target = "build/SEALs Config - Modlist"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Modules\Modlist\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\Modules\Modlist\generation" -Destination $target -Exclude .bak, "vfs_generate*"
    Copy-Item -Recurse -Force -Path ".\Modules\Modlist\generation\vfs_generate_modlist_grp.ps1" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - Modlist.zip"
    }
    Compress-Archive @compress -Force     
}

function Build3DSSConfigs {

    $target = "build/SEALs Config - 3DSS"

    New-Item -Path $target -ItemType Directory | Out-Null

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

BuildMod
BuildGAMMAConfigs
Build3DSSConfigs
BuildModlistConfigs

BuildConfigs "demo"
BuildConfigs "manufacturers"
BuildConfigs "mods"
BuildConfigs "template"
BuildConfigs "Anomaly"


Remove-Item -Force -Recurse -Path "./build"