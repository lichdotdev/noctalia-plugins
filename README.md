# lich plugins for Noctalia

[Noctalia](https://github.com/noctalia-dev/noctalia) plugins for [lich](https://github.com/lichdotdev/lich).

| Plugin | What it does |
| --- | --- |
| [`lich-sessions`](lich-sessions/) | Your lich sessions in the bar, a panel and on the desktop or lock screen. |

## Install

Add this repository as a plugin source, then enable the plugin:

```sh
noctalia msg plugins source add lich git https://github.com/lichdotdev/noctalia-plugins
noctalia msg plugins enable lichdotdev/lich-sessions
```

`noctalia msg plugins update lich` pulls new versions.

## Developing

Point a path source at your checkout instead and Noctalia hot-reloads the entry scripts as you save:

```sh
noctalia msg plugins source add lich-dev path ~/path/to/noctalia-plugins
```

A module pulled in with `require` is cached until the plugin is disabled and enabled again.
`noctalia plugins lint <plugin-dir>` checks a manifest against its code.

After changing a `plugin.toml`, rebuild the catalog Noctalia lists the source from, and commit it with the change:

```sh
python3 tools/catalog.py
```
