# **SEALs**

![mod](doc/images/SEALs_splash_sm.png)

This mod is a simple configurator to add badges (seals) on the weapons icons in the inventory and tooltip.

![saiga12 ico](doc/images/saiga12ico.png)

![saiga12 tip](doc/images/saiga12tip.png)

Seals are meant to represet certifications of provenience, like modders tag, modpack exclusives, manufacturers, or features support (3DSS etc.), mod support (Black Market, Loot boxes, etc) or qualities (unique weapons, quest rewards, etc)   

At the end of the day is what you make out of it.

This mod is considered a community tool and is meant to be used by weapon's mod makers or modpack curators/maintainers or to support user's custom modlists.

# Technical aspects

The addon consist of the main module, a CLI for templating and generating/updating section's lists and several prefab configuration files modules

## The main module

The main mod (under the hood) does the following:

- reworks the **Dynamic Icons Indicator** mod so that it can apply seals as custom layers on the weapon icons 
- customizes the anomaly's inventory scripts to shows the seals on the item's tooltip as well

- customize the behavior of the mod itself (disable seals, icons scale, etc)

## The configuration module

is used to

- defines the seals (icon, caption)
- the list of weapon where the seals are displayed

## List of configuration modules

> [!CAUTION]
> These modules are provided as examples. 
> The mod is meant to be supported only by the community's contribuitions

- **Anomaly**: Applies Anomaly seals to all weapons from the base game (this is a static prefab configuration).
- **3DSS**: Applies 3DSS seals to all weapons that support this kind of scopes (this is a blank prefab configuration ready to be compiled with data).
- **GAMMA**: Applies seals to all available GAMMA weapons, such weapons are present in loadouts and can drop in game (this is a blank prefab configuration ready to be compiled with data).
- **manufactorers**: applies manufactorers seals to guns (this is an example of static configuration)
- **mods**: applies mods related seals (this is an example of static configuration)

> static configuration are mainly manually edited (e.g. guns added manually to a list) in contrast to the use of generation tools, which we will see below, which can dynamically compile these lists by scanning mods folders or the entire modlist

## The CLI

The CLI, an interactive powershell script, is used to create new config modules, blank or already compiled with data from mods. Data is generated dynamically scanning mods folders or entire modlists.

You execute it's command from the windows terminal

e.g.

```powershell
SEALs.ps1 -new athi -from "GAMMA EXP Edition Redux - 3DSS ATHI Weapon Pack"
```

or as a **Mod Organizer 2** Executables

e.g.

![mo_exe](doc/images/mo_exe.png)

# How to build

Launching the powershell `build_fomod.ps1` file in a windows terminal will build all the modules as above.

```shell
./build_fomod.ps1
```

# How to install and requirements

SEALs is a "spin" or total rework of **Dynamic Icons Indicator**, you don't need this mod installed to use SEALs but you will need it if you want the **Dynamic Icons Indicator** funtionalities. 

> [!CAUTION]
> **SEALs** does not replace **Dynamic Icons Indicator**

You install the main mod and then one or any of the config modules of choice.

The **SEALs** mod only requirement is the mighty

- [MCM Mod Configuration Menu](https://www.moddb.com/addons/anomaly-mod-configuration-menu)

# Two distinct use cases

## End User

The end user will only need to install **SEALs** main module and one or more config modules. This will allow to see seals that are defined in the configs module.

![end_user](doc/images/end_user.png)

## Modder - Modlist customizer

The mod creator that wants to create seals for his gun mod or modlist, must install the main module, the CLI module, the config Anomaly module (optionally) and the config template module. This will allow to create new seals or update/maintain current ones.

![creator_user](doc/images/creator_user.png)

# MCM Configuration

**SEALs** has a configuration MCM menu where you can configure its behaviour.

![mcm_menu](<doc/images/mcm_menu.png>)

The main one is toggling the UI. By holding a key, you can turn on/off the visualization of the seals on the weapon's icons. You can change this keybinding in the MCM menus.

![seal_toggle_ui](doc/images/seal_toggle_ui.gif)

You can change the aspects of seals (scale, positions, etc) in both tooltips and icons. 

# How to use the SEALs CLI

The **SEALs CLI** is a script (porwershell) that you can execute in a windows terminal. It offers the following functions:

- to create new **SEALs** seals config modules from a template
- to populate **SEALs** seals's config modules ***group list*** from existing gun mods
- to generate seals configs data from the modlists VFS
- to generate seals 3DSS configs from the modlists VFS

an example of group list `seals_group_gamma.ltx`

```
[gamma]
wpn_9a91
wpn_abakan_n
wpn_ace52
wpn_adar2_15
wpn_aek
wpn_ak101
wpn_ak103
....

```

The **SEALs** main mod uses the ***group list*** from the configs modules to display seals icons on the gun that are listed in such list

## Installing CLI

1) Install the `SEALs - CLI.zip` addon in **MO2**

![cli_mo2](doc/images/cli_mo2.png)

2) Open the *SEALs - CLI* mod folder in **MO2** and and copy in the clipboard the path to the folder

![cli_folder](doc/images/cli_folder.png)

3) Add this path to your *Windows environment variables*

![env_var](doc/images/env_var.png)

## Templating

CLI allows you to create named configs projects from templates. These projects or mod, will be empty and require the compilation of the **group list** inside. Such compilation can be done manually or automatically through CLI geneneration functions.

1) install a template module in MO2

![template_inst](doc/images/template_inst.png)

2) rename the template mod in MO2 with a name of your choice, e.g. `SEALs Configs - ATHI Guns`

![template_athi](doc/images/template_athi.png)

3) open the renamed mod folder in explorer

![template_ini](doc/images/template_ini.png)

4) open the `template.ini` inside and edit the properties within

	`sealid`: it's the id of the group list in this config module

	`sealmcm`: it's the tab name in the MCM menu for this module

	`sealcaption`: it's the seal's caption that will appear in the item detail's tooltip

	e.g. 
	```
	sealid=athi
	sealmcm=Athi Armory
	sealcaption=Athi Armory
	```
	
	save the changes and exit

5) open a terminal in windows to the `SEALs Configs - ATHI weapons pack` mod folder 

![terminal](doc/images/terminal.png)

6) use the CLI `new` command to create a new template config from a gun mod e.g. `3DSS ATHI Weapon Pack`

```powershell
SEALs.ps1 -new athi -from "GAMMA EXP Edition Redux - 3DSS ATHI Weapon Pack"
```

7) you can now add more group sections to this config mod using `add`

```powershell
SEALs.ps1 -add athi -from "GAMMA EXP Edition Redux - 3DSS-BaS22-Hero-s-Choice"
```

### CLI new

```powershell
SEALs.ps1 -new <sealid>
```

Creates an new blank **SEALs** config mod

### CLI new from mod

```powershell
SEALs.ps1 -new <sealid> -from "<mod_name>"
```

Creates and compile the **SEALs** config mod group section from a mod content 

### CLI add from mod

```powershell
SEALs.ps1 -add <sealid> -from "<mod_name>"
```

Add to the group config new group sections (wpn_*) from a mod 

## Generation

While SEALs templating is limited to create blank configs or single mod configs with generation you can generate configs from the entire modlist content.

To do this the SEALs CLI must be run while the MO2 VFS is running at the same time. This it's done by creating SEALs CLI executable in MO2.

![seals_exe_mo2](doc/images/seals_exe_mo2.png)

### Prefab config modules for generation

**SEALs** ships with two prefab config modules that can be used with modlist

- **SEALs Config - GAMMA**: a prefab config for the **GAMMA** modlist, with this config when populated, will tag all the guns with the GAMMA icon

- **SEALs Config - 3DSS**: a prefab config for **3DSS** mod, with this config when populated, will tag all the guns with the 3DSS icon

Both are empty and need to be compiled with data from the modlist. Here's how to configure CLI in MO2 to generate data for them

![gamma_mo2](doc/images/gamma_mo2.png)

`-ExecutionPolicy Bypass -File "SEALs.ps1" -update gamma`

![3dss_mo2](doc/images/3dss_mo2.png)

`-ExecutionPolicy Bypass -File "./SEALs.ps1" -update -3dss`

### CLI 3DSS generation

The 3DSS group list is a reserved name. 

To use **CLI** to generate such group list you use the switch `-3dss` alongside with the `update|generate` switches

e.g.

```powershell
SEALs.ps1 -update -3dss
```

### Static prefab

These modules contain modlist data already compiled, which can be used as is but can be also used are reference data during the generation of other modules configs

- **SEALs Config - Anomaly**: a prefab config with populated group list that reference all the guns present in **Anomaly** VANILLA. With this config only, SEALs will tag all the guns with the Anomaly seal icon ![anomaly_seal](doc/images/anomaly_seal.png)  

## CLI commands support for VFS execution

You can use the CLI in the MO2 VFS with only two commands (update|generate)

> [!CAUTION]
> Don't use in terminal, these are meant to be used in MO2 executable configurations

### CLI update

```powershell
"./SEALs.ps1" -update <group_for_updating> -exclude -groups <groups_for_exclusion>
```

for example

Assuming you are on the stock gamma profile, you can generate the seals of the current available guns in GAMMA

```powershell
-update gamma -exclude -groups anomaly
```

the command above (when run in VFS) will update the gamma group list `seals_group_gamma.ltx`, contained in the **SEALs Config - GAMMA** mod, with all the available guns in GAMMA, e.g. present in loot tables or referenced for drops or rewards. 

However, the presence of the `exclude` parameter which references the `anomaly` group list (from **SEALs Config - Anomaly** ) means that all entries from that grouplist will be filtered out from the final `gamma` group list of the update command

### CLI generate

if you use `generate` instead of `update`, the group list in **SEALs Config - GAMMA** is not modified, instead the output is written in the **GAMMA** `overwrite` folder 

e.g.

```powershell
-generate gamma
```

## CLI Tutorials

### 1. How to update the SEALs Config - GAMMA

1) be on the **default** GAMMA profile in MO2

2) run the CLI executable *SEALs -update GAMMA* in MO2 

![update_gamma](doc/images/update_gamma.png)

3) the gamma group list file in the mod is updated 

![gamma_grp_list](doc/images/gamma_grp_list.png)

`SEALs Config - GAMMA\gamedata\configs\custom_seal_layers\groups\seals_group_gamma.ltx`

```
[gamma]
wpn_9a91
wpn_abakan_n
wpn_ace52
wpn_adar2_15
wpn_aek
wpn_ak101
wpn_ak103
wpn_ak104_alfa
```

> [!TIP]
> if you run the update with the **SEALs Config - Anomaly** enabled, you can use the `-exclude anomaly` to generate in the group list with the only the weapons that are exclusive to **GAMMA**    

### 2. How to update the SEALs Config - 3DSS

1) be on any profile

2) install and enable **SEALs Config - Anomaly**

3) run the CLI executable *SEALs -update 3dss* in MO2 

![update_3dss](doc/images/update_3dss.png)

4) the 3dss group list file in the mod is updated 

`SEALs Config - 3DSS\gamedata\configs\custom_seal_layers\groups\seals_group_3dss.ltx`

```
[3dss]
wpn_9a91
wpn_abakan_n
wpn_ace52
wpn_adar2_15
wpn_aek
wpn_ak101
wpn_ak103
wpn_ak104_alfa
```

### 3. How to generate SEALs group lists for your custom modlist

1) be on your custom profile e.g. `exp_redux`

2) install and enable **SEALs Config - Anomaly**

3) create a new **blank** SEALs template using CLI `new`

```powershell
SEALs.ps1 -new exp_redux
```

> follow the ***templating*** guide above for all the steps, like editing template.ini etc.

now you should have a blank SEALs mod in MO2 which can name **SEALs Config - EXP Redux**

3) create a MO2 executable for your modlist 

![exp_redux_mo2](doc/images/exp_redux_mo2.png)

3) run the CLI executable just created 

![run_exp_redux](run_exp_redux.png)

4) the exp_redux group list file in the blank mod is now compiled  

`SEALs Config - EXP Redux\gamedata\configs\custom_seal_layers\groups\seals_group_exp_redux.ltx`

```
[exp_redux]
wpn_9a91
wpn_abakan_n
wpn_ace52
wpn_adar2_15
wpn_aek
wpn_ak101
wpn_ak103
wpn_ak104_alfa
```

### 4. How to generate exclusive group list and seals for it

You can use CLI `-exclude` option to update/generate exclusive lists. 

For example you have a custom GAMMA modlist and you have both the **SEALs Config - Anomaly** and **SEALs Config - BAGGA** enabled which applies the Anomaly seals to all the Anomaly guns, but also the GAMMA seal to GAMMA ***enabled*** guns.

However you want to create a new seals that tags all guns you have installed on top of these guns. 

You can create a new SEAL group list as shown in the tutorial 3, but you use the exlude option when generating the group list

For this you must create a new MO2 executable or modify the first one in tutorial 3

![exp_redux_exclude](doc/images/exp_redux_exclude.png)

1) run the CLI executable with the exclude directive

2) the exp_redux group list file in the blank mod is now compiled but it will be shorter than when originally done at tutorial 3

```
[exp_redux]
wpn_aa12
wpn_ak101_sp
wpn_ak101vgrip
wpn_ak103_bp
wpn_ak105_sp
wpn_ak12_mono_com
wpn_ak74uvgrip
```

3) you will also need to create a custom icon texture that will be used as SEAL. This will be explained in the next chapter below

# Anatomy of a SEALs config module

The SEALs config is a ***scaffolding*** type of mod which, as we have seen by now, it's used to hold guns lists and other information needed to display custom seal in game for those guns in the list. 

The files within the SEALs config mod have a special purpose which will be explained here. 

To start, first install a SEAL template and open the mod folder in explorer. 

You will see the content of the mod as such 

![template_content](/doc/images/template_content.png)

This is the agnostic form of the config mod or simply scaffold. Files are named with the `default` token and files inside will have tokens. This form is used by the CLI `new` command to create ***concrete*** config mod with name of your choice. 

We will look in detail at each file and what they are used for, before doing use the `-new` to create an `example` group list config

run ***CLI*** `-new`

```powershell
SEALs.ps1 -new example
```

Now all files' names have been tokenized with the `example` group list name and same with their content 

![example_module](/doc/images/example_module.png)

## The group list file

`seals_group_example.ltx`

The first most important file is the group list file and the only file that is manually or dynamically updated at your will

In this example it's empty since we run `-new` to create a blank config module, we could have initialized with some mod data with `-from` parameter otherwise

## The texture file

`seals_icon_example.dds`

The texture file is the second most important file since you will want to have a new custom icon as seal for the config module. The templating process creates a default texture but you can change it with yours. The important is to keep the name the same and some rules regarding the texture format and size.

- name should be kept as is. Changing the name of this file must be reflected in the texture descriptor file xml file we see next.
- the format must be ***dds***
- the size should be 200x200. If any other size is used then some edits are required in the seals layer config file and texture descriptor file

## The texture descriptor file

`ui_seals_example.xml`

This files reflects the details of the texture files, like size and name. 

```xml
<w>
	<!-- seal icon texture descriptor -->
	<file name = "ui\seals_icon_example">
		<texture id = "ui_seals_icon_example" 				x="0"	y="0"	width="200"	height="200" />	
	</file>				
</w>

```

If you use a bigger texture, which you can, you need to update the `width` and `height` params accordingly

## The SEAL layer config

`seals_layer_example.ltx`

This file is concerned in the way the icon is displayed in the UI in game.

```ini
[example]
primary=false
group = example
texture = ui_seals_icon_example
icon_scale = 8
tooltip_scale = 4
caption = ui_seals_example_caption
```

If you keep with defaults with other files then you don't need to change anything here.

However if you used a bigger texture size than the ***default 200x200***, you must edit the `icon_scale` and `tooltip_scale` by the same factor

for example if your texture is 400x400 instead, then you need to change 

```ini
icon_scale = 16
tooltip_scale = 8
```

### Primary seal

If you set `primary` to ***true*** the seal will be considered a primary seal. Primary seals will be showed alwas as first (from the left) in the weapon icons and in tootips the caption text will be gold colored 

A weapon can show multiple seals but only one can be the primary one.

For instance, the anomaly seal is configured as primary seal

![primary_seal](doc/images/primary_seal.png)

### Override seal

You can use the `overrides` directive to take the place of other seals in the weapon's icon

For example the gamma seal is configured to override the anomaly seal

```ini
[gamma]
group = gamma
primary=true
overrides=anomaly
texture = ui_seals_icon_gamma
```

The `override` directive must reference the group name to which it wants to override

## The UI strings file

`st_ui_seals_example.xml`

This file define the strings used by the custom seal mainly two string

- the seal MCM menu string
- the seal caption string 

If you used the CLI templating, you have already set these two strings in the `template.ini`

# SEALs Distribuition

## Standalone Seals Configs distribuition

If you are gun mod maker and you want to add custom seals to the be shown on the gun you make, lets say your personal badge or the manufacturer.

You have several options on how to distribuite your seals

1. Distribuite a single SEALs config module that contains all your guns seals

2. Embeed the relevant SEALs config module in your gun mod directly

3. Embeed both the SEAL main module and your gun SEALs configs in your gun mod

The first 2 options are the most recommended but also rely on the user having installed SEALs main mod in his modlist, which you can always add (encourage) in your install mod instructions

The third option is the fully standalone solution but as you might expect is the less recommended for obvious reason. So avoid it, if you can. 

I do not prohibit you however to distribuite the SEALs main mod with your mod files but there could be bad effects doing so on the user side if you do so, so be mindful of this and respectful of the users needs as well.

## Distribuiting in modlists

You are free to install **SEALs** in your modlist and separately maintain the **SEALs**'s configs in mods or repositories

# Maintaining SEALs

## **Modpack Curators**

As a modpack curator, for yourself or for open distribuition, you are constantly adding new guns or altering the gameplay balance (e.g. updating the loadouts) therefore you will be maintaining the **SEALs** lists as consequence.

The best approach is to keep the **SEALs** mod separated from the **SEALs** configs you create. Use the CLI to keep updated these configs and commit to the repositories (if you use these) only the configs but not the CLI itself.

## **Modpack Users**

If assumingly there will be modpacks that makes use of SEALs, as a user that adds new guns you want to make sure your custom seals are separated from those that comes with the modpack.

# Showcase

Some images to show how the result of using SEALs

![showcase1](/doc/images/showcase1.png)

![showcase2](/doc/images/showcase2.png)

![showcase3](/doc/images/showcase3.png)

![showcase4](/doc/images/showcase4.png)

![showcase5](/doc/images/showcase5.png)

![showcase6](/doc/images/showcase6.png)

# Project Mascotte

![s3al](doc/images/SEALs_stalker_sm.png)

# Credits and disclaimers

This mod could not exists without **HarukaSai** and its **Dynamic Icons Indicator** mod [ddi](https://www.moddb.com/mods/stalker-anomaly/addons/dynamic-icon-indicators) 

Full credits to **HarukaSai** and its DII engine that is doing most of the work for **SEALs**

Thanks to all my invisible collaborators

All icons and SEALs images for this project have been generated using ai tools