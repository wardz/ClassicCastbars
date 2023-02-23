# ClassicCastbars

World of Warcraft Classic addon that brings back the target & nameplate castbars. Casting times in Classic Era are always based on highest spell rank due to API restrictions. TBC & Wrath works like usual. (Dragonflight should technically work too but is not really supported at the moment)

Note: This addon is now in maintenance mode.

## Links

- [CurseForge Download & FAQ](https://www.curseforge.com/wow/addons/classiccastbars)
- [Github Download](https://github.com/wardz/classiccastbars/releases)
- [How to Install AddOns](https://www.wowinterface.com/forums/faq.php?faq=install)
- [Submit Translations](https://www.curseforge.com/wow/addons/classiccastbars/localization)
- [Submit Bugs or Feedback](https://github.com/wardz/ClassicCastbars/issues)

### Contributing

When you want to test changes to the addon's source code you will need to run the [BigWigs packager](https://github.com/BigWigsMods/packager) script. You should setup a symlink for `/ClassicCastbars/` and `/ClassicCastbars_Options/` in the generated `ClassicCastbars/.release/ClassicCastbars/` folders, and link it to your WoW addons folder so your game files are always up to date after running the packager script.  
See file `add_symlinks.bat` for Windows.
  
**BigWigs Packager Script:**  
*On Windows you can run this shell file inside Git Bash. Replace `classic` with wrath, bcc or retail for different builds.*

- Test Build: `./release.sh -d -l -z -e -g classic`

### License

Copyright (C) 2022 Wardz | [MIT License](https://opensource.org/licenses/MIT).
