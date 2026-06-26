# BetterLights

*A Dynamic lighting mod for Garry's Mod.* 

Everything can be configured in the tool menu tab labeled "Better Lights". 

## Steam Workshop

<!-- steam-workshop-stats:start -->
[Steam Workshop Page](https://steamcommunity.com/sharedfiles/filedetails/?id=3597784225)

- Subscribers: **112,692**
- Lifetime subscribers: **199,606**
- Favorites: **11,287**
- Views: **117,210**
- Last updated: **2026-06-26**
<!-- steam-workshop-stats:end -->

> [!IMPORTANT]
> I Highly recommend that you use the 64-Bit branch for Garry's Mod. It's more stable. 

## Contributing Translations

Better Lights uses Garry's Mod `.properties` localization files in `resource/localization/<language>/betterlights.properties`.

The English file is the translation template:

```text
resource/localization/en/betterlights.properties
```

To add or improve a translation:

1. Copy the English file into the supported language folder you want to update, such as `resource/localization/de/betterlights.properties`.
2. Translate only the text after `=`.
3. Keep every key, blank first line, and format placeholder such as `%s` unchanged.
4. Use a Garry's Mod supported language code, such as `de`, `es-ES`, `fr`, `ja`, `ko`, `pl`, `pt-BR`, `ru`, `tr`, `zh-CN`, or `zh-TW`.
5. Run the localization validator before opening a pull request:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate_localization.ps1
```

Current non-English translations were made with the assistance of a large language model. Corrections and native-speaker improvements are welcome as pull requests.

## License

BetterLights is licensed under GPL-3.0-or-later. See [LICENSE.md](LICENSE.md).

<br>
<br>
<p align="center">
  <a href="https://buymeacoffee.com/deisdev">
    <img src="https://i.imgur.com/py0UCVZ.png" width="200" alt="Support">
  </a>
</p>




