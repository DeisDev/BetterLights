# Better Lights

*Configurable dynamic lighting for Garry's Mod.*

Better Lights adds extra dynamic lighting to weapons, NPCs, items, projectiles, fires, explosions, and other effects. Most features can be adjusted or turned off from the **Better Lights** tab in the spawn menu.

## Steam Workshop

<!-- steam-workshop-stats:start -->
[Steam Workshop Page](https://steamcommunity.com/sharedfiles/filedetails/?id=3597784225)

- Subscribers: **114,946**
- Lifetime subscribers: **203,903**
- Favorites: **11,390**
- Views: **118,224**
- Last updated: **2026-07-01**
<!-- steam-workshop-stats:end -->

> [!IMPORTANT]
> I strongly recommend using the 64-bit branch of Garry's Mod. The addon is tested there, and the game is usually more stable on it.

## Translation Help

Better Lights uses Garry's Mod `.properties` localization files. Each supported language has its own file here:

```text
resource/localization/<language>/betterlights.properties
```

The English file is the translation template:

```text
resource/localization/en/betterlights.properties
```

To add or improve a translation, copy the English file into the language folder you want to work on, then translate the player-facing text.

Please keep these details unchanged:

1. Every key before `=`
2. The blank first line
3. Format placeholders such as `%s`
4. The existing file name and folder format

Before opening a pull request, run the localization validator:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate_localization.ps1
```

The current non-English translations were made with help from a large language model, so corrections from native speakers are very welcome.

## License

Better Lights is licensed under GPL-3.0-or-later. See [LICENSE.md](LICENSE.md).

<br>
<br>
<p align="center">
  <a href="https://buymeacoffee.com/deisdev">
    <img src="https://i.imgur.com/py0UCVZ.png" width="200" alt="Support">
  </a>
</p>




