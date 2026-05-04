> **Warning: Requires [BazCore](https://www.curseforge.com/wow/addons/bazcore) and [BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers).** If you use the CurseForge app they install automatically. Manual users must install both.

# BazBrokerWidget

![Part of BazAddons](https://img.shields.io/badge/Part_of-BazAddons-b8924a?labelColor=2a2519) ![WoW](https://img.shields.io/badge/WoW-12.0_Midnight-blue) ![License](https://img.shields.io/badge/License-GPL_v2-green) ![Version](https://img.shields.io/github/v/tag/BazAddons/BazBrokerWidget?label=Version&color=orange&sort=date)

Bridges [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1) feeds into [BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers). Every LDB-publishing addon (Bagnon, Recount, Skada, BugSack, almost anything with a minimap data button) shows up as its own dockable widget you can position, reorder, or disable like any other BWD widget.

***

## Features

*   **One widget per feed** — BWD's existing enable/disable, reorder, and float controls work per-feed for free
*   **Live updates** — subscribes to LDB attribute changes so text/value/icon updates without a `/reload`
*   **Late-registration aware** — feeds that register after login (lazy init, first event) appear automatically
*   **Click + tooltip forwarding** — feed clicks invoke the addon's normal launcher action; hover shows the feed's native tooltip
*   **Both LDB types** — supports `data source` feeds (text + value) and `launcher` feeds (icon-only quick action)

***

## How It Works

When BazBrokerWidget loads, it asks LDB for every registered data object and registers one BWD dockable widget per feed. Each widget renders a compact:

```
[icon]  Label                    Value
```

Click → forwards to the feed's `OnClick`. Hover → forwards to `OnTooltipShow` / `OnEnter`. Live changes to `text`, `value`, `icon`, and `label` re-render the widget automatically.

Late-registering feeds (the common case for "addon registers LDB on first use") are picked up via the `LibDataBroker_DataObjectCreated` callback, so you don't need to reload to see them.

***

## Slash Commands

| Command | Action |
| ------- | ------ |
| `/bbw` | Open settings |
| `/bbw list` | Print every LDB feed currently registered |
| `/bbw rescan` | Rebuild widgets for all known feeds |
| `/bazbroker` | Alias for `/bbw` |

***

## Compatibility

*   **WoW Version:** Retail 12.0 (Midnight)
*   **LibDataBroker:** 1.1 (embedded)

***

## Dependencies

**Required:**

*   [BazCore](https://www.curseforge.com/wow/addons/bazcore) — shared framework for Baz Suite addons
*   [BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers) — the host that displays widgets

***

## Part of the Baz Suite

BazBrokerWidget is part of the **Baz Suite** of addons, all built on the [BazCore](https://www.curseforge.com/wow/addons/bazcore) framework:

*   **[BazBars](https://www.curseforge.com/wow/addons/bazbars)** — Custom extra action bars
*   **[BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers)** — Slide-out widget drawer
*   **[BazWidgets](https://www.curseforge.com/wow/addons/bazwidgets)** — Widget pack for BazWidgetDrawers
*   **[BazNotificationCenter](https://www.curseforge.com/wow/addons/baznotificationcenter)** — Toast notification system
*   **[BazLootNotifier](https://www.curseforge.com/wow/addons/bazlootnotifier)** — Animated loot popups
*   **[BazFlightZoom](https://www.curseforge.com/wow/addons/bazflightzoom)** — Auto zoom on flying mounts
*   **[BazMap](https://www.curseforge.com/wow/addons/bazmap)** — Resizable map and quest log window
*   **[BazMapPortals](https://www.curseforge.com/wow/addons/bazmapportals)** — Mage portal/teleport map pins

***

## License

BazBrokerWidget is licensed under the **GNU General Public License v2** (GPL v2).
