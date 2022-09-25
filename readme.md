[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/spamwax/EavesDrop/ci?color=blue&logo=github&style=for-the-badge)](https://github.com/spamwax/EavesDrop/actions/workflows/ci.yml)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/spamwax?style=for-the-badge&logo=github&color=green)](https://github.com/sponsors/spamwax?frequency=one-time)

<p><img src="misc/eaves1.png" alt="screenshot1" width="22%"/>
<img src="misc/eaves2.png" alt="screenshot2" width="25%"/></p>

## To test the addon in Dragonflight Beta servers switch to [dragon](https://github.com/spamwax/EavesDrop/tree/dragon) branch and download the zip file from the `Code` dropdown menu.

This is my attempt to keep [Grayhoof](https://www.wowinterface.com/downloads/author-14368.html)'s addon going as I am kind of addicted to it since 2008!

The goal is to make it work under latest game version (currently 9.2.5). Please report any issues or bugs on the project's [Github pae](https://github.com/spamwax/EavesDrop).

## What does it do?
A simple combat log that shows events (such as damae, heal, buff/debuff...), using icons and colors to make it easy to find
important information by a quick skim. It separates incoming events (left side) from outgoing events (right side) from misc. events (middle).

Additionally, it keeps track of each spell's maximum *normal* and **critical** hits! :sunglasses:

----

## Installation
### Using wago.io app
Install  [wago.iop app](https://addons.wago.io/app) and search for `EavesDrop` in the app to install this addon.

### Manual Installation
Download the `EavesDrop.zip` file from either [wago.io](https://addons.wago.io/addons/eavesdrop) or [github.com](https://github.com/spamwax/EavesDrop/releases/latest).
Then follow these instructions:

1. Go into your WoW installation folder (e.g. `C:\Program Files (x86)\World of Warcraft\_retail_`).
2. Go into the `Interface` sub-folder.
3. Go into the `AddOns` sub-folder (if you don't have one, create it).
4. Copy/Extract this addon's folder into the `AddOns` folder.
5. Make sure the folder name is `EavesDrop`.

#### Verification

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
        then you've extracted the zip file into a folder an extra
        level deep. Move the files and any sub-folders up one level
        and remove the extra folder.
  * If you have `Interface\AddOns\EavesDrop-2.8\` or similar, you need to rename it to `EavesDrop`.

For more detailed instructions see [wowointerfaces](http://www.wowinterface.com/forums/faq.php?faq=install#faq_howto_install)'s FAQ.

----

Original [FAQ/Notes](misc/old_readme.md) by Grayhoof.
