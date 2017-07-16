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

SWEP.PrintName 		= "Gate Bypasser"
SWEP.Author 		= "Rynoxx"
SWEP.Instructions 	= "Left click to start attempting to bypass the teamgate you're looking at.\nThe exceptions being gates where the bypassing has been disabled by an admin or if bypassing is disabled in the config."
SWEP.Purpose 		= "Bypassing team gates"

SWEP.Spawnable 		= true
SWEP.AdminOnly 		= false

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
SWEP.Dots				= ""

function SWEP:Deploy()
	if !RynGateConfig.SWEPBypassGates then
		self.Owner:ChatPrint("Gate bypassing has been disabled in the server configuration. This weapon is useless...")
	end
end

function SWEP:PrimaryAttack()
	--if CLIENT then return end

	local tr = self.Owner:GetEyeTrace()
	local gate = tr.Entity
	local hitPos = tr.HitPos
	if IsValid(gate) and gate:GetClass() == ent_gate_ClassName and RynGateConfig.SWEPBypassGates and self.Owner:EyePos():Distance(hitPos) <= RynGateConfig.SWEPBypassRange then
		if gate:GetIsServerOwned() and !RynGateConfig.SWEPBypassServerGates then
			self.Owner:ChatPrint("You can't bypass gates owned by the server with this weapon.")
			return
		end

		self.Owner:SetNWBool("RynGates_Bypassing", true)
		self.Owner:SetNWInt("RynGates_BypassStarted", CurTime())
		self.Owner:SetNWEntity("RynGates_BypassEntity", gate)

		local ply = self.Owner

		timer.Simple(RynGateConfig.SWEPBypassWaitTime, function()
			if IsValid(ply) and ply:GetNWBool("RynGates_Bypassing", false) then
				ply:SetNWBool("RynGates_Bypassing", false)
				self.Owner:SetNWInt("RynGates_BypassFinished", CurTime())
			end
		end)
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
	if SERVER and IsValid(self.Owner) then
		if self.Owner:GetNWBool("RynGates_Bypassing", false) then
			if self.Owner:GetEyeTrace().Entity != self.Owner:GetNWEntity("RynGates_BypassEntity") then
				self.Owner:SetNWBool("RynGates_Bypassing", false)
			end
		end
	end
end

local draw = draw

function SWEP:DrawHUD()
	if self.Owner:GetNWBool("RynGates_Bypassing", false) then
		local bypassStarted = self.Owner:GetNWInt("RynGates_BypassStarted", CurTime())

		local timeLeft = CurTime() - bypassStarted

		local scrw, scrh = ScrW(), ScrH()
		local w, h = scrw * 0.2, scrh * 0.1
		local offset = 4

		draw.RoundedBox(6, scrw/2 - w/2 - offset/2, scrh/2 - h/2 - offset/2, w + offset, h + offset, Color(0, 0, 0, 200))
		draw.RoundedBox(6, scrw/2 - w/2, scrh/2 - h/2, w * math.Clamp(timeLeft/RynGateConfig.SWEPBypassWaitTime, 0, 1), h, Color(0, 250, 0, 200))

		if string.len(self.Dots) > 3 then
			self.Dots = ""
		end

		if (self.lastTime or 0) != os.time() then
			self.Dots = self.Dots .. "."
			self.lastTime = os.time()
		end

		draw.SimpleText("Bypassing" .. self.Dots .. " " .. math.floor(timeLeft) .. "/" .. RynGateConfig.SWEPBypassWaitTime, "BudgetLabel", scrw/2, scrh/2, color_white, TEXT_ALIGN_CENTER)
	end
end
