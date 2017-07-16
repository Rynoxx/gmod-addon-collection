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

TOOL.Category = "Rynoxx"
TOOL.Name = "#tool.team_gates.name"

if CLIENT then
	language.Add("Tool.team_gates.name", "Team Gates")
	language.Add("Tool.team_gates.desc", "Allows you to spawn Team Gates with a toolgun")
	language.Add("Tool.team_gates.0", "Left-click to spawn")
	language.Add("Tool.team_gates.1", "Right-click to remove")
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end

	local ent = ent_gate_spawnFunction(self:GetOwner(), trace, ent_gate_ClassName)

	if IsValid(ent) and ent.CPPISetOwnerUID and !ent:GetIsServerOwned() then
		ent:CPPISetOwnerUID(self:GetOwner():UniqueID())
	end
end

function TOOL:RightClick( trace )
	local ent = trace.Entity

	if CLIENT and IsValid(ent) and ent:GetClass() == ent_gate_ClassName then return true end

	if IsValid(ent) and ent:GetClass() == ent_gate_ClassName then
		if ent:GetIsServerOwned() and self:GetOwner():IsAdmin() then
			SafeRemoveEntity(ent)
		elseif !ent:GetIsServerOwned() and ent:GetOwnerUniqueID() == self:GetOwner():UniqueID() then
			SafeRemoveEntity(ent)
		end
	end
end

function TOOL:Reload( trace )

end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", { Description = "#tool.team_gates.desc" } )
end
