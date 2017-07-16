--[[
Allows creation of walls/gates that are only certain players can go through.
Copyright (C) 2017  Rynoxx

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

--- RynGateConfig.SaveFileName (Default: "rynoxx_team_gates") 
-- The name of the file that the gates are saved in, can only include characters that are allowed in Windows/Linux file names.
-- Using a "/" will create a new folder, e.g "gates/team_gates" will create the folder gates and save the gates in a file called team_gates
RynGateConfig.SaveFileName = "rynoxx_team_gates"

--- RynGateConfig.NonAdminsCanSpawn (Default: false)
-- Should non-admins be allowed to spawn gates?
RynGateConfig.NonAdminsCanSpawn = false

--- RynGateConfig.UsergroupWhitelist (Default: {})
-- Specify a list of groups that will be able to spawn the gates (that aren't admins)
-- Leave this as default to allow all non-admin groups to spawn (Do note that RynGateConfig.NonAdminsCanSpawn has to be set to true for this to work)
-- This supports ULX/ULib usergroups, default gmod usergroups, Exsto, and Evolve
RynGateConfig.UsergroupWhitelist = {}

--- RynGateConfig.SaveNonAdminGates (Default: false)
-- Should gates spawned by non-admins be saved? (Respawn after cleanup, server restart, etc.)
-- NOTE: The ownership of the prop can not be guaranteed to work after a cleanup or server restart.
-- (In most cases it -should- work, as it's using a standardized interface for prop protection)
RynGateConfig.SaveNonAdminGates = false

--- RynGateConfig.CanBreak (Default: false)
-- Can gates be broken?
-- Do note that this disables the "CanShootThrough" property. (CanBreakAdmin has to be enabled to automaticly disable the CanShootThrough on the server owned gates)
-- And will allow only those who can pass through the gates to shoot through it
-- Having this as faults overrides the RynGateConfig.CanBreakAdmin value
RynGateConfig.CanBreak = false

--- RynGateConfig.CanBreakAdmin (Default: false)
-- Can server owned gates be broken?
RynGateConfig.CanBreakAdmin = false

--- RynGateConfig.BreakDuration (Default: 6)
-- For how long should a gate be broken? (In seconds)
RynGateConfig.BreakDuration = 6

--- RynGateConfig.GateHealth (Default: 200)
-- How much HP should the gate have?
RynGateConfig.GateHealth = 200

--- RynGateConfig.DisallowedDamageTypes (Default: {DMG_CRUSH, DMG_PHYSGUN, DMG_RADIATION})
-- Which damagetypes shouldn't be allowed to damage the gate(s)
-- For a list of damagetypes, look at the wiki ( http://wiki.garrysmod.com/page/Enums/DMG )
-- Do not edit this unless you know what you're doing
RynGateConfig.DisallowedDamageTypes = {DMG_CRUSH, DMG_PHYSGUN, DMG_RADIATION}

--- RynGateConfig.SpawnLimit (Default: 4)
-- How many gates can be spawned by one player?
-- By default, this only applies to regular players, not admins (Can be changed below)
RynGateConfig.SpawnLimit = 4

--- RynGateConfig.SpawnLimitAdmins (Default: true)
-- Whether or not admins should be affected by the SpawnLimit defined above. (Doesn't affect server owned gates)
RynGateConfig.SpawnLimitAdmins = true

--- RynGateConfig.SWEPBypassRange (Default: 80)
-- How far away should the player be able to stand when attempting to bypass a gate?
RynGateConfig.SWEPBypassRange = 80

--- RynGateConfig.SWEPBypassWaitTime (Default: 4)
-- The time it takes for the non-admin swep to bypass a gate
RynGateConfig.SWEPBypassWaitTime = 4

--- RynGateConfig.SWEPBypassDuration (Default: 2)
-- For how long a gate will be bypassed for a certain player
RynGateConfig.SWEPBypassDuration = 2

--- RynGateConfig.SWEPBypassGates (Default: true)
-- Wether or not any Team Gates spawned can be bypassed by the Gate Bypasser SWEP
-- Do note that leaving this as false overrides the SWEPBypassServerGates and AdminSWEPBypassServerGates settings
RynGateConfig.SWEPBypassGates = true

--- RynGateConfig.SWEPBypassServerGates (Default: false)
-- Wether or not Team Gates spawned that belongs to the server can be bypassed by the regular Gate Bypasser SWEP
RynGateConfig.SWEPBypassServerGates = false

--- RynGateConfig.SWEPBypassServerGates (Default: false)
-- Wether or not Team Gates spawned that belongs to the server can be bypassed by the Admin Gate Bypasser SWEP
RynGateConfig.AdminSWEPBypassServerGates = false

--- RynGateConfig.DefaultCanShootThrough (Default: true)
-- Can be true or false
-- Whether or not ALL players should be able to shoot through the gates by default (This is configurable in each gate)
-- Do note that this will be disabled by RynGateConfig.CanBreak
RynGateConfig.DefaultCanShootThrough = true

--- RynGateConfig.DefaultTextAlignment (Default: 3)
-- Valid values: 1 (Left), 2 (Center), 3 (Right)
-- The default alignment of the text entered for a gate.
RynGateConfig.DefaultTextAlignment = 2

--- RynGateConfig.MaxTextScale (Default: 4)
-- The maximum scale the gate texts can have
RynGateConfig.MaxTextScale = 5

--- RynGateConfig.MinTextScale (Default: 0.5)
-- The minimum scale the gate texts can have
RynGateConfig.MinTextScale = 0.5

--- RynGateConfig.DefaultTextScale (Default: 2)
-- A number between RynGateConfig.MinTextScale and RynGateConfig.MaxTextScale
-- The default scale of the text on the gates
RynGateConfig.DefaultTextScale = 2

--- RynGateConfig.DefaultTextShouldFade (Default: true)
-- Can be true or false
-- Wether or not the text on the gates should fade over distance by default (This is configurable in each gate)
RynGateConfig.DefaultTextShouldFade = true

--- RynGateConfig.DefaultTextFadeDistance (Default: 512)
-- A number above 0
-- The distance at which the text should start to fade away
RynGateConfig.DefaultTextFadeDistance = 512

--- RynGateConfig.DefaultDermaSkin (Default: "Default")
-- The derma skin to use for the panel
RynGateConfig.DefaultDermaSkin = "Default"

--- RynGateConfig.OverrideDarkRPDerma (Default: false)
-- Can be true or false
-- Should the derma skin above override the DarkRP derma skin? (If used on a DarkRP server)
RynGateConfig.OverrideDarkRPDerma = false

--- RynGateConfig.SaveInterval (Default: 30)
-- Any integer above 0, I don't recommend anything below 10
-- How many seconds between each auto-save?
RynGateConfig.SaveInterval = 30

--- RynGateConfig.DefaultAlpha (Default: 80)
-- Integer between 0 and 100 (including 0 and 100)
-- The alpha (how opaque the team gate is) in percentage
RynGateConfig.DefaultAlpha = 80

--- RynGateConfig.MenuSize (Default: {width = 1024, height = 864})
-- The width and height of the Team Gate menu
-- If you don't plan on editing the menu, leave this as default
RynGateConfig.MenuSize = {
	width = 1280,
	height = 864
}

--- RynGateConfig.MaxPlayTime (Default: 1000)
-- The max amount of "minimum playtime" that can be specified (in hours) in the RynGateMenu
RynGateConfig.MaxPlaytime = 1000

--- RynGateConfig.ModelIconSize (Default: 64)
-- Any integer above 1. I recommend keeping this as default
-- I can not guarantee that the menu looks good if you change this.
-- The size of the model icons (in the model selection)
RynGateConfig.ModelIconSize = 64

--- RynGateConfig.MaterialIconSize (Default: 96)
-- Any integer above 1. I recommend keeping this as default
-- I can not guarantee that the menu looks good if you change this.
-- The size of the material icons (in the material selection)
RynGateConfig.MaterialIconSize = 96

--- RynGateConfig.DefaultModelIndex (Default: 22 (4x4 plate))
-- Must be above 0 and can't be higher than the amount of indexes in the ModelList, which by default has 36 indexes
-- I recommend that you only edit this if you know how arrays/tables work.
-- The index of the default model in the model list
RynGateConfig.DefaultModelIndex = 22

--- RynGateConfig.ModelList (Default: Too long to put here, check the files you've downloaded.)
-- I recommend that you only edit this if you know how arrays/tables work.
-- Also do note that currently the angles and positions for combine fences and the text are partly hard coded to work with these models.
-- A list of the models that should be selectable in the menu.
RynGateConfig.ModelList = {
	"models/hunter/plates/plate1x1.mdl",
	"models/hunter/plates/plate1x2.mdl",
	"models/hunter/plates/plate1x3.mdl",
	"models/hunter/plates/plate1x4.mdl",
	"models/hunter/plates/plate1x5.mdl",
	"models/hunter/plates/plate1x6.mdl",
	"models/hunter/plates/plate1x7.mdl",
	"models/hunter/plates/plate1x8.mdl",
	"models/hunter/plates/plate1x16.mdl",
	"models/hunter/plates/plate1x24.mdl",
	"models/hunter/plates/plate1x32.mdl",
	"models/hunter/plates/plate2x2.mdl",
	"models/hunter/plates/plate2x3.mdl",
	"models/hunter/plates/plate2x4.mdl",
	"models/hunter/plates/plate2x5.mdl",
	"models/hunter/plates/plate2x6.mdl",
	"models/hunter/plates/plate2x7.mdl",
	"models/hunter/plates/plate2x8.mdl",
	"models/hunter/plates/plate2x16.mdl",
	"models/hunter/plates/plate2x24.mdl",
	"models/hunter/plates/plate2x32.mdl",
	"models/hunter/plates/plate3x3.mdl",
	"models/hunter/plates/plate3x4.mdl",
	"models/hunter/plates/plate3x5.mdl",
	"models/hunter/plates/plate3x6.mdl",
	"models/hunter/plates/plate3x7.mdl",
	"models/hunter/plates/plate3x8.mdl",
	"models/hunter/plates/plate3x16.mdl",
	"models/hunter/plates/plate3x24.mdl",
	"models/hunter/plates/plate3x32.mdl",
	"models/hunter/plates/plate4x4.mdl",
	"models/hunter/plates/plate4x5.mdl",
	"models/hunter/plates/plate4x6.mdl",
	"models/hunter/plates/plate4x7.mdl",
	"models/hunter/plates/plate4x8.mdl",
	"models/hunter/plates/plate4x16.mdl",
	"models/hunter/plates/plate4x24.mdl",
	"models/hunter/plates/plate4x32.mdl",
	"models/hunter/plates/plate5x5.mdl",
	"models/hunter/plates/plate5x6.mdl",
	"models/hunter/plates/plate5x7.mdl",
	"models/hunter/plates/plate5x8.mdl",
	"models/hunter/plates/plate5x16.mdl",
	"models/hunter/plates/plate5x24.mdl",
	"models/hunter/plates/plate5x32.mdl",
	"models/hunter/plates/plate6x6.mdl",
	"models/hunter/plates/plate6x7.mdl",
	"models/hunter/plates/plate6x8.mdl",
	"models/hunter/plates/plate6x16.mdl",
	"models/hunter/plates/plate6x24.mdl",
	"models/hunter/plates/plate6x32.mdl",
	"models/hunter/plates/plate7x7.mdl",
	"models/hunter/plates/plate7x8.mdl",
	"models/hunter/plates/plate7x16.mdl",
	"models/hunter/plates/plate7x24.mdl",
	"models/hunter/plates/plate7x32.mdl",
	"models/hunter/plates/plate8x8.mdl",
	"models/hunter/plates/plate8x16.mdl",
	"models/hunter/plates/plate8x24.mdl",
	"models/hunter/plates/plate8x32.mdl",
	"models/hunter/plates/plate16x16.mdl",
	"models/hunter/plates/plate16x24.mdl",
	"models/hunter/plates/plate16x32.mdl"
}
