# **SEALs**

This mod is a simple configurator to add badges (seals) on the weapons icons in the inventory and tooltip.

![saiga12 ico](doc/images/saiga12ico.png)

![saiga12 tip](doc/images/saiga12tip.png)

Seals are meant to represet certifications of provenience, like modders tag, modpack exclusives, manufacturers, or technical support (3DSS etc.), mod support (Black Market, Loot boxes, etc) or specifics (unique weapon)   

At the end of the day is what you make out of it.

This mod is considered a community tool and is meant to be used by weapon's mod makers or modpack curators/maintainers or to support user's custom modlists.

# Techical aspects

The mod consist of main mod and configuration files modules

## The main mod

The main mod (under the hood) does the following:

- customizes the **Dynamic Icons Indicator** mod so it can apply seals as custom layers on the weapon icons 
- customizes the anomaly's inventory scripts to shows the seals on the item's tooltip as well

- customize the behavior of the mod itself (disable seals, icons scale, etc)

## The configuration module

is used to

- defines the seals (icon, caption)
- the list of weapon where the seals are displayed

## List of configuration modules

> [!CAUTION]
> These modules are provided as examples. 
> The mod is meant to be supported only by the community's > contribuitions

- 3DSS: Applies 3DSS seals to all weapons that support this kind of scopes
- GAMMA: Applies seals to all available GAMMA weapons, such weapons are present in loadouts and can drop in game. This module also includes the 3DSS seals
- manufactorers: applies manufactorers seals to guns (this is an example mod)
- demo: Combine all the config modules in one, for demo purposes
- mods: applies mods related seals (this is an example mod)
- template: template config module meant to be used for creating new/custom seals configurations

# How to build

Launching the powershell `build_fomod` file in a windows terminal will build all the modules

```shell
./build_fomod.ps1
```

# How to install and requirements

You install the main mod and then one or any of the config modules of choice

The **SEALs** mod requirements are:

- [MCM Mod Configuration Menu](https://www.moddb.com/addons/anomaly-mod-configuration-menu)
- [Dynamic Icon Indicators](https://www.moddb.com/mods/stalker-anomaly/addons/dynamic-icon-indicators)
- [HD Inventory Icons Framework](https://www.moddb.com/mods/stalker-anomaly/addons/hd-inventory-icons-framework)

The **SEALs** mod must be installed below these 3 mods

![alt text](doc\images\loadorder.png)