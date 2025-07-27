function BuildMod {
    
    $target = "build/SEALs"
    
    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Main\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\NPE\gamedata" -Destination $target -Exclude .bak

    $compress = @{
        Path = "build/SEALs/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs.zip"
    }
    Compress-Archive @compress -Force

    Remove-Item -Force -Recurse -Path $target
}

function BuildFOMod {

    $target = "build/SEALs"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\fomod", ".\Main", ".\CLI", ".\Config\Module", -Destination $target -Exclude .bak

    New-Item -Path "$target\CLI\gamedata" -ItemType Directory | Out-Null
    New-Item -Path "$target\CLI\gamedata\.keep" -ItemType File -Force | Out-Null

    $compress = @{
        Path = "build/SEALs" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs-FOMOD.zip"
    }
    Compress-Archive @compress -Force

    Remove-Item -Force -Recurse -Path $target
}

function BuildConfigs {
    param (
        [string]$target
    )

    $targetPath = "build/SEALs Config - " + $target

    New-Item -Path $targetPath -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Config\Module\$target\gamedata" -Destination $targetPath -Exclude .bak

    $compress = @{
        Path = "$targetPath/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs_Config-$target.zip"
    }
    Compress-Archive @compress -Force    

    Remove-Item -Force -Recurse -Path $targetPath
}

function BuildGAMMAConfigs {

    $target = "build/SEALs Config - GAMMA"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Config\Module\GAMMA\gamedata" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs_Config-GAMMA.zip"
    }
    Compress-Archive @compress -Force     

    Remove-Item -Force -Recurse -Path $target
}

function BuildTemplateConfigs {

    $target = "build/SEALs Config - Template"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\CLI\generation\templates\gamedata" -Destination "$target\gamedata"
    Copy-Item -Recurse -Force -Path ".\CLI\template.ini" -Destination $target

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs_Config-Template.zip"
    }
    Compress-Archive @compress -Force     

    Remove-Item -Force -Recurse -Path $target
}

function Build3DSSConfigs {

    $target = "build/SEALs Config - 3DSS"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Config\Module\3DSS\gamedata" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs_Config-3DSS.zip"
    }
    Compress-Archive @compress -Force         

    Remove-Item -Force -Recurse -Path $target
}

function BuildSEALsCLI {

    $target = "build\SEALs - CLI"

    New-Item -Path $target -ItemType Directory | Out-Null
    New-Item -Path "$target\gamedata" -ItemType Directory | Out-Null
    New-Item -Path "$target\gamedata\.keep" -ItemType File -Force | Out-Null

    Copy-Item -Recurse -Force -Path ".\CLI\generation" -Destination "$target\generation"
    Copy-Item -Recurse -Force -Path ".\CLI\SEALs.ps1" -Destination $target
    Copy-Item -Recurse -Force -Path ".\CLI\template.ini" -Destination $target

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs_CLI.zip"
    }
    Compress-Archive @compress -Force   

    Remove-Item -Force -Recurse -Path $target
}

New-Item -Path "build" -ItemType Directory | Out-Null

BuildMod
BuildSEALsCLI
BuildTemplateConfigs
BuildFOMod

BuildGAMMAConfigs
Build3DSSConfigs
BuildConfigs "manufacturers"
BuildConfigs "mods"
BuildConfigs "Anomaly"
BuildConfigs "RWAP"
BuildConfigs "ATHI"
BuildConfigs "BaS"


Remove-Item -Force -Recurse -Path "./build"