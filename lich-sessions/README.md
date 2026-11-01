# lich Sessions

The sessions open in [lich](https://github.com/lichdotdev/lich), drawn the way lich's own sidebar draws them:
grouped by project and sidebar folder, each card with the agent's mark in a status ring that spins while the agent
works, turns amber when it waits for you and green when its turn is done. Under the title, a working session shows
the tool its turn runs and one waiting for you says why, on a lich whose `lich sessions --json` reports them; on an
older one that line is the session's path.

![The panel, with example sessions](thumbnail.webp)

## Entries

| Entry | Kind | What it shows |
| --- | --- | --- |
| `bar` | Bar widget | The lich mark, how many sessions are working, and an amber badge with how many wait for you. Click it to open the panel. |
| `panel` | Panel | Every session by project and folder, with its branch. Click a card to bring lich forward with that session open. |
| `desktop` | Desktop widget | The same list, read-only, for the desktop or the lock screen. |
| `service` | Service | Polls lich and sends a notification when a session starts waiting for you. |

## Settings

| Setting | Entries | Default | What it does |
| --- | --- | --- | --- |
| `order` | `panel`, `desktop` | `attention` | `attention` puts the sessions waiting for you first, then the working ones; `lich` keeps lich's sidebar order. |
| `max_sessions` | `desktop` | `8` | How many cards the desktop widget shows (1-30), with a "+N" line for the rest. Desktop widgets cannot scroll. |

Add the bar widget from the bar's *Add widget* picker and the desktop widget from the desktop or lock-screen widget
editor. Shell sessions are left out.

Open the panel from a keybind with:

```sh
noctalia msg panel-toggle lichdotdev/lich-sessions:panel
```

## Performance

Noctalia cannot animate an image by itself, so every step of the busy spinner rebuilds
the widget's whole tree and the host redraws it. What that costs, measured on an
i7-13650HX with three busy sessions:

| Entry | While a session is busy | Otherwise |
| --- | --- | --- |
| `desktop` | redraws at 10fps on the host's frame ticks: 3-7% of one core | redraws only when a session changes state |
| `panel` | redraws at 30fps, only while the panel is open | idle |
| `service` | runs `lich sessions --json` every second, and the folder and worktree commands every 15 seconds | the same |

A timer-driven desktop widget at 30fps cost 30-40% of a core, even with the widget covered
by windows, which is why the desktop widget follows the host's frames at a lower rate.
Each desktop or lock-screen widget you add is its own instance and adds its own cost.

## Dependencies

- `lich` on `PATH`, running.
- `git`, for the branch of each project's own checkout.

## What it runs

Every process the plugin starts, all read-only except `lich focus`:

| Command | When |
| --- | --- |
| `lich sessions --json` | Every second. |
| `lich folders --project <dir> --json` | Every 15 seconds, once per project. |
| `lich worktrees --project <dir> --json` | Every 15 seconds, once per project. |
| `git -C <dir> branch --show-current` | Every 15 seconds, once per project. |
| `lich focus --project <dir> <session>` | When you click a card in the panel. |

It makes no network calls. It writes only the ring and mark SVGs, in the active palette's colors, under its own
plugin data directory, one set per palette.

## Credits

The provider marks are from [Lobe Icons](https://github.com/lobehub/lobe-icons) (MIT, © 2023 LobeHub), taken from
lich's own icon set.
