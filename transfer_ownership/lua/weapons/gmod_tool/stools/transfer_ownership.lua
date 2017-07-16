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

local function doGiveOwnership(ent, plyFrom, plyTo, bWasUndone)
	print(bWasUndone)
	if !IsValid(ent) or !IsValid(plyFrom) or !IsValid(plyTo) then return false end

	local owner = (FPP and FPP.entGetOwner(ent)) or (ent.CPPIGetOwner and ent:CPPIGetOwner()) or ent:GetOwner()

	if owner ~= plyFrom then
		return false
	end

	if !bWasUndone then
		undo.Create("transfer_ownership")
			local undoE = ent
			local undoP = plyTo

			undo.AddFunction(function(tab, undoneE, undoneP)
				doGiveOwnership(undoneE, undoneP, tab.Owner, true)
			end, undoE, undoP)
			undo.SetPlayer(plyFrom)
		undo.Finish()
	end

	if ent.CPPISetOwner then
		ent:CPPISetOwner(plyTo)
	end

	if ent.dt and ent.dt.owning_ent then
		ent.dt.owning_ent = plyTo
	end

	return true
end

---
-- Transfer ownership of single entity
function TOOL:LeftClick(tr)
	if !IsValid(tr.Entity) then return end

	local ply = Player( self:GetClientInfo("selected_userid") )

	if !IsValid(ply) then
		if CLIENT then
			notification.AddLegacy("No valid player selected!", NOTIFY_ERROR, 5)
		end

		return false
	end

	if SERVER then
		doGiveOwnership(tr.Entity, self:GetOwner(), ply)
	end

	return true
end

---
-- Transfer ownership of constrained entities
function TOOL:RightClick(tr)
	if !IsValid(tr.Entity) then return end

	local ply = Player(self:GetClientInfo("selected_userid") )

	if !IsValid(ply) then
		if CLIENT then
			notification.AddLegacy("No valid player selected!", NOTIFY_ERROR, 5)
		end

		return false
	end

	if SERVER then
		local ents = constraint.GetAllConstrainedEntities( tr.Entity )

		for k, v in pairs(ents) do
			doGiveOwnership(ents[v], self:GetOwner(), ply)
		end

		ents = nil
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
		print(item.player)
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
					if v ~= localplayer then
						local item = me:AddItem(v:Nick())
						item.player = v
					end
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
