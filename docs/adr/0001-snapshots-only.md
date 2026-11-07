# Statistics come only from in-game Snapshots

The WoW add-on API reads Statistics of the logged-in Character only, so each Tracked Character saves a Snapshot to account-wide SavedVariables when it Syncs (login, logout, UI reload), and the add-on combines those Snapshots. A Character therefore appears only after it has been logged in once with the add-on enabled, and its values are as fresh as its Last Synced.

## Considered Options

- **Blizzard's web API** (`/profile/wow/character/{realm}/{name}/achievements/statistics`) would cover Characters never logged in with the add-on, but add-ons cannot make HTTP requests. It would need a separate desktop companion with Battle.net OAuth that writes into the add-on's files, and it is unverified whether the endpoint covers WoW: Forever at all. Rejected as out of proportion for the first version; revisit only if "Characters never logged in" becomes a real pain.
- **A periodic timer or a "scan all" button** cannot reach other Characters either; for the logged-in Character, the add-on reads Statistics live instead.
