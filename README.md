# Fallout 4 Modlist Manager in Perl

## Available Mod Lists

All currently available mod lists are stored in [mo2/snapshots/](mo2/snapshots/).

## Why?!?

- It's about managing files. Perl is perfect for that. No building/compiler/IDE needed to adjust the mod list manager. All you need is a text editor.
- Features a simple, highly transparent overlay mechanism.
- Compiling modlists is fast.
- It's a command line tool!

## Homepage

- https://github.com/jjYBdx4IL/fo4_modlist_mgr

## Prerequisites

- Premium account at https://www.nexusmods.com/ for automatic download of mod archives.
- The perl script has been developed in a cygwin shell. For that reason I recommend running it in one, too:
  - https://www.cygwin.com/
  - Use `perl -cw fo4_modlist_mgr.pl` to check for missing perl modules. The cygwin package for a perl module with a name like `A::B` is usually named `liba-b-perl`.
  - Cygwin command line tools: perl, wget, curl, 7z
- Other command line tools:
  - unrar (https://www.win-rar.com)

## Installing a mod list

**Beware! A mod list restore/install will DELETE all files in the current folder (incl. savegames!) if they are not part of the snapshot!**
 
- `cd mo2 && ../fo4_modlist_mgr.pl --restore=<modlist-name>` - see snapshots/ dir for a list of available modlist names/versions.
- The script is intended to be run from within the ModOrganizer2 root folder, ie. `snapshots/` folder is expected to be on the same level as `profiles/` or `downloads/`.
- Run `../fo4_modlist_mgr.pl --clean` to remove the unpacked archive data if you don't intend to run `fo4_modlist_mgr.pl` any time soon again.
- Do not (!) remove the `downloads/*.meta` files if you plan on updating/maintaining/editing the modlist because those files contain version information needed by MO2.

## Saving a mod list

- `../fo4_modlist_mgr.pl --save=<modlist-name>`
- Will write all necessary data to `snapshots/<modlist-name>`.
- You should check the saved data in `snapshots/<modlist-name>` for files that may be problematic for redistribution because of copyright issues. Generally, there should only be configuration files and (maybe) savegame files etc. in there.
  - `mods/*/meta.ini` files are included because they provide the information necessary to download nexus mod archives.
  - `downloads/*.meta` files should be included because they make it easier to update the restored modlist.
- Stuff like F4SE cannot be installed via MO2. Place archive download links for archives not managed by MO2 into `manual_urls.txt`, which will be included (as most other files in the MO2 folder and below) in any created modlist snapshot.
  - General rule: all nexusmods.com FO4 archives need to be downloaded and installed via ModOrganizer2, even (as is the case for f4se) if contained files need a manual copy operation.
  - The rest of the downloads are manual direct links placed in `manual_urls.txt`.
  - This imples that there currently is no support for non-FO4 modules from nexusmods.com. If an archive does not have any license restrictions, you can simply not provide any download source, which will force it to be included with saved snapshots directly.
- Example command to check for suspicious files in a modlist snapshot:
  - `find snapshots/frost-fast-153 -type f | grep -v "\.\(ini\|meta\|txt\)$"`

## Notes

- Some plugins are disabled because of bugs. Those should be documented in a README_modlist.md file included with the modlist snapshot.
- Some plugins are disabled but not removed because the meta information is used to download archives from nexus mods website. For such plugins, use MO2 to download the archive, then install the archive by unselecting all contained files and ignoring the MO2 warning.

## Possible Improvements

- Unpacks all archives. On-demand extraction would probably be preferable.
