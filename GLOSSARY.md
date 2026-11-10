# Forever Account Stats

A World of Warcraft: Forever add-on that shows the in-game Statistics of every character on one account side by side, plus their combined totals.

## Language

### Characters

**Account**:
One WoW game account, the scope within which characters are combined.
_Avoid_: Battle.net account, Warband

**Character**:
A player character on the Account, identified by its GUID and shown by its Full Name.
_Avoid_: Alt, toon, char

**Full Name**:
A Character's First Name plus Surname (e.g. "Calgan Blackbeard"); unique within a region and Ruleset, so the same Full Name can appear once per Ruleset.
_Avoid_: Name (when only the First Name is meant)

**Surname**:
The second part of a Character's Full Name. Not a realm.
_Avoid_: Last name, realm

**Ruleset**:
The rules a Character plays under, such as PvE, PvP or RP. On Forever each Ruleset is one realm per region, and the add-on reads it as the last word of the realm name ("CAMWOW EU4 Realm 5 PvE" is PvE).
_Avoid_: Realm, server

**Tracked Character**:
A Character that has been logged in at least once with the add-on enabled. Only Tracked Characters appear in the add-on.

**Roster**:
Every Tracked Character in order of Full Name and Ruleset, the logged-in one marked, each with its Last Synced ("now" for the logged-in Character). The Character dropdown, /stats list, /stats dump and the Breakdown all take their Characters from it.
_Avoid_: Character list

### Statistics

**Statistic**:
One entry of the game's Statistics panel, such as "Total deaths" or "Times camped".
_Avoid_: Stat, achievement

**Category**:
A named group of Statistics as shown in the game's Statistics panel (e.g. Character, Combat); may contain nested Categories.
_Avoid_: Section, group

**Account Total**:
The combined value of one Statistic across all Tracked Characters, whatever their Ruleset: a sum, except for Peak Statistics. Text Statistics and Average Statistics have none, and neither does any Statistic whose value reads as text.
_Avoid_: Aggregate, overall, total stats

**Breakdown**:
The tooltip on a Statistic with an Account Total in the Statistics window: the top 5 Tracked Characters' values of that Statistic, highest first, with "--" and "?" last.
_Avoid_: Details, per-character list

**Peak Statistic**:
A Statistic whose Account Total is the highest value among Tracked Characters rather than their sum (e.g. "Largest hit dealt").
_Avoid_: Max stat, record

**Text Statistic**:
A Statistic whose value is a count with a label, such as "Creature type killed the most" reading "62 (Beasts)"; hand-picked by Statistic ID (the "… most" Statistics), since each reads "--" until its first count. It has no Account Total.
_Avoid_: Label stat, string stat

**Average Statistic**:
A Statistic that is one Character's daily average (e.g. "Average quests completed per day"), hand-picked by Statistic ID; summing them overstates, so it has no Account Total.
_Avoid_: Rate, per-day stat

**Statistics window**:
The add-on's own window, opened with /stats or the button on the default UI's Statistics tab: every Statistic by Category, with the value of the Character chosen in its dropdown and the Account Total. Its search box narrows the list to the Statistics and Categories whose name matches.
_Avoid_: Main window, frame, Statistics panel (that is the game's own)

**Window Session**:
What the Statistics window remembers from opening to closing: the expanded Categories, the search, the Character chosen in its dropdown and the Live Values. Each open starts a new one, with every Category expanded, on the logged-in Character and with no search; closing forgets it.
_Avoid_: Window state, view state

### Syncing

**Snapshot**:
The saved Statistic values of one Tracked Character, taken at one moment.
_Avoid_: Scan, cache, backup

**Live Values**:
The logged-in Character's Statistic values read just now, never saved. The Statistics window counts them in place of its Snapshot; /stats dump shows only Snapshots.
_Avoid_: Current values, live snapshot

**Sync**:
Taking a new Snapshot of the logged-in Character, on login, logout or UI reload. A Sync that reads no Statistic values (none at all, or every one "--") keeps the earlier Snapshot and Last Synced.
_Avoid_: Scan, refresh, update

**Last Synced**:
The time of a Tracked Character's most recent Snapshot.

**Forget**:
Removing a Tracked Character and its Snapshot, so it no longer counts in Account Totals.
_Avoid_: Delete (that is what the player does to the Character in-game), remove, purge
