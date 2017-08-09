## Transfer Ownership ##

### This addon requires that you're using a prop protection addon that is CPPI compliant ###
Examples of popular prop protection addons which are CPPI compliant:
* [Falco Prop Protection](http://steamcommunity.com/sharedfiles/filedetails/?id=133537219) (Comes with DarkRP)
* [Simple Prop protection](http://steamcommunity.com/sharedfiles/filedetails/?id=145061455)
* [Nadmod Prop Protection](http://steamcommunity.com/sharedfiles/filedetails/?id=159298542)

Allows players to transfer ownership of selected entities to another player.
The ownership transfer can be undone using the "Undo" button in-game

Use the convar `transfer_ownership_check_ownership` to choose whether to check strictly against the owner of the prop (`1`) or if the player has permission to use toolgun on the prop (`0`). The latter is useful for cases where you want the players to change the ownership of their friends props.

The convar `transfer_ownership_admin_check_ownership` is the same as above, but only applies to admins so that admins can change ownership of players props or disconnected players props. This convar is ignored if the above is set to `0`.

The convar `transfer_ownership_admin_usergroup` sets which usergroup that should take advantage of the above admin check.
E.g. `transfer_ownership_admin_usergroup "superadmin"` allows only superadmins (and on ULX, exsto and AssMod any group that inherits from it. "admin" and "superadmin" will use the IsAdmin and IsSuperAdmin checks respectively.)

[Steam Workshop page](http://steamcommunity.com/sharedfiles/filedetails/?id=1078491590)
