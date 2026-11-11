<p align="center"><img src="media/logo.svg" alt="" width="128"></p>

# Account Statistics

A World of Warcraft: Forever add-on that shows the in-game Statistics of all your characters side by side, plus totals across your whole account. Search for a Statistic, for example "death", and see every character's value and the account total on one row.

## Features

- **Statistics window**: every Statistic from the game's Statistics panel, by Category, with the value of the character you pick and the Account Total.
- **Account Totals**: each Statistic summed over all your characters, or the highest value for records such as "Largest hit dealt". Hover a total to see the top 5 characters behind it.
- **Search**: type part of a name to narrow the list to matching Statistics and Categories.
- **Character dropdown**: pick any of your characters and see when each one last synced.
- **Minimap button**: opens the window; drag it to move it around the Minimap.
- **English and German**, following the game's language.

## Usage

- `/stats`, or a click on the Minimap button, opens and closes the Statistics window.
- `/stats minimap` hides the Minimap button, and shows it again.

## How it works

WoW only lets an add-on read the Statistics of the character you are logged in with. So each character saves a Snapshot of its Statistics when you log in, log out or `/reload`, and the add-on combines those Snapshots. A character shows up after you have logged in with it once while the add-on is enabled.

To forget a character, for example after deleting it, hover it in the window's character dropdown and click its X. Logging it in again tracks it anew.

## Install

With the [CurseForge app](https://www.curseforge.com/download/app): choose your WoW: Forever installation and search for "Account Statistics".

By hand: download the zip from [Releases](../../releases) and unpack it into `World of Warcraft/_forever_/Interface/AddOns/`.

## Feedback

Report bugs and ideas in the [issues](../../issues). Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[GPL-3.0-or-later](LICENSE).
