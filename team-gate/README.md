# Rynoxx's Team Gates #

**Should work with any gamemode. But there is still a possibility that there can be some compatability issues.**  
_Teams will only work if the gamemode is using the default team system in Garry's Mod_

This is a system that allows players to spawn a gate which can be customised to allow only certain people (by team, ULX/ULib Group, SteamID), vehicles and NPCs through it.  
I've tried to make the system as feature-rich by default as I could, but it allows for further customisation through hooks.  
Very few values are hardcoded and values that aren't can be configured _(Those that aren't can be found in the entity files themselves, however I can't guarantee the quality of the system staying the same if you modify any file but the config.lua)_ through the config.lua file included (located in team-gates/lua/entities/ent_ryn_team_gate/).  
Further configuration of the gates can be done on a gate-by-gate basis by pressing E on a gate (if you're the one who spawned it, or if you're an admin pressing E on a non-personal team gate).
The gates are respawned after cleanup, map change and server restart, however, the gates are only saved to one map (e.g. spawning a gate on gm_construct wont spawn the same gate if you change to gm_flatgrass).  

The gates can be bypassed using weapons _(this can be disabled in the config.lua file)_, currently there's two weapons with two different goals.  
One intended for admin use _(can only be spawned by admins, but in e.g. DarkRP can be given with a job)_ that allows any player that has the swep equipped to bypass any gate (depending on the server configurations).  
One with a keypad-cracker style to it, after X seconds (4 by default) of attempting to bypass (left clicking on a gate), the player can pass through that gate, for y seconds (default 2).  

Do note that the menu uses the default Garry's Mod derma skin (or DarkRP if it's used on a DarkRP server and the configuration isn't set to do otherwise) and every player can change the derma skin that they want their panel to use to any loaded derma skin.

A video demonstration of the addon is available on [Youtube](http://youtu.be/_bSOgi1ogT8 "Video on youtube").  
_Do note that the video shows the 1.0.1 version of the addon, newer version include updates to the menu_


[Steam Workshop page](http://steamcommunity.com/sharedfiles/filedetails/?id=1073652620)

---------------------------------------

## Table of Content ##
1. [Guide](#guide)
2. [Use Cases](#use-cases)
3. [Copyright](#copyright)
4. [Credits](#credits)
5. [Hooks](#hooks)
6. [Todo](#todo)

---------------------------------------

## Guide ##

* To install, simply extract the zip file to your addons folder (the team-gate folder should be inside garrysmod/addons/).
And then restart your server.
* As the system allows quite extensive configuration, make sure you check the config.lua file to see if there's something you want to change before using the gates.
* After installation the team gate can be spawned in three different ways
	* Through the entities tab in the Q menu, in the "Rynoxx" category click on the "Team Gate" entity.
	* Through a toolgun
	* Through a console command: `rynteamgate_spawn`
* After you've spawned a Team Gate you can configure it by pressing the interact/use key (Default E) on it
	* Team gates are automatically saved and will respawn after cleanup, map change and server restart
	* All team gates are saved on a per-map basis (e.g. spawning a gate on gm_construct wont spawn the same gate on gm_flatgrass after a map change)  

---------------------------------------

## Use Cases ##
* Creating a vehicle-free zone
* Creating zones for certain teams
	* Could be used as spawn areas
	* Some kind of gang zone
* Creating an admin room/area
* NPC safe zone (on e.g. a zombie map)
* Creating combine fences (e.g. for HL2RP) _(comes with the option to automatically put combine fences on gates)_

---------------------------------------

## Credits ##

* [Rynoxx](http://steamcommunity.com/profiles/76561198004177027 "Rynoxx' Steam Profile"): Coding
* [Ice Dragon](http://steamcommunity.com/profiles/76561197987470469/ "Ice Dragons Steam Profile"): Ideas
* [PwndKilled](http://steamcommunity.com/profiles/76561198103106152/ "PwndKilleds Steam Profile"): Suggestions

---------------------------------------

## Hooks ##

For those interested in attempting to develop further extensions of this addon, these are currently the hooks available:

### Hooks that you can call: ###
* RynGates_SaveAll
	* Saves all gates
	* Server side (Nothing happens if called on the client)


* RynGates_Save
	* Saves one team gate
	* Parameters:
		* gate - The gate that should be saved.
	* Server side (Nothing happens if called on the client)

---------------------------------------

### Hooks that get called: ###
_Yes, these can be called manually if you feel the need to get the result of them_

* RynGates_IsAllowedEnt
	* Checks whether or not an entity will be tested for collision
	* Parameters:
		* ent - The entity that is being tested
	* Should return:
		* Boolean - Whether or not the entity is passes the check. (By default Players, NPCs and vehicles are the only ones that passes this test)
	* Shared, can (and will be) called on both server and client (when called by the system, otherwise it stays on the side it's called on)


* RynGates_ShouldPlayerCollide
	* Checks whether or not a certain player should collide with the gate
	* Parameters:
		* ent - The gate
		* ply - The player
		* MaxDist - The highest number in return by the ent:GetCollisionBounds(), times 1.3
	* Should return:
		* Boolean - Whether or not the player will collide
	* Shared, can (and will be) called on both server and client (when called by the system, otherwise it stays on the side it's called on)


* RynGates_ShouldNPCCollide
	* Checks whether or not a certain NPC should collide with the gate
	* Parameters:
		* gate - The gate
		* ent - The NPC
		* dist - The distance between the gate and the NPC
		* MaxDist - The highest number in return by the ent:GetCollisionBounds(), times 1.3
	* Should return:
		* Boolean - Whether or not the NPC will collide
	* Shared, can (and will be) called on both server and client (when called by the system, otherwise it stays on the side it's called on)


* RynGates_ShouldVehicleCollide -- self, ent, dist, MaxDist
	* Checks whether or not a certain vehicle should collide with the gate
	* Parameters:
		* gate - The gate
		* ent - The vehicle
		* dist - The distance between the gate and the vehicle
		* MaxDist - The highest number in return by the ent:GetCollisionBounds(), times 1.3
	* Should return:
		* Boolean - Whether or not the vehicle will collide with the gate
	* Shared, can (and will be) called on both server and client (when called by the system, otherwise it stays on the side it's called on)


* RynGates_CustomCollisionCheck
	* Checks whether or not an entity/prop should collide with the gate (The entity must have passed the RynGates_IsAllowedEnt first)
		* Only entities/props that aren't Players, NPCs or vehicles will come through this hook.
	* Parameters:
		* gate - The gate
		* ent - The entity
		* dist - The distance between the gate and the vehicle
		* MaxDist - The highest number in return by the ent:GetCollisionBounds(), times 1.3
	* Should return:
		* Boolean - Whether or not the entity will collide with the gate
	* Shared, can (and will be) called on both server and client (when called by the system, otherwise it stays on the side it's called on)


* RynGates_Draw
	* A hook called from inside the draw hook of the gate
	* Parameters:
		* gate - The gate
	* Should return:
		* Void - There's no return value needed.
	* Client side, will only be called on the client

---------------------------------------

## TODO ##
* Only collide with certain people (ShouldCollide) -- **DONE**
	* NPC -- **DONE**
	* Vehicles -- **DONE**
	* ULX/ULib group Support -- **DONE**
	* SteamID support -- **DONE**
	* SWEP to bypass (One admin walk through all gates by simply equipping the swep, one non-admin acting more similarly to the Keypad Cracker) -- **DONE**
* Open menu when E is pressed on the entity -- **DONE**
	* Check boxes for all the teams -- **DONE**
	* Model selection/text field -- **DONE**
	* Material selection -- **DONE**
	* Color selection -- **DONE**
	* Can/Should shoot through -- **DONE**
	* Combine Fence decorations -- **DONE**
	* Text/Label Editor -- **DONE**
		* Position -- **DONE**
		* Text Alignment -- **DONE**
		* Color -- **DONE**
	* "Allow Vehicles" -- **DONE**
		* Team check, only driver? -- _Currently only on the driver_
	* "Allow (ALL) NPCs" -- **DONE**
	* Alpha Selection -- **DONE**
* Save door/gates to file -- **DONE**
* Add Copyright info to every file -- **DONE**
* Add hooks -- **DONE**
	* Add even more hooks -- **DONE** _There's basically a hook for every custom function_
* Add check for self maxs.x - entPos.x, self maxs.y - entPos.y, etc in shared.lua for a collision calculation with higher precision
* Allow admins to spawn non-server owned gates -- **DONE**
* Allow admins to set their personal gates to server owned gates -- **DONE**
* Add STool to spawn gates -- **DONE**
	* More suggestions for the STool would be nice
* Spawn Limit -- **DONE**
* Breakable -- **DONE**
