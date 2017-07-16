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

RynGateConfig = {}

include("config.lua")
include("shared.lua")
include("saving.lua")

AddCSLuaFile("config.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("rynslider.lua")

util.AddNetworkString("RynoxxGateMenu")
util.AddNetworkString("RynoxxRemoveGate")
util.AddNetworkString("RynoxxUpdateGate")

resource.AddFile("materials/entities/" .. ent_gate_ClassName .. ".png")

local math = math
local util = util

net.Receive("RynoxxUpdateGate", function(len, ply)
	if !IsValid(ply) then
		return
	end

	local gate = net.ReadEntity()

	if !IsValid(gate) then
		return
	end

	if (gate:GetIsServerOwned() and !ply:IsAdmin()) or (!gate:GetIsServerOwned() and gate:GetOwnerUniqueID() != ply:UniqueID()) then
		return
	end

	local tbl = net.ReadTable()

	tbl.owneruniqueid = ply:UniqueID()

	if !ply:IsAdmin() then
		tbl.isserverowned = false
	end

	if IsValid(gate) and gate:GetClass() == ent_gate_ClassName then
		gate:Update(tbl)
	end
end)

net.Receive("RynoxxRemoveGate", function(len, ply)
	if !IsValid(ply) or (!ply:IsAdmin() and !RynGateConfig.NonAdminsCanSpawn) then
		return
	end

	local gate = net.ReadEntity()

	if !IsValid(gate) then
		return
	end

	if (gate:GetIsServerOwned() and !ply:IsAdmin()) or (!gate:GetIsServerOwned() and gate:GetOwnerUniqueID() != ply:UniqueID()) then
		return
	end

	if IsValid(gate) and gate:GetClass() == ent_gate_ClassName then
		RynGateSaving:Remove(gate:GetNWInt("GateID"))
		SafeRemoveEntity(gate)
	end
end)

ENT.MaxDistMult = 1.3

local function maxMaxs(maxs)
	return math.max(maxs.x, math.max(maxs.y, maxs.z))
end

local function CanSpawnGate(ply)
	if ply:IsAdmin() then
		return true
	else
		if RynGateConfig.UsergroupWhitelist and table.Count(RynGateConfig.UsergroupWhitelist) > 0 then
			if table.HasValue(RynGateConfig.UsergroupWhitelist, ply:GetUserGroup()) then
				return true
			elseif ply.GetRank and table.HasValue(RynGateConfig.UsergroupWhitelist, ply:GetRank()) then
				return true
			elseif ply.EV_GetRank and table.HasValue(RynGateConfig.UsergroupWhitelist, ply:EV_GetRank()) then
				return true
			end

			return false
		else
			return RynGateConfig.NonAdminsCanSpawn
		end
	end
end

function ENT:SetTextColor(color)
	if type(color) == "string" then
		color = string.ToColor(color)
	end

	self:SetTxtColor(Vector(color.r, color.g, color.b))
	if color.a != nil then
		self:SetTxtAlpha(color.a)
	else
		self:SetTxtAlpha(255)
	end
end

function ENT:SetULibGroups(groups)
	if string.lower(type(groups)) == "string" then
		self:SetNWString("RynGates_ULibGroups", groups)
	elseif string.lower(type(groups)) == "table" then
		self:SetNWString("RynGates_ULibGroups", util.TableToJSON(groups))
	end
end

function ent_gate_spawnFunction(ply, tr, ClassName)
	if ( !tr.Hit ) then return end

	if !CanSpawnGate(ply) then
		return nil
	end

	local SpawnPos = tr.HitPos
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 90
	SpawnAng.y = SpawnAng.y - 180

	local ent = ents.Create( ClassName )
	ent:SetAngles( SpawnAng )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()

	local mins, maxs = ent:GetCollisionBounds()
	local maxbounds = maxMaxs(maxs)

	ent:SetPos( ent:GetPos() + (tr.HitNormal * maxbounds) )

	ent:SetIsServerOwned(ply:IsAdmin())
	ent:SetOwnerUniqueID(ply:UniqueID())
	ent:SetGateID(RynGateSaving:GetNewID())
	RynGateSaving:Save(ent)

	if !ent:GetIsServerOwned() then
		--hook.Call("CPPIAssignOwnership", nil, ply, ent, ent:GetOwnerUniqueID())
		--ent:SetOwner(ply)

		if (RynGateSaving.limit[ply:UniqueID()] or 0) >= RynGateConfig.SpawnLimit and RynGateConfig.SpawnLimit > 0 then
			ent.noDecreaseLimit = true
			SafeRemoveEntity(ent)
			ply:LimitHit("team_gate")
			return
		end

		RynGateSaving.limit[ply:UniqueID()] = (RynGateSaving.limit[ply:UniqueID()] or 0) + 1

		ent:CPPISetOwnerUID(ply:UniqueID())

		return ent -- If it's not an admin that spawns it, return ent and let the addons decide who owns it.
	end

	ply:SendLua([[chat.AddText(Color(200, 200, 200), "[Team Gates] ", Color(255, 255, 255), "The gate you've spawned belongs to the server, to change this press E on the gate and untick the \"Is this gate owned by the server\" option.")]])
	ply:SendLua("chat.PlaySound()")

	return nil -- If an admin spawns it, make sure that it isn't owned by a player by default.
end

function ENT:SpawnFunction(...)
	return ent_gate_spawnFunction(...)
end

concommand.Add("rynteamgate_spawn", function(ply, cmd, args)
	local ent = ent_gate_spawnFunction(ply, ply:GetEyeTrace(), ent_gate_ClassName)

	if IsValid(ent) and ent.CPPISetOwnerUID and ent:GetIsServerOwned() then
		ent:CPPISetOwnerUID(ply:UniqueID())
	end
end)

function ENT:Update(tbl, ignoreSaving, newlySpawned)
	ignoreSaving = ignoreSaving or false
	newlySpawned = newlySpawned or false

	if tbl.id != nil then
		self:SetGateID(tbl.id)
	end

	if tbl.mat != nil then
		self:SetMaterial(tbl.mat)
	end

	if tbl.usecombinefence != nil then
		self:SetUseCombineFence(tbl.usecombinefence)
	end

	if tbl.combineorientation != nil then
		self:SetCombineOrientation(tbl.combineorientation)
	end

	if tbl.ownerisadmin != nil then
		self:SetIsServerOwned(tbl.ownerisadmin)
	end

	-- Start of spawn limit check for admins
	if !tbl.isserverowned and tbl.owneruniqueid != nil and self:GetIsServerOwned() then
		if (RynGateSaving.limit[tbl.owneruniqueid] or 0) >= RynGateConfig.SpawnLimit and RynGateConfig.SpawnLimit > 0 and RynGateConfig.SpawnLimitAdmins then
			local ply = player.GetByUniqueID(tbl.owneruniqueid)

			if IsValid(ply) then
				ply:LimitHit("team_gate")

				ply:SendLua([[chat.AddText(Color(240, 30, 30), "[Team Gates] ", Color(255, 255, 255), "You've hit the gate limit, this gate will be set to being server owned again.")]])
				ply:SendLua("chat.PlaySound()")
			end

			tbl.isserverowned = true
		else
			RynGateSaving.limit[tbl.owneruniqueid] = (RynGateSaving.limit[tbl.owneruniqueid] or 0) + 1
		end
	elseif tbl.isserverowned and tbl.owneruniqueid != nil and tbl.owneruniqueid == self:GetOwnerUniqueID() and self:GetOwnerUniqueID() != "" then
		RynGateSaving.limit[tbl.owneruniqueid] = math.Max((RynGateSaving.limit[tbl.owneruniqueid] or 1) - 1, 0)
	end
	-- End of spawn limit check for admins

	if tbl.isserverowned != nil then
		self:SetIsServerOwned(tbl.isserverowned)
	end

	if tbl.owneruniqueid != nil then
		self:SetOwnerUniqueID(tbl.owneruniqueid)

		if !self:GetIsServerOwned() then
			if self.CPPISetOwnerUID then
				self:CPPISetOwnerUID(self:GetOwnerUniqueID())
			end
		elseif self:GetIsServerOwned() then
			self:SetOwnerUniqueID("")

			if self.CPPISetOwnerUID then
				self:CPPISetOwnerUID("")
				self:CPPISetOwner(nil)
			end
		end
	end

	if tbl.swepcanbypass != nil then
		self:SetSWEPCanBypass(tbl.swepcanbypass)
	end

	if tbl.allownpcs != nil then
		self:SetAllowNPCs(tbl.allownpcs)
	end

	if tbl.allowvehicles != nil then
		self:SetAllowVehicles(tbl.allowvehicles)
	end

	if tbl.canshootthrough != nil then
		self:SetCanShootThrough(tbl.canshootthrough)
	end

	if tbl.text != nil then
		self:SetText(tbl.text)
	end

	if tbl.textalignment != nil then
		self:SetTextAlignment(tbl.textalignment)
	end

	if tbl.textposition != nil then
		self:SetTextPosX(math.Clamp(tbl.textposition[1], -1, 1))
		self:SetTextPosY(math.Clamp(tbl.textposition[2], -1, 1))
	end

	if tbl.textscale != nil then
		self:SetTextScale(tbl.textscale)
	end

	if tbl.textshouldfade != nil then
		self:SetTextShouldFade(tbl.textshouldfade)
	end

	if tbl.textcolor != nil then
		self:SetTextColor(tbl.textcolor)
	end

	if tbl.minplaytime != nil then
		self:SetMinPlayTime(tbl.minplaytime)
	end

	if tbl.allowedteams != nil then
		if string.lower(type(tbl.allowedteams)) == "string" then
			self:SetAllowedTeams(tbl.allowedteams)
		elseif string.lower(type(tbl.allowedteams)) == "table" then
			self:SetAllowedTeams(util.TableToJSON(tbl.allowedteams))
		end
	end

	if tbl.allowedsteamids != nil then
		if string.lower(type(tbl.allowedsteamids)) == "string" then
			self:SetAllowedSteamIDs(tbl.allowedsteamids)
		elseif string.lower(type(tbl.allowedsteamids)) == "table" then
			self:SetAllowedSteamIDs(util.TableToJSON(tbl.allowedsteamids))
		end
	end

	if tbl.ulibgroups != nil then
		self:SetULibGroups(tbl.ulibgroups)
	end

	if tbl.color != nil then
		self:SetCustomAlpha(tbl.color.a/255)
		tbl.color.a = 255
		self:SetColor(tbl.color)
	end

	if tbl.customalpha != nil then
		self:SetCustomAlpha(tbl.customalpha)
	end

	if tbl.map != nil then
		self.map = tbl.map
	end

	if tbl.model != nil then
		self:SetModel(tbl.model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		local physObj = self:GetPhysicsObject()

		if IsValid(physObj) then
			physObj:EnableMotion(false)
		end

		local mins, maxs = self:GetCollisionBounds()
		local maxbounds = maxMaxs(maxs)

		self:SetMaxDist(maxbounds * self.MaxDistMult)
	end

	local entLua = "Entity(" .. self:EntIndex() .. ")"

	self.SimplifiedSteamIDList = nil

	timer.Simple((newlySpawned and 2) or 0, function()
		local players = player.GetHumans()

		for i = 1, table.Count(players) do
			players[i]:SendLua([[local ent = ]] .. entLua .. [[ if IsValid(ent) and ent.RemoveCombineFences then ent:RemoveCombineFences() end]])
		end

		players = nil
	end)

	if !ignoreSaving then
		RynGateSaving:Save(self)
	end
end

function ENT:Initialize()
	self:SetModel(RynGateConfig.ModelList[RynGateConfig.DefaultModelIndex])
	self:SetAllowedTeams("{}")
	self:SetCanShootThrough(RynGateConfig.DefaultCanShootThrough)
	self:SetGateID(0)
	self:SetTextAlignment(RynGateConfig.DefaultTextAlignment)
	self:SetTextPosX(0)
	self:SetTextPosY(0)
	self:SetTextScale(RynGateConfig.DefaultTextScale)
	self:SetTextShouldFade(RynGateConfig.DefaultTextShouldFade)
	self:SetTextColor(color_white)
	self:SetColor(Color(255, 255, 255, 255))
	self:SetCustomAlpha((RynGateConfig.DefaultAlpha/100))
	self.ShouldKeepInSystem = false
	self:SetUseCombineFence(false)
	self:SetCombineOrientation(COMBINE_ORIENTATION_DEFAULT)

	self:UnBreak()

	self.Entity:SetCustomCollisionCheck(true)
	self:SetCustomCollisionCheck(true)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	--self:SetMoveType(MOVETYPE_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetIsServerOwned(true)

	self.map = game.GetMap()

	local physObj = self:GetPhysicsObject()

	if IsValid(physObj) then
		physObj:EnableMotion(false)
		physObj:SetMaterial("solidmetal")
	end

	local mins, maxs = self:GetCollisionBounds()
	local maxbounds = maxMaxs(maxs)

	self:SetMaxDist(maxbounds * self.MaxDistMult)
	self:Update({}, true)
end

function ENT:Use( activator, caller )
	if !activator:IsPlayer() or (!self:GetIsServerOwned() and activator:UniqueID() != self:GetOwnerUniqueID()) or (self:GetIsServerOwned() and !activator:IsAdmin()) then
		return false
	end

	net.Start("RynoxxGateMenu")
		net.WriteEntity(self.Entity)
	net.Send(activator)
end

function ENT:Break()
	self:SetIsBroken(true)
	self:SetBreakTime(CurTime())
	self:EmitSound("physics/plastic/plastic_barrel_break" .. math.random(1, 2) .. ".wav")
end

function ENT:UnBreak()
	self:SetIsBroken(false)
	self:SetGHealth(RynGateConfig.GateHealth)
end

function ENT:OnTakeDamage(dmg)
	if !self:GetIsBroken() then
		if RynGateConfig.CanBreak then
			if (RynGateConfig.CanBreakAdmin and self:GetIsServerOwned()) or !self:GetIsServerOwned() then
				local disallowed = false
				for i = 1, #RynGateConfig.DisallowedDamageTypes do
					if bit.band(dmg:GetDamageType(), RynGateConfig.DisallowedDamageTypes[i]) > 0 then
						disallowed = true
						break
					end
				end

				if !disallowed then
					self:SetGHealth((self:GetGHealth() or RynGateConfig.GateHealth) - dmg:GetDamage())

					if self:GetGHealth() <= 0 then
						self:Break()
					end
				end
			end
		end
	end
end

function ENT:Think()
	if self:GetIsBroken() and self:GetBreakTime() + RynGateConfig.BreakDuration < CurTime() then
		self:UnBreak()
	end

	if (self.lastSave or 0) + math.max(RynGateConfig.SaveInterval, 1) > CurTime() then
		self.lastSave = CurTime()

		RynGateSaving:Save(self)
	end
end

function ENT:OnRemove()
	if !self:GetIsServerOwned() and IsValid(self.Entity) and !self.noDecreaseLimit then
		RynGateSaving.limit[self:GetOwnerUniqueID()] = math.Max((RynGateSaving.limit[self:GetOwnerUniqueID()] or 1) - 1, 0)
	end

	if self.ShouldKeepInSystem then
		RynGateSaving:Save(self)
	else
		RynGateSaving:Remove(self:GetGateID())
	end
end
