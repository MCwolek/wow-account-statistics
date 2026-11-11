# The Minimap button is the add-on's own

The Minimap button is a plain Button the add-on creates on the Minimap, with its angle and whether it is shown saved in `AccountStatisticsDB.minimapButton`. It does not use LibDBIcon or LibDataBroker, so the add-on ships no embedded library and does not have to keep one updated for Forever's client. The trade-off: players who use a LibDataBroker display add-on (a data bar or a Minimap button bag) get no launcher (LibDataBroker's term for a data object that opens something) for the Statistics window there; they have the Minimap button and /stats.

## Considered Options

- **LibDBIcon with a LibDataBroker launcher** would make the button behave like many add-ons' Minimap buttons and let LibDataBroker display add-ons show it too. Rejected for now: it embeds LibStub, CallbackHandler, LibDataBroker and LibDBIcon in the add-on, to be kept updated for one button. Revisit if players ask for the launcher in their LibDataBroker display.
