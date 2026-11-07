# Forever Account Stats

A World of Warcraft: Forever add-on that shows the in-game Statistics of every character on one account side by side, plus their combined totals.

## Language

### Characters

**Account**:
One WoW game account, the scope within which characters are combined.
_Avoid_: Battle.net account, Warband

**Character**:
A player character on the Account, identified by its Full Name.
_Avoid_: Alt, toon, char

**Full Name**:
A Character's First Name plus Surname (e.g. "Calgan Blackbeard"); unique within a region and ruleset.
_Avoid_: Name (when only the First Name is meant)

**Surname**:
The second part of a Character's Full Name. Not a realm.
_Avoid_: Last name, realm

**Tracked Character**:
A Character that has been logged in at least once with the add-on enabled. Only Tracked Characters appear in the add-on.

### Statistics

**Statistic**:
One entry of the game's Statistics panel, such as "Total deaths" or "Times camped".
_Avoid_: Stat, achievement

**Category**:
A named group of Statistics as shown in the game's Statistics panel (e.g. Character, Combat); may contain nested Categories.
_Avoid_: Section, group

**Account Total**:
The combined value of one Statistic across all Tracked Characters: a sum, except for Peak Statistics.
_Avoid_: Aggregate, overall, total stats

**Peak Statistic**:
A Statistic whose Account Total is the highest value among Tracked Characters rather than their sum (e.g. "Largest hit dealt").
_Avoid_: Max stat, record

### Syncing

**Snapshot**:
The saved Statistic values of one Tracked Character, taken at one moment.
_Avoid_: Scan, cache, backup

**Sync**:
Taking a new Snapshot of the logged-in Character, on login, logout or UI reload.
_Avoid_: Scan, refresh, update

**Last Synced**:
The time of a Tracked Character's most recent Snapshot.

**Forget**:
Removing a Tracked Character and its Snapshot, so it no longer counts in Account Totals.
_Avoid_: Delete (that is what the player does to the Character in-game), remove, purge
