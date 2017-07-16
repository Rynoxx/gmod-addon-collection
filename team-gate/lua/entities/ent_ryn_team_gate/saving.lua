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

local savefile = RynGateConfig.SaveFileName -- The filename can end with anything, the script will automaticly add .txt if it doesn't end with it already.

RynGateSaving = {
	gates = {},
	savefile = (string.EndsWith(savefile, ".txt") and savefile) or savefile .. ".txt",
	autosave = autosave_interval or 120,
	limit = {}
}

local ClassName = ent_gate_ClassName

function RynGateSaving:LoadAll()
	self.gates = util.JSONToTable(file.Read(self.savefile, "DATA") or "{}") or {}
	self.limit = {}

	local allgates = ents.FindByClass(ClassName)

	for i = 1, table.Count(allgates) do
		if IsValid(allgates[i]) then
			allgates[i].ShouldKeepInSystem = true
			SafeRemoveEntity(allgates[i])
		end
	end

	allgates = nil

	for k, v in pairs(self.gates) do
		if !v then
			print("Gate #" .. v.id, "is missing")
			continue
		end

		if v.map != nil and v.map != game.GetMap() then
			continue
		end

		v.isserverowned = v.isserverowned or (v.ownerisadmin != nil and v.ownerisadmin)

		if !v.isserverowned and !RynGateConfig.SaveNonAdminGates then
			continue
		end

		local ent = ents.Create( ClassName )
		ent:SetAngles( v.angles )
		ent:SetPos( v.position )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:Spawn()
		ent:Activate()

		ent:Update(v, true, true)
	end
end

function RynGateSaving:SaveAll()
	local allgates = ents.FindByClass(ClassName)

	for i = 1, table.Count(allgates) do
		self:Save(allgates[i])
	end

	allgates = nil
end

function RynGateSaving:Save(ent)
	if !IsValid(ent) then
		return
	end

	if !ent:GetIsServerOwned() and !RynGateConfig.SaveNonAdminGates then
		self.gates[ent:GetGateID()] = nil
		return
	end

	local gate = {}
	gate.id = ent:GetGateID()
	gate.mat = ent:GetMaterial() or ""
	gate.model = ent:GetModel() or ""
	gate.color = ent:GetColor()
	gate.customalpha = ent:GetCustomAlpha() or (RynGateConfig.DefaultAlpha/100)
	gate.allowedteams = ent:GetAllowedTeams()
	gate.usecombinefence = ent:GetUseCombineFence()
	gate.combineorientation = ent:GetCombineOrientation()
	gate.allowvehicles = ent:GetAllowVehicles()
	gate.allownpcs = ent:GetAllowNPCs()
	gate.canshootthrough = ent:GetCanShootThrough()
	gate.position = ent:GetPos()
	gate.angles = ent:GetAngles()
	gate.text = ent:GetText()
	gate.textscale = ent:GetTextScale()
	gate.textcolor = ent:GetTextColor()
	gate.textalignment = ent:GetTextAlignment()
	gate.textshouldfade = ent:GetTextShouldFade()
	gate.textposition = {ent:GetTextPosX(), ent:GetTextPosY()}
	gate.map = game.GetMap()
	gate.isserverowned = ent:GetIsServerOwned()
	gate.owneruniqueid = ent:GetOwnerUniqueID()
	gate.swepcanbypass = ent:GetSWEPCanBypass()
	gate.allowedsteamids = ent:GetAllowedSteamIDs()
	gate.ulibgroups = ent:GetULibGroups()
	gate.minplaytime = ent:GetMinPlayTime()
	-- gate.canbreak = ent:GetCanBreak() -- Disabled for now, might be added later

	self.gates[gate.id] = gate

	self:SaveToFile()
end

function RynGateSaving:SaveToFile()
	file.Write(self.savefile, util.TableToJSON(self.gates))
end

function RynGateSaving:Remove(id)
	if isentity(id) then
		id = id:GetGateID()
	end

	for k, v in pairs(self.gates) do
		if v.id == id then
			self.gates[k] = nil
			break
		end
	end

	self:SaveToFile()
end

function RynGateSaving:GetNewID()
	local id = 1

	for k, v in pairs(self.gates) do
		if v.id >= id then
			id = v.id + 1
		end
	end

	return id
end

function RynGateSaving:GetByID(id)
	local gate = nil

	if !self.gates[id] then
		local allgates = ents.FindByClass(ClassName)

		for i = 1, table.Count(allgates) do
			if allgates[i]:GetNWInt("GateID") == id then
				gate = allgates[i]
				break
			end
		end

		allgates = nil
	end

	return gate
end

hook.Add("PreCleanupMap", "MarkAllTeamGatesForSaving", function()
	local allgates = ents.FindByClass(ClassName)

	for i = 1, table.Count(allgates) do
		if IsValid(allgates[i]) then
			allgates[i].ShouldKeepInSystem = true
		end
	end
end)

hook.Add("PostCleanupMap", "RespawnAllTeamGates", function()
	RynGateSaving:LoadAll()
end)

hook.Add("ShutDown", "SaveAllTeamGates", function()
	local allgates = ents.FindByClass(ClassName)

	for i = 1, table.Count(allgates) do
		if IsValid(allgates[i]) then
			allgates[i].ShouldKeepInSystem = true
		end
	end

	RynGateSaving:SaveAll()
end)

hook.Add("RynGates_SaveAll", "SaveAllTeamGates", function()
	RynGateSaving:SaveAll()
end)

hook.Add("RynGates_Save", "SaveOneTeamGate", function(ent)
	RynGateSaving:Save(ent)
end)

timer.Simple(2, function()
	MsgN("Spawning all Team Gates")
	RynGateSaving:LoadAll()
end)
