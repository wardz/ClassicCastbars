# ClassicCastbars

Lightweight addon that adds casting bars to various unitframes in Classic World of Warcraft.

![Imgur](https://i.imgur.com/thxJqi6.jpg)

## Install

Installing directly from source is not guaranteed to work. You should instead download a packaged version here:

- [CurseForge Download.](https://www.curseforge.com/wow/addons/classiccastbars)
- [WoWInterface Download.](https://wowinterface.com/downloads/info24925-ClassicCastbars.html)
- [Github Download.](https://github.com/wardz/classiccastbars/releases) (Choose binary instead of source code)

## Configuration

Type `/castbar` or go to `Escape -> Interface Options -> AddOns -> ClassicCastbars` to open the options panel.

## Contribute

- [Help translate.](https://www.curseforge.com/wow/addons/classiccastbars/localization)
- [Submit an issue or feature request.](https://github.com/wardz/ClassicCastbars/issues)
- [Submit a pull request.](https://github.com/wardz/ClassicCastbars/pulls)
  When forking the addon you should save the folder somewhere outside your WoW AddOns directory and
  instead have two symlinks inside the AddOns folder pointing to
  `ClassicCastbars/ClassicCastbars/` and `ClassicCastbars/ClassicCastbars_Options/`.
  As of TBC release, you now need to run the [BigWigs packager](https://github.com/BigWigsMods/packager) script after making changes to the code.
  `./release.sh -d -l -z -g bcc` for TBC and `./release.sh -d -l -z -g classic` for Classic era.

## License

Copyright (C) 2019 Wardz | [MIT License](https://opensource.org/licenses/MIT)
