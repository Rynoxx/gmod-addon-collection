--[[
Allows you to transfer entity ownership to different players
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

print("This server is using the Transfer Ownership tool by Rynoxx. Source code is available at https://github.com/Rynoxx/gmod-addon-collection")

TOOL.Category = "Construction"
TOOL.Name = "#tool.transfer_ownership.name"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" }
}

TOOL.ClientConVar[ "selected_userid" ] = ""

CreateConVar( "transfer_ownership_check_ownership", 1, bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Should the tool check if the user is the owner of the entity or if they have the right to use a toolgun on it? (e.g. on props of their friends)")
CreateConVar( "transfer_ownership_admin_check_ownership", 0, bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Should the tool check if the user is the owner of the entity or if they have the right to use a toolgun on it for admins?")
CreateConVar( "transfer_ownership_admin_usergroup", "superadmin", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE), "To which usergroup should the 'transfer_ownership_admin_check_ownership' convar apply?")

local TOCO = GetConVar("transfer_ownership_check_ownership")
local TOACO = GetConVar("transfer_ownership_admin_check_ownership")
local TOAU = GetConVar("transfer_ownership_admin_usergroup")

local function isUserGroup(ply, usergroup)
	if ply.ASS_HasLevel and ply:ASS_HasLevel(usergroup) then
		return true
	end

	if ply.CheckGroup and ply:CheckGroup(usergroup) then
		return true
	end

	if ply.EV_IsRank and ply.EV_IsRank(usergroup) then
		return true
	end

	if string.lower(usergroup) == "superadmin" and ply:IsSuperAdmin() then
		return true
	end

	if string.lower(usergroup) == "admin" and ply:IsAdmin() then
		return true
	end

	return ply:IsUserGroup(usergroup)
end

local function doGiveOwnership(ent, plyFrom, plyTo, bWasUndone)
	if type(ent) ~= "table" then
		ent = { ent }
	end

	local success = true

	for k, v in pairs(ent) do
		if not IsValid(v) or not IsValid(plyFrom) or not IsValid(plyTo) then continue end

		local owner = (FPP and FPP.entGetOwner(v)) or (v.CPPIGetOwner and v:CPPIGetOwner()) or v:GetOwner()

		if owner == plyTo then
			continue
		end

		if not TOCO:GetBool() or (not TOACO:GetBool() and ((plyFrom.CheckGroup and plyFrom:CheckGroup(TOAU:GetString())) or plyFrom:IsUserGroup(TOAU:GetString()))) then
			local canTool = (v.CPPICanTool and v:CPPICanTool(plyFrom, "transfer_ownership"))

			if not canTool then
				if not DarkRP then
					plyFrom:SendLua([[notification.AddLegacy("You're not allowed to transfer ownership of that entity!", NOTIFY_ERROR, 5)]])
				else
					DarkRP.notify(plyFrom, NOTIFY_ERROR, 5, "You're not allowed to transfer ownership of that entity!")
				end

				success = false
				continue
			end
		else
			if owner ~= plyFrom then
				if not DarkRP then
					plyFrom:SendLua([[notification.AddLegacy("You can only transfer your own entities!", NOTIFY_ERROR, 5)]])
				else
					DarkRP.notify(plyFrom, NOTIFY_ERROR, 5, "You can only transfer your own entities!")
				end

				success = false
				continue
			end
		end

		if v.CPPISetOwner then
			v:CPPISetOwner(plyTo)
		end

		if v.dt and v.dt.owning_ent then
			v.dt.owning_ent = plyTo
		end
	end

	if success then
		if not DarkRP then
			plyFrom:SendLua([[notification.AddLegacy("Successfully transfered ownership!", NOTIFY_ERROR, 5)]])
		else
			DarkRP.notify(plyFrom, NOTIFY_ERROR, 5, "Successfully transfered ownership!")
		end
	end

	if not bWasUndone then
		undo.Create("transfer_ownership")
			local undoE = ent
			local undoP = plyTo

			undo.AddFunction(function(tab, undoneE, undoneP)
				doGiveOwnership(undoneE, undoneP, tab.Owner, true)
			end, undoE, undoP)
			undo.SetPlayer(plyFrom)
		undo.Finish()
	end

	return true
end

local function simphysCompatability(entity)
	if CLIENT then return {} end

	if entity:GetClass() == "gmod_sent_vehicle_fphysics_base" then
		local simphysEnts = {}

		if IsValid(entity.DriverSeat) then
			table.insert(simphysEnts, entity.DriverSeat)
		end

		if IsValid(entity.MassOffset) then
			table.insert(simphysEnts, entity.MassOffset)
		end

		if IsValid(entity.SteerMaster) then
			table.insert(simphysEnts, entity.SteerMaster)
		end

		if IsValid(entity.SteerMaster2) then
			table.insert(simphysEnts, entity.SteerMaster2)
		end

		if entity.pSeat then
			for i = 1, table.Count(entity.pSeat) do
				if IsValid(entity.pSeat[i]) then
					table.insert(simphysEnts, entity.pSeat[i])
				end
			end
		end

		if entity.GhostWheels then
			for i = 1, table.Count(entity.GhostWheels) do
				if IsValid(entity.GhostWheels[i]) then
					table.insert(simphysEnts, entity.GhostWheels[i])
				end
			end
		end

		if entity.Wheels then
			for i = 1, table.Count(entity.Wheels) do
				if IsValid(entity.Wheels[i]) then
					table.insert(simphysEnts, entity.Wheels[i])
				end
			end
		end

		if entity.ColorableProps then
			if IsValid(entity.ColorableProps[i]) then
				table.insert(simphysEnts, entity.ColorableProps[i])
			end
		end
		return simphysEnts
	else
		return {}
	end
end

---
-- Transfer ownership of single entity
function TOOL:LeftClick(tr)
	if not IsValid(tr.Entity) then return end

	local ply = Player( self:GetClientInfo("selected_userid") )

	if not IsValid(ply) then
		if CLIENT then
			notification.AddLegacy("No valid player selected!", NOTIFY_ERROR, 5)
		end

		return false
	end

	if SERVER then
		local targetEnts = { tr.Entity }

		local simphysEnts = simphysCompatability(tr.Entity)
		table.Add(targetEnts, simphysEnts)

		doGiveOwnership(targetEnts, self:GetOwner(), ply)
	end

	return true
end

---
-- Transfer ownership of constrained entities
function TOOL:RightClick(tr)
	if not IsValid(tr.Entity) then return end

	local ply = Player(self:GetClientInfo("selected_userid") )

	if not IsValid(ply) then
		if CLIENT then
			notification.AddLegacy("No valid player selected!", NOTIFY_ERROR, 5)
		end

		return false
	end

	if SERVER then
		local targetEnts = constraint.GetAllConstrainedEntities( tr.Entity )

		local simphysEnts = simphysCompatability(tr.Entity)
		table.Add(targetEnts, simphysEnts)

		doGiveOwnership(targetEnts, self:GetOwner(), ply)
	end

	return true
end


function TOOL.BuildCPanel( CPanel )

	CPanel:Help("#tool.transfer_ownership.desc")

	local listBox, listLabel = CPanel:ListBox("#tool.transfer_ownership.players")
	listBox:SetMultiple(false)
	listBox.lastThink = 0
	listBox.players = {}
	listBox.OnSelect = function(me, item)
		RunConsoleCommand("transfer_ownership_selected_userid", item.player:UserID())
	end

	listBox:SetTall(480)

	local localplayer = LocalPlayer()

	listBox.Think = function(me)
		if me.lastThink + 1 < CurTime() then
			me.lastThink = CurTime()

			local playerList = player.GetAll()

			if table.Count(me.players) ~= table.Count(playerList) or me.players[table.maxn(me.players)] ~= playerList[table.maxn(playerList)] then
				me:Clear()
				me.players = playerList

				for k, v in pairs(me.players) do
					--if v ~= localplayer then
						local item = me:AddItem(v:Nick())
						item.player = v
					--end
				end

			end
			--]]
		end
	end
end

if CLIENT then
	language.Add("tool.transfer_ownership.name", "Transfer Ownership")
	language.Add("tool.transfer_ownership.desc", "Allows you to transfer ownership of entities to a player of your choice.")
	language.Add("tool.transfer_ownership.left", "Transfer ownership of target entity.")
	language.Add("tool.transfer_ownership.right", "Transfer ownership of constrained entities.")
	language.Add("tool.transfer_ownership.players", "Players")
	language.Add("Undone_transfer_ownership", "Undone ownership transfer")
end
