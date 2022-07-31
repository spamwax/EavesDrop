![](misc/eaves1.png)
![](misc/eaves2.png)

This is my attempt to get this addon going as I am kind of addicted to it since 2008!

The goal is to make it work under latest game version (currently 9.1)

You can install it using [wago.io app](https://addons.wago.io/addons/eavesdrop) or follow these instructions:

First download the EavesDrop.zip from [latest release page](https://github.com/spamwax/EavesDrop/releases/latest).

These instructions assume you have extracted (or are about to extract)
this .zip file with "Retain directory structure" enabled.

## Installation Instructions

1. Go into your WoW installation folder (e.g. `C:\Program Files (x86)\World of Warcraft\_retail_`)
2. Go into the `Interface` sub-folder
3. Go into the `AddOns` sub-folder (if you don't have one, create it)
4. Copy/Extract this addon's folder into the AddOns folder.
5. Make sure the folder name is `EavesDrop`

### Verification

  The following folder paths will exist within your WoW Install directory:

```sh
    Interface\AddOns\EavesDrop\
    Interface\AddOns\EavesDrop\libs\
    Interface\AddOns\EavesDrop\locals\
```

  Look for the following (wrong) files as evidence of common mistakes:

  * If you have `Interface\AddOns\EavesDrop.toc`
    then you've extracted the zip file's contents without its
        folder structure, or copied the contents without the parent
        folder.
  * If you have `Interface\AddOns\EavesDrop\EavesDrop\EavesDrop.toc`
    ... then you've extracted the zip file into a folder an extra
        level deep. Move the files and any sub-folders up one level
        and remove the extra folder.
  * If you have `Interface\AddOns\EavesDrop-2.8\` or similar, you need to rename it to `EavesDrop`

Original [logs by grayhoof](misc/old_readme.md)
