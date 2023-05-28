# ClassicCastbars

World of Warcraft Classic addon that brings back the target & nameplate castbars. Casting times for players in Classic Era are always based on highest spell rank due to API restrictions. TBC & Wrath works like usual.

**Note: This addon is now in maintenance mode, expect less frequent updates.**

## Links

- [CurseForge Main Download & FAQ](https://www.curseforge.com/wow/addons/classiccastbars)
- [How to Install AddOns](https://www.wowinterface.com/forums/faq.php?faq=install)
- [Submit Translations](https://www.curseforge.com/wow/addons/classiccastbars/localization)
- [Submit Bugs or Issues](https://github.com/wardz/ClassicCastbars/issues)

## Configuration

Castbars have configurable size, textures, positioning and more.  
Type `/castbar` or go to "Escape -> Interface Options -> AddOns -> ClassicCastbars" to open the options panel.
  
If for some reason the addon stopped working, try temporarily disabling all other addons too see if there's any conflicts, or run this macro ingame twice: (Will reset all castbar settings to default)

`/run ClassicCastbarsDB=nil;ClassicCastbarsCharDB=nil;EnableAddOn("ClassicCastbars");EnableAddOn("ClassicCastbars_Options")ReloadUI();`

### License

Copyright (C) 2023 Wardz | [MIT License](https://opensource.org/licenses/MIT).
