# FROST-Fast

FROST-Fast is a very performance-oriented FROST mod list. It should run fine on GTX 1060/3 GB cards at FullHD@60fps. It does not include ENBs, changes to shaders/graphical postprocessing and neither does it include HD textures.

- based on: https://github.com/richardaubin/FROST-Fast v1.5.2 (check it out for Optional High-Res Textures and how to modify ini files in case you want to modify your own ini files and not use the included ones)

## Game-Breaking Bugs

- none known

## Homepage

- https://github.com/jjYBdx4IL/fo4_modlist_mgr

## Installation

You can ignore the following installation steps if you load the included save game. All you need is an up-to-date and pristine Fallout 4 Steam installation with all DLCs and in English, but without HD textures.

### MCM Configuration

When you have finished character setup, hit _ESC_ and click _Mod Config_.

NPCs Travel is the only one which *must* be configured.

* NPCs Travel > Number of NPCs > set Synth Patrol to 0
* NPCs Travel > Number of NPCs > DLC > set everything under Far Harbor to 0, including Nuka-World and Nuka-World Open Season

### Holotape Configuration

There are optional settings accessible via Pip-Boy holotapes. You can craft them at any Chemistry Table.

You are done with installation!

## Maintenance

- If you change/add/remove any mod related to item sorting, you have to re-run R88SimpleSorter.bat from MO2 (select "New Patch" and leave everything else as it is, that will update complex_sorter_list.esp in the R88SimpleSorter OUTPUT mod). 
  - the process also generates a log file in FO4Edit/ which you might want to remove before saving the modlist.
- FallUI: install everything (incl sorter mod tags) except the sorter mod itself

## Notes

- Some plugins are disabled because of bugs (see below).
- Some plugins are disabled but not removed because the meta information is used to download archives from nexus mods website. For such plugins, use MO2 to download the archive, then install the archive by unselecting all contained files and ignoring the MO2 warning.
- MXPF is located under Skyrim at nexusmods. It has relaxed licensing terms, so it's okay to include it directly with the snapshot(s).

## Bugs

- bad graphics performance around Bunker Hill (NW?)
- minor: Scavver's Toolbox freezes game when used while wearing power armor: https://www.nexusmods.com/fallout4/mods/17507?tab=bugs
- (FROST Lore Tweaked Sanity Loss: disabled because it prevents sanity from falling.)

## Additional Links

-  FROST Unofficial Updates - Outdated and Incompatible FROST mods and patches:
  - https://www.nexusmods.com/fallout4/articles/3392 
- https://www.reddit.com/r/fodust/comments/m2fp77/list_of_frost_expansion_mods/
- Essentials:
  - https://www.reddit.com/r/fodust/comments/mc77bs/frost_ultimate_guide_for_beginners_advanced/
  - Frost Modding: Designed for Newbies: https://docs.google.com/document/d/145k1OWDNetfPIB46hNB-AFaakn4Snxcj9NbUvbjyYhQ/edit
  - A (More) Comprehensive List of Mods for FROST! https://docs.google.com/document/d/1S9OpgbcNGCplKM_BrnksRCu8Y3vqYMkHkY4rXseZ0zE/edit

## TODO

...

## ChangeLog

### 1.5.4

- switched to FCF (FROST Cell Fixes)
- added Marshland DLC - https://www.nexusmods.com/fallout4/mods/48628?tab=description
  - related FROST patch - https://www.nexusmods.com/fallout4/mods/51987
- added The Forest DLC - https://www.nexusmods.com/fallout4/mods/46602
  - related FROST patch - https://www.nexusmods.com/fallout4/mods/52003
- added FO4Edit, mxpf, R88SimpleSorter_SCRIPTS; hooked up MO2 with R88SimpleSorter.bat
- switched from FROST .055 loose files to archive
- removed eleanor restored and updated according to FROST Unofficial Updates (v1.0.2)
  - https://docs.google.com/document/d/13YjEqEDCR0pyvfZsknELAw1t8JZjNxZy49f6nGk-4bk/edit
  - https://www.nexusmods.com/fallout4/articles/3392
