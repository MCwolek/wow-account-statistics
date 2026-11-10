# The add-on follows the game's language

The add-on's own text (buttons, labels, tooltips, chat lines) is in the game's text language, as `GetLocale()` reports it when the add-on loads, with English for any text a translation lacks and for every language without one. The add-on has no language setting of its own. The trade-off: a player cannot read the add-on in another language than the client; in return there is nothing to configure, and the Statistic and Category names, which come from the client, always match the add-on's own text.

Of the add-ons installed in the user's Forever client (checked for #9), ForeverAuras, Auctionator and AtlasLoot follow `GetLocale()` alone; only Questie also offers a language switch in its options.

## Considered Options

- **A language switch in the add-on** (as Questie has) would let a player pick the add-on's language apart from the client's. Rejected: it adds a setting and its storage, and mixes languages in one window, since Statistic and Category names stay in the client's. Revisit if players ask for it.
