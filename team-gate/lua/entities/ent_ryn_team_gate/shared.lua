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

ENT.Base			= "base_anim"
ENT.Type			= "anim"
ENT.Category		= "Rynoxx"

ENT.PrintName       = "Team Gate"
ENT.Author          = "Rynoxx"
ENT.Contact         = "rynoxx@grid-servers.net"
ENT.Purpose         = "Block areas and restrict them to certain teams"
ENT.Instructions    = "Spawn it and use it to block of areas for certain teams"

ENT.Spawnable 		= true
ENT.AdminOnly 		= false

ent_gate_ClassName = "ent_ryn_team_gate"

RynGateConfig = RynGateConfig or {}

COMBINE_ORIENTATION_DEFAULT = 1
COMBINE_ORIENTATION_NINETY_ROLL = 2

print("This server is using Team Gates by Rynoxx. Source code is available at https://github.com/Rynoxx/gmod-addon-collection")

local table = table
local mmax = math.max
local Color = Color
local utilJtoT = util.JSONToTable

local ulibExists = ULib != nil and ULib.ucl != nil and ULib.ucl.groups != nil

local plyMeta = FindMetaTable( "Player" )
local utimeExists = plyMeta.GetUTime != nil
plyMeta = nil

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "MaxDist")
	self:NetworkVar("Float", 1, "TextPosX")
	self:NetworkVar("Float", 2, "TextPosY")
	self:NetworkVar("Float", 3, "TextScale")
	self:NetworkVar("Float", 4, "CustomAlpha")
	self:NetworkVar("Float", 5, "MinPlayTime")
	self:NetworkVar("Float", 6, "GHealth")
	self:NetworkVar("Int", 0, "GateID")
	self:NetworkVar("Int", 1, "TextAlignment")
	self:NetworkVar("Int", 2, "CombineOrientation")
	self:NetworkVar("Int", 3, "TxtAlpha")
	self:NetworkVar("Int", 4, "BreakTime")
	self:NetworkVar("Vector", 0, "TxtColor")
	self:NetworkVar("Bool", 0, "UseCombineFence")
	self:NetworkVar("Bool", 1, "AllowNPCs")
	self:NetworkVar("Bool", 2, "AllowVehicles")
	self:NetworkVar("Bool", 3, "CanShootThrough")
	self:NetworkVar("Bool", 4, "TextShouldFade")
	self:NetworkVar("Bool", 5, "IsServerOwned")
	self:NetworkVar("Bool", 6, "SWEPCanBypass")
	self:NetworkVar("Bool", 7, "IsBroken")
	--self:NetworkVar("Bool", 8, "CanBreak") -- Disabled for now, might add configurability per gate later
	self:NetworkVar("String", 0, "AllowedTeams")
	self:NetworkVar("String", 1, "OwnerUniqueID")
	self:NetworkVar("String", 2, "Text")
	self:NetworkVar("String", 3, "AllowedSteamIDs")
end

function ENT:GetULibGroups()
	return self:GetNWString("RynGates_ULibGroups", "{}")
end

function ENT:GetTextColor()
	local vecClr = self:GetTxtColor()
	return Color(vecClr.x or 255, vecClr.y or 255, vecClr.z or 255, self:GetTxtAlpha())
end

ENT.SimplifiedSteamIDList = nil

function ENT:GetSimplifiedAllowedSteamIDs()
	if self.SimplifiedSteamIDList != nil then
		return self.SimplifiedSteamIDList
	end

	self.SimplifiedSteamIDList = {}

	local allowedSteamIDs = utilJtoT((self:GetAllowedSteamIDs() != "" and self:GetAllowedSteamIDs()) or "{}")

	for i = 1, table.Count(allowedSteamIDs) do
		if allowedSteamIDs[i].steamid then
			table.insert(self.SimplifiedSteamIDList, allowedSteamIDs[i].steamid)
		end
	end

	return self.SimplifiedSteamIDList
end

local function IsAllowedEnt(ent)
	return IsValid(ent) and (
		ent:IsPlayer() or
		ent:IsNPC() or
		ent:IsVehicle()
	)
end

hook.Add("RynGates_IsAllowedEnt", "RynGates_DefaultIsAllowedEnt", IsAllowedEnt)

local function maxMaxs(maxs)
	return mmax(maxs.x, mmax(maxs.y, maxs.z))
end

local function shouldPlayerCollide(ent, ply, MaxDist)
	if !IsValid(ply) then
		return
	end

	local swep = (ply.GetActiveWeapon and ply:GetActiveWeapon())

	local eyepos = ply:EyePos()
	local plypos = ply:GetPos()
	local entpos = ent:GetPos()

	local dist1 = plypos:Distance(entpos)
	local dist2 = eyepos:Distance(entpos)
	local dist = mmax(dist1, dist2)
	local allowedTeams = utilJtoT((ent:GetAllowedTeams() != "" and ent:GetAllowedTeams()) or "{}")
	local allowedULibGroups = utilJtoT((ent:GetULibGroups() != "" and ent:GetULibGroups()) or "{}")
	local allowedSteamIDs = ent:GetSimplifiedAllowedSteamIDs()

	local ownsEntity = (ply:IsAdmin() and ent:GetIsServerOwned()) or (!ent:GetIsServerOwned() and ply:UniqueID() == ent:GetOwnerUniqueID())

	if (ownsEntity and !ply:InVehicle() and ply:KeyDown(IN_USE)) then
		return true
	end

	if (ownsEntity and !ply:InVehicle() and (IsValid(swep) and swep:GetClass() == "weapon_physgun" and dist > MaxDist) and ply:KeyDown(IN_ATTACK)) then
		return true
	end

	if IsValid(swep) and swep:GetClass() == "weapon_team_gate_admin_bypasser" and (((RynGateConfig.AdminSWEPBypassServerGates and ent:GetIsServerOwned()) or !ent:GetIsServerOwned()) and RynGateConfig.SWEPBypassGates) and (!ent:GetIsServerOwned() or ent:GetSWEPCanBypass()) then
		return false
	end

	if (((RynGateConfig.SWEPBypassServerGates and ent:GetIsServerOwned()) or !ent:GetIsServerOwned()) and RynGateConfig.SWEPBypassGates) and ply:GetNWInt("RynGates_BypassFinished", CurTime()) + RynGateConfig.SWEPBypassDuration > CurTime() and ent == ply:GetNWEntity("RynGates_BypassEntity") and (!ent:GetIsServerOwned() or ent:GetSWEPCanBypass()) then
		return false
	end

	if table.HasValue(allowedTeams, ply:Team()) then
		return false
	end

	if table.HasValue(allowedSteamIDs, ply:SteamID()) then
		return false
	end

	if ulibExists and table.HasValue(allowedULibGroups, ply:GetUserGroup()) then
		return false
	end

	if utimeExists and ((ply:GetUTimeTotalTime()/60/60) > ent:GetMinPlayTime() and ent:GetMinPlayTime() > 0) then
		return false
	end

	return false
end

hook.Add("RynGates_ShouldPlayerCollide", "RynGates_DefaultShouldPlayerCollide", shouldPlayerCollide)

local function shouldVehicleCollide(ent, vehicle, dist, maxdist)
	local driver = vehicle:GetDriver()

	if !IsValid(driver) or !driver:IsPlayer() then
		return true
	end

	return hook.Call("RynGates_ShouldPlayerCollide", nil, ent, driver, maxdist) or (!IsValid(driver) or !driver:IsPlayer())
end

hook.Add("RynGates_ShouldVehicleCollide", "RynGates_DefaultShouldVehicleCollide", shouldVehicleCollide)

local function shouldNPCollide(ent, npc, dist, MaxDist)
	if IsValid(npc) and npc:IsNPC() and ent:GetAllowNPCs() then
		return false
	end
end

hook.Add("RynGates_ShouldNPCCollide", "RynGates_DefaultShouldVehicleCollide", shouldNPCCollide)

local function CheckGateCollision(self, ent)
	if !IsValid(self) or !IsValid(ent) or !hook.Call("RynGates_IsAllowedEnt", nil, ent) or ent:IsWorld() or !self.GetAllowedTeams then
		return true
	end

	if self:GetIsBroken() then
		return false
	end

	local dist1 = ent:GetPos():Distance(self:GetPos())
	local dist2 = ent.EyePos and ent:EyePos():Distance(self:GetPos())
	local swep = (ent.GetActiveWeapon and ent:GetActiveWeapon())
	local mins, maxs = ent:GetCollisionBounds()
	local maxbounds = maxMaxs(maxs)
	local MaxDist = (self.GetMaxDist and self:GetMaxDist()) or 25
	local driver = ent:IsVehicle() and ent.GetDriver and ent:GetDriver()

	local dist = (dist1 < dist2 and dist1) or dist2

	if dist < (MaxDist + maxbounds) * 2 then -- Add check for self maxs.x - entPos.x, self maxs.y - entPos.y, etc
		if ent:IsPlayer() then
			return hook.Call("RynGates_ShouldPlayerCollide", nil, self, ent, MaxDist) --playerCollide(ent, self, MaxDist, allowedTeams)
		elseif self:GetAllowNPCs() and ent:IsNPC() then
			local result = hook.Call("RynGates_ShouldNPCCollide", nil, self, ent, dist, MaxDist)

			return (result != nil and result)
		elseif self:GetAllowVehicles() and ent:IsVehicle() then
			return hook.Call("RynGates_ShouldVehicleCollide", nil, self, ent, dist, MaxDist)
		else
			return hook.Call("RynGates_CustomCollisionCheck", nil, self, ent, dist, MaxDist)
		end
	else
		return (RynGateConfig.CanBreak and ((RynGateConfig.CanBreakAdmin and self:GetIsServerOwned()) or !self:GetIsServerOwned())) or ((ent:IsPlayer() or ent:IsNPC()) and !self:GetCanShootThrough())
	end
end

hook.Add("ShouldCollide", "ryn_team_gate_collision", function(ent1, ent2)
	if ent1:GetClass() == ent_gate_ClassName and ent2:GetClass() == ent_gate_ClassName then
		return
	end

	if (ent1:GetClass() == ent_gate_ClassName and ent2:IsWorld()) or (ent2:GetClass() == ent_gate_ClassName and ent1:IsWorld()) then
		return
	end

	local isValid1 = hook.Call("RynGates_IsAllowedEnt", nil, ent1)
	local isValid2 = hook.Call("RynGates_IsAllowedEnt", nil, ent2)

	if !isValid1 and !isValid2 then
		return
	end

	if ent2:GetClass() == ent_gate_ClassName then
		return CheckGateCollision(ent2, ent1)
	else
		return CheckGateCollision(ent1, ent2)
	end
end)
