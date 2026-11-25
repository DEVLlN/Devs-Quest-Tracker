# DeV's Quest Tracker

DeV's Quest Tracker is an unofficial fork of [Questie](https://github.com/Questie/Questie), based on Questie 12.14.0. This development release targets World of Warcraft Forever.

## Install on WoW Forever

1. Download the `DevsQuestTracker` ZIP from [Releases](https://github.com/DEVLlN/Devs-Quest-Tracker/releases) and extract the `DevsQuestTracker` folder into `World of Warcraft/_forever_/Interface/AddOns/`.
2. If `QuestieDB` is missing, download the [official Questie 12.14.0 bundle](https://github.com/Questie/Questie/releases/tag/bundle%2Fv12.14.0%2Bv1.1.6) and copy its `QuestieDB` folder into the same AddOns directory. This build uses QuestieDB 1.1.6.
3. In WoW's AddOns list, disable Questie and enable DeV's Quest Tracker and QuestieDB. Type `/devstracker` in game to open the options.

The fork stores its own settings. New installations start with the addon's defaults.

## Tracker changes

- Quest titles and objectives wrap. The auto-width slider goes down to 5%.
- Quest focus buttons scale independently up to 200%. Quest item buttons appear on the right.
- The optional Classic header fills the tracker width and scales with the font, including the settings and minimize buttons. The question mark can be hidden or faded until hover.
- The tracker can open the current zone and collapse other zone groups. Pinned quests have a group at the top. An option pins quests when manually tracked and removes the pin when untracked.

## Build from source

Clone the repository with Git and run `python -X utf8 build.py --standalone --forever --release`. The installable ZIP is under `releases/`.

Credit for the original addon goes to the Questie team and contributors. See [LICENSE.md](LICENSE.md) for the upstream licensing terms and [gpl-3.0.md](gpl-3.0.md) for the GPLv3 license text. Third-party notices remain with their respective files.
