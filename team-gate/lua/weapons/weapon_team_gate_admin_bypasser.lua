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

SWEP.PrintName 		= "(Admin) Gate Bypasser"
SWEP.Author 		= "Rynoxx"
SWEP.Instructions 	= "Equip it and walk through (almost) all gates.\nThe exceptions being gates where the bypassing has been disabled by an admin or if bypassing is disabled in the config."
SWEP.Purpose 		= "Bypassing team gates"

SWEP.Spawnable 		= true
SWEP.AdminOnly 		= true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo 			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= true

SWEP.Slot				= 5
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true

SWEP.ViewModel			= ""
SWEP.WorldModel			= ""

function SWEP:Deploy()
	if !RynGateConfig.SWEPBypassGates then
		self.Owner:ChatPrint("Gate bypassing has been disabled in the server configuration. This weapon is useless...")
	end
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end
