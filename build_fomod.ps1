function BuildMod {
    
    New-Item -Path "build" -ItemType Directory | Out-Null

    New-Item -Path "build/SEALs" -ItemType Directory | Out-Null

    $target = "build/SEALs"
    Copy-Item -Recurse -Force -Path ".\Main\gamedata" -Destination $target -Exclude .bak
    Copy-Item -Recurse -Force -Path ".\NPE\gamedata" -Destination $target -Exclude .bak

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

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - Modlist.zip"
    }
    Compress-Archive @compress -Force     
}

function BuildTemplateConfigs {

    $target = "build/SEALs Config - Template"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\CLI\generation\templates\gamedata" -Destination "$target\gamedata"
    Copy-Item -Recurse -Force -Path ".\CLI\template.ini" -Destination $target

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - Template.zip"
    }
    Compress-Archive @compress -Force     
}

# function BuildConfigsGenerator {

#     $target = "build/SEALs Config - Generator"

#     New-Item -Path $target -ItemType Directory | Out-Null

#     Copy-Item -Recurse -Force -Path ".\CLI\generation" -Destination "$target\generation"
#     Copy-Item -Recurse -Force -Path ".\CLI\SEALs.ps1" -Destination $target

#     $compress = @{
#         Path = "$target/*" 
#         CompressionLevel = "Fastest"
#         DestinationPath = "release/SEALs Config - Modlist.zip"
#     }
#     Compress-Archive @compress -Force     
# }

function Build3DSSConfigs {

    $target = "build/SEALs Config - 3DSS"

    New-Item -Path $target -ItemType Directory | Out-Null

    Copy-Item -Recurse -Force -Path ".\Modules\3DSS\gamedata" -Destination $target -Exclude .bak

    $compress = @{
        Path = "$target/*" 
        CompressionLevel = "Fastest"
        DestinationPath = "release/SEALs Config - 3DSS.zip"
    }
    Compress-Archive @compress -Force         
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
        DestinationPath = "release/SEALs - CLI.zip"
    }
    Compress-Archive @compress -Force   
}

BuildMod
BuildGAMMAConfigs
Build3DSSConfigs
BuildSEALsCLI
BuildTemplateConfigs

# BuildConfigs "demo"
BuildConfigs "manufacturers"
BuildConfigs "mods"
BuildConfigs "Anomaly"
BuildConfigs "RWAP"
BuildConfigs "ATHI"
BuildConfigs "BaS"


Remove-Item -Force -Recurse -Path "./build"