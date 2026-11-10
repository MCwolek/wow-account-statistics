# Forget stays manual

Characters deleted on the character select screen stay Tracked Characters until the player Forgets them from the Statistics window's dropdown. The add-on cannot tell that a Character was deleted: add-ons do not run on character select, and no in-world API lists the Account's Characters safely.

## Considered Options

- **`C_Housing.RequestPlayerCharacterList()`**, which answers with `PLAYER_CHARACTER_LIST_UPDATED` and every Character's GUID, would let the add-on spot Tracked Characters missing from the list on login and offer to Forget them. Blizzard's own UI calls it only from the house settings. Probed in game on 2026-11-10 (#7, commit be0fc5f): calling it in the world, away from housing, disconnected the client from the server (WOW51900319). Rejected: an add-on must not risk a disconnect, least of all on every login. Revisit only if Forever adds a safe way to list the Account's Characters.
