# Changelog #

## 1.0.12 ##
* Some optimization
* An attempt to fix the bug where physics messes up. (Currently I haven't been able to find a way to reproduce the bug.)

## 1.0.11 ##
* Forgot to fix one bug in the last update...
* Updated the menu, teams are now shown more properly (before they got cut off, due to an offset being too high)

## 1.0.10 ##
* Fixed all saving related issues (that have been reported). Everyone is recommended to upgrade to this version.

## 1.0.9 ##
* Removed a piece of code which didn't work that I forgot to take out in the last release.
* Fixed some weapon bases being able to shoot through the gate.

## 1.0.8 ##
* Attempted to fix a bug causing saved gates to not spawn

## 1.0.7 ##
* Added support for usergroup whitelist on non-admin gates (As suggested by [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ ))
	* This currently supports ULX/ULib usergroups, default gmod usergroups, Exsto, and Evolve
* Fixed a bug with weapons used for bypassing

## 1.0.6 ##
* Fixed a problem with M9K
	* Changed damagetype check to blacklist instead of whitelist
	* Using bit.band instead of equals to decide whether or not the damagetype was used
* Improved the check that decides whether or not a player should collide

## 1.0.5 ##
* Swatted another bug

## 1.0.4 ##
* Fixed a few bugs that I forgot in the last update
* Added toolgun to spawn gates

## 1.0.3 ##
* Added support for changing a gate between server and player owned (Admin only)
* Added support for [CPPI](http://facepunch.com/showthread.php?488410-Common-Prop-Protection-Interface-%28CPPI%29-v1.1 "CPPI On facepunch") when switching a gate between server and player ownership.
* Added weapons that allow players to bypass gates. (As suggested by [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ "PwndKilleds Steam Profile"))
	* One intended for admin use _(can only be spawned by admins, but in e.g. DarkRP can be given with a job)_ that allows any player that has the swep equipped to bypass any gate (depending on the server configurations).
	* One with a keypad-cracker style to it, after X seconds (4 by default) of attempting to bypass (left clicking on a gate), the player can pass through that gate, for y seconds (default 2).
* Added support for UTime restrictions. (As suggested by [Segeco](http://steamcommunity.com/profiles/76561198121585279 "Segecos Steam Profile"))
* Made the gates breakable. (As suggested by [BobTheMightyMan](http://steamcommunity.com/profiles/76561198080472902 "BobTheMightyMans Steam Profil"))
	* NOTE: This must be enabled through the config.lua file

## 1.0.2 ##
* Added ULX/ULib group support, this will only activate if ULib is installed. (As suggested by [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ "PwndKilleds Steam Profile") and [Segeco](http://steamcommunity.com/profiles/76561198121585279 "Segecos Steam Profile")
* Added the ability to allow certain SteamIDs. (As suggested by [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ "PwndKilleds Steam Profile"))
* Fixed a bug with the combine fence when in the right to left orientation

## 1.0.1 ##
* Fixed a few bugs that I somehow missed before the release.
* Added configuration options to enable (and disable) saving for Team Gates spawned by non-admins (As suggested by [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ "PwndKilleds Steam Profile")).
* Non-admins can now edit the settings of their own Team Gates.

## 1.0.0 ##
* Initial release
