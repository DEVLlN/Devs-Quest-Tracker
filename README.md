# DeV's Quest Tracker

DeV's Quest Tracker is an unofficial fork of [Questie](https://github.com/Questie/Questie), based on Questie 12.15.0. This development release targets World of Warcraft Forever.

## Install on WoW Forever

1. Download the [complete Forever ZIP from Releases](https://github.com/DEVLlN/Devs-Quest-Tracker/releases).
2. Extract both folders, `DevsQuestTracker` and `QuestieDB`, directly into `World of Warcraft/_forever_/Interface/AddOns/`.
3. In WoW's AddOns list, enable DeV's Quest Tracker and QuestieDB, and disable stock Questie if installed. Type `/devstracker` in game to open the options.

The complete ZIP includes the [official QuestieDB 1.1.6 Forever build](https://github.com/Questie/QuestieDB/releases/tag/v1.1.6). Use the tracker-only ZIP if you manage QuestieDB separately.

The fork stores its own settings. New installations start with the addon's defaults.

## Tracker changes

- Quest titles and objectives wrap. The auto-width slider goes down to 5%.
- Quest focus buttons scale independently up to 200%. Quest item buttons appear on the right.
- The optional Classic header fills the tracker width and scales with the font, including the settings and minimize buttons. The question mark can be hidden or faded until hover.
- The tracker can open the current zone and collapse other zone groups. Pinned quests stay at the top, with completed quests grouped below when **Group Completed Quests** is enabled.
- Ctrl-right-click a quest in the tracker to pin or unpin it. The shortcut is configurable under Tracker. If automatic pinning is enabled, focusing a quest also puts it in the pinned group until you clear focus. A manual pin survives that change.
- **Combat Category Toggles (Beta)** allows the tracker to refresh quest rows and expand or collapse groups during combat when possible. Quest-item buttons dim until combat ends.
- Shortest Path Forever's attached tracker follows the quest tracker when it moves or resizes.

## Build from source

Clone the repository with Git and run `python -X utf8 build.py --standalone --forever --release`. The installable ZIP is under `releases/`.

Credit for the original addon goes to the Questie team and contributors. See [LICENSE.md](LICENSE.md) for the upstream licensing terms and [gpl-3.0.md](gpl-3.0.md) for the GPLv3 license text. Third-party notices remain with their respective files.
