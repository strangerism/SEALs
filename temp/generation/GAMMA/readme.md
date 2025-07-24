# Add these to your ModOrganizer.ini for quick shortcuts creation

```

21\arguments=-ExecutionPolicy Bypass -File \"./vfs_generate_gamma_grp.ps1\" update
21\binary=C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
21\hide=false
21\ownicon=false
21\steamAppID=
21\title=update_gamma_seals
21\toolbar=false
21\workingDirectory=D:\\games\\GAMMA\\Anomaly


22\arguments=-ExecutionPolicy Bypass -File \"./vfs_generate_gamma_grp.ps1\"
22\binary=C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
22\hide=false
22\ownicon=false
22\steamAppID=
22\title=generate_gamma_seals
22\toolbar=false
22\workingDirectory=D:\\games\\GAMMA\\Anomaly
```

make sure you update the indexes accordingly to your `ModOrganizer.ini` and the `workingDirectory` with your path to Anomaly

e.g. 

**21**\arguments=-ExecutionPolicy Bypass -File \"./vfs_generate_gamma_grp.ps1\"

to 

**10**\arguments=-ExecutionPolicy Bypass -File \"./vfs_generate_gamma_grp.ps1\"

and so on
