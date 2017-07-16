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
include("rynslider.lua")

language.Add("SBoxLimit_team_gate", "Team Gate limit hit!")

local RynGateMaterial = CreateClientConVar("cl_ryngate_material", "", false, false)
local RynGateModel = CreateClientConVar("cl_ryngate_model", "", false, false)
local RynGateDermaSkin = CreateClientConVar("cl_ryngate_derma_skin", "Default", true, false)

ENT.LeftCombineFence = "models/props_combine/combine_fence01b.mdl"
ENT.RightCombineFence = "models/props_combine/combine_fence01a.mdl"

local surface = surface
local draw = draw
local render = render
local cam = cam
local math = math
local util = util

local ulibExists = ULib != nil and ULib.ucl != nil and ULib.ucl.groups != nil

local plyMeta = FindMetaTable( "Player" )
local utimeExists = plyMeta.GetUTime != nil
plyMeta = nil

surface.CreateFont("RynGateFont", {
	font = "Arial",
	size = ScreenScale(64),
	outline = true
})

local txtH = draw.GetFontHeight("RynGateFont")
local fadeDistMult = 2

function ENT:Draw()
	if (self.GetIsBroken and self:GetIsBroken()) and RynGateConfig.CanBreak and ((RynGateConfig.CanBreakAdmin and self:GetIsServerOwned()) or !self:GetIsServerOwned()) then
		return false
	end

	render.SetBlend(math.Clamp(self:GetCustomAlpha(), 0, 1))
		self.Entity:DrawModel()
	render.SetBlend(1)

	local mins, maxs = self:GetRenderBounds()

	local ply = LocalPlayer()

	if string.Trim(self:GetText()) != "" then
		local numRows = table.Count(string.Explode("\n", self:GetText()))
		local txtY = -(txtH * numRows)/2

		local scale = math.Clamp(self:GetTextScale(), RynGateConfig.MinTextScale, RynGateConfig.MaxTextScale)/10

		local realAlignVal = self:GetTextAlignment()
		local alignment = (realAlignVal == 1 and TEXT_ALIGN_LEFT) or (realAlignVal == 2 and TEXT_ALIGN_CENTER) or (realAlignVal == 3 and TEXT_ALIGN_RIGHT)

		local txtPosX = (self:GetRight() * (maxs.x * self:GetTextPosX()))
		local txtPosY = (self:GetForward() * (maxs.y * self:GetTextPosY()))

		local textAlpha = 1

		if self:GetTextShouldFade() and ply:EyePos():Distance(self:GetPos()) > RynGateConfig.DefaultTextFadeDistance then
			local dist = ply:EyePos():Distance(self:GetPos()) - RynGateConfig.DefaultTextFadeDistance

			local distDiv = dist/(RynGateConfig.DefaultTextFadeDistance * RynGateConfig.MaxTextScale)

			textAlpha = 1 - math.Clamp(distDiv, 0, 1)
		elseif !self:GetTextShouldFade() and ply:EyePos():Distance(self:GetPos()) > (RynGateConfig.DefaultTextFadeDistance * (fadeDistMult * RynGateConfig.MaxTextScale + 1)) then
			textAlpha = 0
		end

		if textAlpha > 0 then
			local textColor = self:GetTextColor() or color_white
			textColor.a = textColor.a * textAlpha

			local ang1 = self:GetAngles() * 1

			if self:GetCombineOrientation() == COMBINE_ORIENTATION_DEFAULT then
				ang1:RotateAroundAxis(ang1:Up(), 90)
			end

			cam.Start3D2D(self:GetPos() + (self:GetUp() * maxs.z) - txtPosX - txtPosY, ang1, scale)
				draw.DrawText(self:GetText(), "RynGateFont", 0, txtY, textColor, alignment)
			cam.End3D2D()

			ang1:RotateAroundAxis(ang1:Right(), 180)
			cam.Start3D2D(self:GetPos() - (self:GetUp() * maxs.z) + txtPosX - txtPosY, ang1, scale)
				draw.DrawText(self:GetText(), "RynGateFont", 0, txtY, textColor, alignment)
			cam.End3D2D()
		end
	end

	if self:GetUseCombineFence() and (!IsValid(self.RightFence) or !IsValid(self.LeftFence)) then
		if !self.RemovingFences and !self.Creating then
			self.Creating = true

			if IsValid(self.RightFence) then
				self.RightFence:Remove()
			end

			if IsValid(self.LeftFence) then
				self.LeftFence:Remove()
			end

			self.RightFence = ClientsideModel(self.RightCombineFence, RENDERGROUP_OPAQUE)
			self.LeftFence = ClientsideModel(self.LeftCombineFence, RENDERGROUP_OPAQUE)

			local ang2 = self:GetAngles() * 1
			local pos_r = self:GetPos()
			local pos_l = self:GetPos()
			local rfMins, rfMaxs = self.RightFence:GetRenderBounds()
			local lfMins, lfMaxs = self.LeftFence:GetRenderBounds()

			if self:GetCombineOrientation() == COMBINE_ORIENTATION_DEFAULT then
				ang2:RotateAroundAxis(ang2:Right(), 90)

				pos_r = pos_r + (self:GetForward() * (maxs.x + rfMins.z)) + (self:GetRight() * mins.y*1.01) + (self:GetUp() * 1.5)

				pos_l = pos_l + (self:GetForward() * (maxs.x + lfMins.z)) + (self:GetRight() * maxs.y*1.01) + (self:GetUp() * 1.5)
			elseif self:GetCombineOrientation() == COMBINE_ORIENTATION_NINETY_ROLL then
				ang2:RotateAroundAxis(ang2:Right(), 90)
				ang2:RotateAroundAxis(ang2:Up(), 180)
				ang2:RotateAroundAxis(ang2:Forward(), 90)

				pos_r = pos_r + (self:GetRight() * (maxs.y + rfMins.z)) + (self:GetForward() * mins.x*1.01) - (self:GetUp() * 1.5)

				pos_l = pos_l + (self:GetRight() * (maxs.y + lfMins.z)) + (self:GetForward() * maxs.x*1.01) - (self:GetUp() * 1.5)
			end

			self.RightFence:SetAngles(ang2)
			self.RightFence:SetPos(pos_r)
			self.RightFence:SetParent(self)

			self.LeftFence:SetAngles(ang2)
			self.LeftFence:SetPos(pos_l)
			self.LeftFence:SetParent(self)

			self.Creating = false
		end
	end

	hook.Call("RynGates_Draw", nil, self)
end

function ENT:OnRemove()
	self:RemoveCombineFences()
end

function ENT:RemoveCombineFences()
	self.SimplifiedSteamIDList = nil

	if self.RemovingFences or self.Creating then return end

	self.RemovingFences = true

	if IsValid(self.RightFence) then
		self.RightFence:Remove()
	end

	if IsValid(self.LeftFence) then
		self.LeftFence:Remove()
	end

	self.RemovingFences = false
end

function ENT:Think()
	if (self.lastFenceRemoval or 0) + 120 > CurTime() then
		self.lastFenceRemoval = CurTime()
		self:RemoveCombineFences()
	end
end

RynGateMenu = RynGateMenu or nil

net.Receive("RynoxxGateMenu", function(len)
	if IsValid(RynGateMenu) then
		return
	end

	local gate = net.ReadEntity()
	local ply = LocalPlayer()

	if !gate then
		return
	end

	if gate:GetClass() != ent_gate_ClassName then
		return
	end

	if (gate:GetIsServerOwned() and !ply:IsAdmin()) or (!gate:GetIsServerOwned() and gate:GetOwnerUniqueID() != ply:UniqueID()) then
		return
	end

	RynGateMenu = vgui.Create("DFrame")
	RynGateMenu:SetTitle("Rynoxx's Team Gate - Menu")
	RynGateMenu:SetSize(math.min(RynGateConfig.MenuSize.width, ScrW()), math.min(RynGateConfig.MenuSize.height, ScrH()))
	RynGateMenu.gate = gate
	RynGateMenu.previouslyAllowedTeams = util.JSONToTable((gate:GetAllowedTeams() != "" and gate:GetAllowedTeams()) or "{}")
	RynGateMenu.previouslyAllowedGroups = util.JSONToTable((gate:GetULibGroups() != "" and gate:GetULibGroups()) or "{}")
	RynGateMenu:Center()
	RynGateMenu:MakePopup()
	function RynGateMenu:UpdateDermaSkin(dermaSkin)
		local GAM = GM or GAMEMODE or gmod.GetGamemode()

		local cl_Skin = RynGateDermaSkin:GetString()
		local isDefaultSkin = !cl_Skin or cl_Skin == "Default" or RynGateMenu.SkinList[cl_Skin] != nil

		if RynGateMenu.SkinList[cl_Skin] != nil and cl_Skin != nil and cl_Skin != "" then
			RunConsoleCommand("cl_ryngate_derma_skin", RynGateConfig.DefaultDermaSkin)
		end

		local DSkin = (!isDefaultSkin and cl_Skin) or (GAM.Config and GAM.Config.DarkRPSkin and !RynGateConfig.OverrideDarkRPDerma) or RynGateConfig.DefaultDermaSkin

		self:SetSkin(DSkin)
	end

	RynGateMenu.SkinList = derma.GetSkinTable()

	RynGateMenu.Panel = vgui.Create("DPanel", RynGateMenu)
	RynGateMenu.Panel:SetPos(8, 23)
	RynGateMenu.Panel:SetSize(RynGateMenu:GetWide() - 16, RynGateMenu:GetTall() - 23 - 32)
	RynGateMenu.Panel.Paint = function(p, w, h) /*draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 168))*/ end

	RynGateMenu.LeftPanel = RynGateMenu.Panel:Add("DScrollPanel")
	RynGateMenu.LeftPanel:SetSize((RynGateMenu.Panel:GetWide()/2) - 4, RynGateMenu.Panel:GetTall())
	RynGateMenu.LeftPanel:Dock(LEFT)
	RynGateMenu.LeftPanel.Paint = function(p, w, h) /*draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 168))*/ end

	RynGateMenu.RightPanel = RynGateMenu.Panel:Add("DScrollPanel")
	RynGateMenu.RightPanel:SetSize((RynGateMenu.Panel:GetWide()/2) - 4, RynGateMenu.Panel:GetTall())
	RynGateMenu.RightPanel:Dock(RIGHT)
	RynGateMenu.RightPanel.Paint = function(p, w, h) /*draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 168))*/ end

	-------- Buttons
	RynGateMenu.Buttons = vgui.Create("DPanel", RynGateMenu)
	RynGateMenu.Buttons:SetPos(8, RynGateMenu:GetTall() - 32)
	RynGateMenu.Buttons:SetSize(RynGateMenu:GetWide() - 16, 32 - 8)
	RynGateMenu.Buttons.Paint = function(p, w, h) /*draw.RoundedBox(0, 0, 0, w, h, Color(225, 0, 168))*/ end

	RynGateMenu.Buttons.Save = RynGateMenu.Buttons:Add("DButton")
	RynGateMenu.Buttons.Save:Dock(LEFT)
	RynGateMenu.Buttons.Save:DockMargin(0, 0, 8, 0)
	RynGateMenu.Buttons.Save:SetText("Save")
	RynGateMenu.Buttons.Save:SizeToContentsX()
	RynGateMenu.Buttons.Save:SetWide(RynGateMenu.Buttons.Save:GetWide() * 2)
	RynGateMenu.Buttons.Save.DoClick = function(b)
		if IsValid(RynGateMenu.gate) then
			local allowedTeams = {}

			for i = 1, table.Count(RynGateMenu.TeamPanels.teams) do
				if RynGateMenu.TeamPanels.teams[i]:GetChecked() then
					table.insert(allowedTeams, RynGateMenu.TeamPanels.teams[i].team)
				end
			end

			local allowedSteamIDs = {}

			for k, v in pairs(RynGateMenu.SteamIDList.Lines) do
				table.insert(allowedSteamIDs, {name = v:GetColumnText(1), steamid = v:GetColumnText(2)})
			end

			local ulibGroups = {}

			for i = 1, table.Count(RynGateMenu.ULibPanels.groups) do
				if RynGateMenu.ULibPanels.groups[i]:GetChecked() then
					table.insert(ulibGroups, RynGateMenu.ULibPanels.groups[i].group)
				end
			end

			local saveTbl = {
				mat = RynGateMaterial:GetString(),
				model = RynGateModel:GetString(),
				allowedteams = util.TableToJSON(allowedTeams),
				allowedsteamids = util.TableToJSON(allowedSteamIDs),
				ulibgroups = util.TableToJSON(ulibGroups),
				color = RynGateMenu.ColorSelect:GetColor(),
				usecombinefence = RynGateMenu.FenceCheckBox:GetChecked(),
				combineorientation = RynGateMenu.FenceComboBox:GetOptionData(RynGateMenu.FenceComboBox:GetSelectedID()),
				allowvehicles = RynGateMenu.VehicleCheckBox:GetChecked(),
				allownpcs = RynGateMenu.NPCCheckBox:GetChecked(),
				canshootthrough = RynGateMenu.CanShootCheckBox:GetChecked(),
				text = RynGateMenu.TextArea:GetValue(),
				textalignment = RynGateMenu.TextAlignCombo:GetSelectedID(),
				textposition = {RynGateMenu.TextPosX:GetValue(), RynGateMenu.TextPosY:GetValue()},
				textscale = RynGateMenu.TextScale:GetValue(),
				textshouldfade = RynGateMenu.TextShouldFade:GetChecked(),
				textcolor = RynGateMenu.TextColorSelect:GetColor(),
				isserverowned = (IsValid(RynGateMenu.ServerOwnedCheckBox) and RynGateMenu.ServerOwnedCheckBox:GetChecked()) or false,
				swepcanbypass = (IsValid(RynGateMenu.SWEPBypassCheckBox) and RynGateMenu.SWEPBypassCheckBox:GetChecked()),
				minplaytime = (IsValid(RynGateMenu.UTimeSlider) and RynGateMenu.UTimeSlider:GetValue()) or 0
			}

			if !IsValid(RynGateMenu.SWEPBypassCheckBox) then
				saveTbl.swepcanbypass = RynGateConfig.SWEPBypassGates
			end

			net.Start("RynoxxUpdateGate")
				net.WriteEntity(RynGateMenu.gate)
				net.WriteTable(saveTbl)
			net.SendToServer()

			chat.AddText(Color(200, 200, 200), "[Team Gates] ", Color(255, 255, 255), "Saved gate #" .. RynGateMenu.gate:GetGateID())
			chat.PlaySound()
		else
			chat.AddText(Color(200, 200, 200), "[Team Gates] ", Color(255, 255, 255), "The gate couldn't be saved, this could be because the gate has been removed or there was a map cleanup.")
			chat.PlaySound()
		end
	end

	RynGateMenu.Buttons.ResetMat = RynGateMenu.Buttons:Add("DButton")
	RynGateMenu.Buttons.ResetMat:Dock(LEFT)
	RynGateMenu.Buttons.ResetMat:DockMargin(0, 0, 8, 0)
	RynGateMenu.Buttons.ResetMat:SetText("Reset Material")
	RynGateMenu.Buttons.ResetMat:SizeToContentsX()
	RynGateMenu.Buttons.ResetMat:SetWide(RynGateMenu.Buttons.ResetMat:GetWide() * 2)
	RynGateMenu.Buttons.ResetMat.DoClick = function(b)
		RunConsoleCommand("cl_ryngate_material", "")

		net.Start("RynoxxUpdateGate")
			net.WriteEntity(RynGateMenu.gate)
			net.WriteTable({
				mat = ""
			})
		net.SendToServer()


		RynGateMenu.MatSelect:TestForChanges()
	end

	RynGateMenu.Buttons.ResetCol = RynGateMenu.Buttons:Add("DButton")
	RynGateMenu.Buttons.ResetCol:Dock(LEFT)
	RynGateMenu.Buttons.ResetCol:DockMargin(0, 0, 8, 0)
	RynGateMenu.Buttons.ResetCol:SetText("Reset Color")
	RynGateMenu.Buttons.ResetCol:SizeToContentsX()
	RynGateMenu.Buttons.ResetCol:SetWide(RynGateMenu.Buttons.ResetCol:GetWide() * 2)
	RynGateMenu.Buttons.ResetCol.DoClick = function(b)
		local col = Color(255, 255, 255, (255 * (RynGateConfig.DefaultAlpha/100)))

		RynGateMenu.ColorSelect:SetColor(col)

		net.Start("RynoxxUpdateGate")
			net.WriteEntity(RynGateMenu.gate)
			net.WriteTable({
				color = col
			})
		net.SendToServer()
	end

	RynGateMenu.Buttons.ResetTxtCol = RynGateMenu.Buttons:Add("DButton")
	RynGateMenu.Buttons.ResetTxtCol:Dock(LEFT)
	RynGateMenu.Buttons.ResetTxtCol:DockMargin(0, 0, 8, 0)
	RynGateMenu.Buttons.ResetTxtCol:SetText("Reset Text Color")
	RynGateMenu.Buttons.ResetTxtCol:SizeToContentsX()
	RynGateMenu.Buttons.ResetTxtCol:SetWide(RynGateMenu.Buttons.ResetCol:GetWide() * 1.5)
	RynGateMenu.Buttons.ResetTxtCol.DoClick = function(b)
		local col = color_white

		RynGateMenu.TextColorSelect:SetColor(col)

		net.Start("RynoxxUpdateGate")
			net.WriteEntity(RynGateMenu.gate)
			net.WriteTable({
				textcolor = col
			})
		net.SendToServer()
	end

	RynGateMenu.Buttons.RemoveGate = RynGateMenu.Buttons:Add("DButton")
	RynGateMenu.Buttons.RemoveGate:SetText("Remove")
	RynGateMenu.Buttons.RemoveGate:Dock(RIGHT)
	RynGateMenu.Buttons.RemoveGate:DockMargin(8, 0, 0, 0)
	RynGateMenu.Buttons.RemoveGate.DoClick = function(b)
		net.Start("RynoxxRemoveGate")
			net.WriteEntity(RynGateMenu.gate)
		net.SendToServer()

		RynGateMenu:Close()
	end

	RynGateMenu.Buttons.DermaSkin = RynGateMenu.Buttons:Add("DComboBox")
	RynGateMenu.Buttons.DermaSkin:Dock(RIGHT)
	RynGateMenu.Buttons.DermaSkin:DockMargin(0, 0, 0, 0)
	RynGateMenu.Buttons.DermaSkin:SetTooltip("Do note that this only affects your menu.")
	RynGateMenu.Buttons.DermaSkin.OnSelect = function(b, index, value, data)
		if value != "" then
			RunConsoleCommand("cl_ryngate_derma_skin", value)

			if IsValid(RynGateMenu) then
				RynGateMenu:UpdateDermaSkin()
			end
		end
	end

	local i = 0

	for k, v in pairs(RynGateMenu.SkinList) do
		i = i + 1

		RynGateMenu.Buttons.DermaSkin:AddChoice(k)

		if k == RynGateDermaSkin:GetString() then
			RynGateMenu.Buttons.DermaSkin:ChooseOption(k, i)
		end
	end

	i = 0

	RynGateMenu.Buttons.DermaSkinLbl = RynGateMenu.Buttons:Add("DLabel")
	RynGateMenu.Buttons.DermaSkinLbl:SetText("Derma Skin:")
	RynGateMenu.Buttons.DermaSkinLbl:Dock(RIGHT)
	RynGateMenu.Buttons.DermaSkinLbl:DockMargin(8, 0, 0, 0)
	RynGateMenu.Buttons.DermaSkinLbl:SetTooltip("Do note that this only affects your menu.")

	-------- Job Selection
	RynGateMenu.TeamLbl = RynGateMenu.LeftPanel:Add("DLabel")
	RynGateMenu.TeamLbl:SetText("Teams/Jobs: (Selected ones CAN go through the gate)")
	RynGateMenu.TeamLbl:Dock(TOP)
	RynGateMenu.TeamLbl:SetWide(RynGateMenu.LeftPanel:GetWide())

	RynGateMenu.TeamPanels = RynGateMenu.LeftPanel:Add("DPanel")
	RynGateMenu.TeamPanels:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.TeamPanels:Dock(TOP)
	RynGateMenu.TeamPanels.columns = {}
	RynGateMenu.TeamPanels.teams = {}
	RynGateMenu.TeamPanels.Paint = function(me, w, h)
		draw.RoundedBox(2, 0, 0, w, h, Color(200, 200, 200))
	end

	for i = 1, 3 do
		RynGateMenu.TeamPanels.columns[i] = RynGateMenu.TeamPanels:Add("DPanel")
		RynGateMenu.TeamPanels.columns[i]:Dock(LEFT)
		RynGateMenu.TeamPanels.columns[i]:SetWide(RynGateMenu.TeamPanels:GetWide()/3)
		RynGateMenu.TeamPanels.columns[i].Paint = function() end
	end

	local teams = team.GetAllTeams()

	local size = 0
	local currentTeam = 0
	local currentColumn = 0
	local teamCount = table.Count(teams)

	for k, v in pairs(teams) do
		if currentTeam % math.ceil(teamCount/3) == 0 then
			currentColumn = currentColumn + 1

			if currentColumn > 3 then
				currentColumn = 1
			end
		end

		currentTeam = currentTeam + 1
		local checklbl = RynGateMenu.TeamPanels.columns[currentColumn]:Add("DCheckBoxLabel")
		checklbl:SetText(v.Name)
		checklbl.team = k
		checklbl:Dock(TOP)
		checklbl:SetTextColor(Color(50, 50, 50))
		checklbl:SizeToContents()
		checklbl:DockMargin(10, 3, 10, 3)
		checklbl:SetChecked(table.HasValue(RynGateMenu.previouslyAllowedTeams, k))

		table.insert(RynGateMenu.TeamPanels.teams, checklbl)

		if currentColumn == 1 then
			size = size + checklbl:GetTall() + 6
		end
	end

	RynGateMenu.TeamPanels:SetTall(size)

	for i = 1, 3 do
		RynGateMenu.TeamPanels.columns[i]:SetTall(size)
	end

	teams = nil

	-------- SteamID Selection
	RynGateMenu.SteamIDLbl = RynGateMenu.LeftPanel:Add("DLabel")
	RynGateMenu.SteamIDLbl:SetText("Players which can (ALWAYS) go through the gate. (Double click to remove single steamid,\nright click to remove selected steamids)")
	RynGateMenu.SteamIDLbl:Dock(TOP)
	RynGateMenu.SteamIDLbl:DockMargin(0, 8, 0, 2)
	RynGateMenu.SteamIDLbl:SizeToContentsY()

	RynGateMenu.SteamIDList = RynGateMenu.LeftPanel:Add("DListView")
	RynGateMenu.SteamIDList:Dock(TOP)
	RynGateMenu.SteamIDList:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.SteamIDList:SetTall(RynGateMenu:GetTall() * 0.1)
	RynGateMenu.SteamIDList:SetMultiSelect(true)
	RynGateMenu.SteamIDList:AddColumn("Name")
	RynGateMenu.SteamIDList:AddColumn("SteamID")
	function RynGateMenu.SteamIDList:OnRowRightClick(index, Line)
		local selectedSteamIDs = self:GetSelected()
		Derma_Query("Are you sure you want to remove the selected SteamIDs from the list?", "Remove Selected SteamIDs", "Yes", function()
			if IsValid(self) and selectedSteamIDs then
				for i = 1, table.Count(selectedSteamIDs) do
					self:RemoveLine(selectedSteamIDs[i]:GetID())
				end
			end
		end, "No")
	end

	function RynGateMenu.SteamIDList:DoDoubleClick(index, line)
		Derma_Query("Are you sure you want to remove \"" .. line:GetColumnText(2) .. "\" from the list?", "Remove SteamID", "Yes", function() if IsValid(self) then self:RemoveLine(index) end end, "No")
	end

	RynGateMenu.SteamIDPanel = RynGateMenu.LeftPanel:Add("DPanel")
	RynGateMenu.SteamIDPanel:Dock(TOP)
	RynGateMenu.SteamIDPanel:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.SteamIDPanel.Paint = function() end

	RynGateMenu.SteamIDInput = RynGateMenu.SteamIDPanel:Add("DTextEntry")
	RynGateMenu.SteamIDInput:Dock(LEFT)
	RynGateMenu.SteamIDInput:SetText("Steam ID")
	RynGateMenu.SteamIDInput:DockMargin(0, 0, 8, 0)
	RynGateMenu.SteamIDInput:SetAllowNonAsciiCharacters(false)
	RynGateMenu.SteamIDInput:SetWide(RynGateMenu.SteamIDPanel:GetWide() * 0.4)

	RynGateMenu.SteamIDComboBox = RynGateMenu.SteamIDPanel:Add("DComboBox")
	RynGateMenu.SteamIDComboBox:Dock(LEFT)
	RynGateMenu.SteamIDComboBox:SetText("Steam ID")
	RynGateMenu.SteamIDComboBox:DockMargin(4, 0, 0, 0)
	RynGateMenu.SteamIDComboBox:SetWide(RynGateMenu.SteamIDPanel:GetWide() * 0.4)
	function RynGateMenu.SteamIDComboBox:OnSelect(index, value, data)
		local str = string.gsub(value, "%s?%(STEAM_.*%)", "")
		RynGateMenu.SteamIDInput:SetText(str .. "," .. data)
	end

	for k, v in pairs(player.GetHumans()) do
		RynGateMenu.SteamIDComboBox:AddChoice(v:Nick() .. " (" .. v:SteamID() .. ")", v:SteamID())
	end

	RynGateMenu.SteamIDAddButton = RynGateMenu.SteamIDPanel:Add("DButton")
	RynGateMenu.SteamIDAddButton:SetText("Add")
	RynGateMenu.SteamIDAddButton:Dock(RIGHT)
	RynGateMenu.SteamIDAddButton:SetWide(RynGateMenu.SteamIDPanel:GetWide() * 0.15)
	function RynGateMenu.SteamIDAddButton:DoClick()
		local expl = string.Explode(",", RynGateMenu.SteamIDInput:GetText())

		local name = (expl[2] != nil and expl[1]) or ""
		local steamID = expl[2] or expl[1]

		for k, v in pairs(RynGateMenu.SteamIDList.Lines) do
			if steamID == v:GetColumnText(2) then
				Derma_Message("The SteamID \"" .. steamID .. "\" is already in the allowed list!", "Couldn't add SteamID", "Ok")
				return
			end
		end

		RynGateMenu.SteamIDList:AddLine(name, steamID)
	end

	local allowedSteamIDs = util.JSONToTable((gate:GetAllowedSteamIDs() != "" and gate:GetAllowedSteamIDs()) or "{}")

	for i = 1, table.Count(allowedSteamIDs) do
		if allowedSteamIDs[i].steamid then
			RynGateMenu.SteamIDList:AddLine(allowedSteamIDs[i].name or "", allowedSteamIDs[i].steamid)
		end
	end

	allowedSteamIDs = nil

	RynGateMenu.SteamIDPanel:SizeToContentsY()

	RynGateMenu.SteamIDHelpLbl = RynGateMenu.LeftPanel:Add("DLabel")
	RynGateMenu.SteamIDHelpLbl:SetText("To add a SteamID, type the steamid above (if you want the name in the list,\ntype it before the steamid followed by a comma\ne.g. \"" .. ply:Name() .. "," .. ply:SteamID() .. "\") or select from one the list.")
	RynGateMenu.SteamIDHelpLbl:Dock(TOP)
	RynGateMenu.SteamIDHelpLbl:DockMargin(0, 0, 0, 4)
	RynGateMenu.SteamIDHelpLbl:SetWide(RynGateMenu.SteamIDPanel:GetWide())
	RynGateMenu.SteamIDHelpLbl:SizeToContentsY()

	-------- CombineFence Checkbox
	RynGateMenu.FencePanel = RynGateMenu.LeftPanel:Add("DPanel")
	RynGateMenu.FencePanel:Dock(TOP)
	RynGateMenu.FencePanel:DockMargin(0, 2, 0, 2)
	RynGateMenu.FencePanel:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.FencePanel.Paint = function() end

	RynGateMenu.FenceCheckBox = RynGateMenu.FencePanel:Add("DCheckBoxLabel")
	RynGateMenu.FenceCheckBox:SetText("Enable combine fence decoration")
	RynGateMenu.FenceCheckBox:DockMargin(0, 5, 0, 0)
	RynGateMenu.FenceCheckBox:Dock(LEFT)
	RynGateMenu.FenceCheckBox:SetChecked(gate:GetUseCombineFence() or false)
	RynGateMenu.FenceCheckBox:SetWide(RynGateMenu.FencePanel:GetWide()/2.75)

	RynGateMenu.FenceComboBox = RynGateMenu.FencePanel:Add("DComboBox")
	RynGateMenu.FenceComboBox:SetTooltip("Orientation of the Combine Fence.\n(NOTE: This also changes the orientation of the text)")
	RynGateMenu.FenceComboBox:Dock(RIGHT)
	RynGateMenu.FenceComboBox:SetWide(RynGateMenu.FencePanel:GetWide()/3.25)
	RynGateMenu.FenceComboBox:AddChoice("Bottom to top (DEFAULT)", COMBINE_ORIENTATION_DEFAULT, false)
	RynGateMenu.FenceComboBox:AddChoice("Right to left", COMBINE_ORIENTATION_NINETY_ROLL, false)
	RynGateMenu.FenceComboBox:ChooseOptionID(gate:GetCombineOrientation())

	RynGateMenu.FenceLbl = RynGateMenu.FencePanel:Add("DLabel")
	RynGateMenu.FenceLbl:SetText("Fence orientation: ")
	RynGateMenu.FenceLbl:Dock(RIGHT)
	RynGateMenu.FenceLbl:SizeToContentsX()

	RynGateMenu.FencePanel:SizeToContentsY()

	-------- CanShootThrough Checkbox
	local canShootDisabled = RynGateConfig.CanBreak and ((RynGateConfig.CanBreakAdmin and gate:GetIsServerOwned()) or !gate:GetIsServerOwned())

	RynGateMenu.CanShootCheckBox = RynGateMenu.LeftPanel:Add("DCheckBoxLabel")
	RynGateMenu.CanShootCheckBox:SetText("Can (all) players shoot through this?")
	RynGateMenu.CanShootCheckBox:SetTooltip("Disabling will allow only the teams allowed to enter to shoot through.")
	RynGateMenu.CanShootCheckBox:Dock(TOP)
	RynGateMenu.CanShootCheckBox:DockMargin(0, 2, 0, 2)
	RynGateMenu.CanShootCheckBox:SetChecked(gate:GetCanShootThrough() or false)
	RynGateMenu.CanShootCheckBox:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.CanShootCheckBox:SetDisabled(canShootDisabled)
	if canShootDisabled then
		RynGateMenu.CanShootCheckBox:SetChecked(false)

		RynGateMenu.CanShootLbl = RynGateMenu.LeftPanel:Add("DLabel")
		RynGateMenu.CanShootLbl:SetText("Configuring whether or not this gate can be shot through is disabled due to it being breakable.")
		RynGateMenu.CanShootLbl:Dock(TOP)
		RynGateMenu.CanShootLbl:SizeToContentsX()
	end

	-------- Allow NPCs Checkbox
	RynGateMenu.NPCCheckBox = RynGateMenu.LeftPanel:Add("DCheckBoxLabel")
	RynGateMenu.NPCCheckBox:SetText("Allow all NPCs through this gate")
	RynGateMenu.NPCCheckBox:Dock(TOP)
	RynGateMenu.NPCCheckBox:DockMargin(0, 2, 0, 2)
	RynGateMenu.NPCCheckBox:SetChecked(gate:GetAllowNPCs())
	RynGateMenu.NPCCheckBox:SetWide(RynGateMenu.LeftPanel:GetWide())

	-------- Allow Vehicles Checkbox
	RynGateMenu.VehicleCheckBox = RynGateMenu.LeftPanel:Add("DCheckBoxLabel")
	RynGateMenu.VehicleCheckBox:SetText("Allow vehicles driven by members of the selected teams through this gate")
	RynGateMenu.VehicleCheckBox:SetTooltip("Do note that this doesn't check any passengers in vehicles.")
	RynGateMenu.VehicleCheckBox:Dock(TOP)
	RynGateMenu.VehicleCheckBox:DockMargin(0, 2, 0, 2)
	RynGateMenu.VehicleCheckBox:SetChecked(gate:GetAllowVehicles() or false)
	RynGateMenu.VehicleCheckBox:SetWide(RynGateMenu.LeftPanel:GetWide())

	-------- Model Selection
	RynGateMenu.ModelLbl = RynGateMenu.LeftPanel:Add("DLabel")
	RynGateMenu.ModelLbl:SetText("Model: ")
	RynGateMenu.ModelLbl:DockMargin(0, 4, 0, 0)
	RynGateMenu.ModelLbl:Dock(TOP)

	RynGateMenu.ModelScroll = RynGateMenu.LeftPanel:Add("DScrollPanel")
	RynGateMenu.ModelScroll:Dock(TOP)
	RynGateMenu.ModelScroll:SetTall(RynGateConfig.ModelIconSize * 2 + 8)
	/*Scroll:SetSize( 355, 200 )
	Scroll:SetPos( 10, 30 )*/

	RynGateMenu.ModelList = RynGateMenu.ModelScroll:Add("DIconLayout")
	RynGateMenu.ModelList:Dock(FILL)
	RynGateMenu.ModelList:SetSpaceY( 5 )
	RynGateMenu.ModelList:SetSpaceX( 5 )
	RunConsoleCommand("cl_ryngate_model", gate:GetModel())

	for i = 1, table.Count(RynGateConfig.ModelList) do
		local modelIcon = RynGateMenu.ModelList:Add("SpawnIcon")
		modelIcon:SetModel(RynGateConfig.ModelList[i])
		modelIcon:SetSize(RynGateConfig.ModelIconSize, RynGateConfig.ModelIconSize)
		modelIcon.model = RynGateConfig.ModelList[i]
		modelIcon.DoClick = function(me)
			RunConsoleCommand("cl_ryngate_model", me.model)
		end
	end

	-------- Text Area
	RynGateMenu.TextLbl = RynGateMenu.LeftPanel:Add("DLabel")
	RynGateMenu.TextLbl:SetText("Text: ")
	RynGateMenu.TextLbl:Dock(TOP)

	RynGateMenu.TextArea = RynGateMenu.LeftPanel:Add("DTextEntry")
	RynGateMenu.TextArea:Dock(TOP)
	RynGateMenu.TextArea:SetMultiline(true)
	RynGateMenu.TextArea:SetTall(48)
	RynGateMenu.TextArea:SetText(gate:GetText())

	-------- Text Alignment
	RynGateMenu.TextAlignPanel = RynGateMenu.LeftPanel:Add("DPanel")
	RynGateMenu.TextAlignPanel:Dock(TOP)
	RynGateMenu.TextAlignPanel.Paint = function() end

	RynGateMenu.TextAlignLbl = RynGateMenu.TextAlignPanel:Add("DLabel")
	RynGateMenu.TextAlignLbl:SetText("Text alignment: ")
	RynGateMenu.TextAlignLbl:SizeToContentsX()
	RynGateMenu.TextAlignLbl:Dock(LEFT)

	RynGateMenu.TextAlignCombo = RynGateMenu.TextAlignPanel:Add("DComboBox")
	RynGateMenu.TextAlignCombo:Dock(LEFT)
	RynGateMenu.TextAlignCombo:AddChoice("Left", 1)
	RynGateMenu.TextAlignCombo:AddChoice("Center", 2, true)
	RynGateMenu.TextAlignCombo:AddChoice("Right", 3)
	RynGateMenu.TextAlignCombo:ChooseOptionID(gate:GetTextAlignment() or RynGateConfig.DefaultTextAlignment)

	RynGateMenu.TextAlignPanel:SizeToContents()
	RynGateMenu.TextAlignPanel:DockMargin(0, 4, 0, 2)

	-------- Text Positions
	RynGateMenu.TextPosX = RynGateMenu.LeftPanel:Add("RYNSlider")
	RynGateMenu.TextPosX:Dock(TOP)
	RynGateMenu.TextPosX:SetMinMax(-1, 1)
	RynGateMenu.TextPosX:SetDecimals(2)
	RynGateMenu.TextPosX:DockMargin(0, 4, 0, 6)
	RynGateMenu.TextPosX:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.TextPosX:SetText("Text X Position")
	RynGateMenu.TextPosX:SetValue(gate:GetTextPosX() or 0)

	RynGateMenu.TextPosY = RynGateMenu.LeftPanel:Add("RYNSlider")
	RynGateMenu.TextPosY:Dock(TOP)
	RynGateMenu.TextPosY:SetMinMax(-1, 1)
	RynGateMenu.TextPosY:SetDecimals(2)
	RynGateMenu.TextPosY:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.TextPosY:SetText("Text Y Position")
	RynGateMenu.TextPosY:SetValue(gate:GetTextPosY() or 0)

	-------- Text Scale
	RynGateMenu.TextScale = RynGateMenu.LeftPanel:Add("RYNSlider")
	RynGateMenu.TextScale:Dock(TOP)
	RynGateMenu.TextScale:SetMinMax(RynGateConfig.MinTextScale, RynGateConfig.MaxTextScale)
	RynGateMenu.TextScale:SetDecimals(1)
	RynGateMenu.TextScale:DockMargin(0, 4, 0, 0)
	RynGateMenu.TextScale:SetWide(RynGateMenu.LeftPanel:GetWide())
	RynGateMenu.TextScale:SetText("Text Scale")
	RynGateMenu.TextScale:SetValue(gate:GetTextScale() or 0)

	-------- Text Should Fade
	RynGateMenu.TextShouldFade = RynGateMenu.LeftPanel:Add("DCheckBoxLabel")
	RynGateMenu.TextShouldFade:SetText("Should the text fade over distance?")
	RynGateMenu.TextShouldFade:SetTooltip("If not, it'll suddenly disappear")
	RynGateMenu.TextShouldFade:SetChecked(gate:GetTextShouldFade())
	RynGateMenu.TextShouldFade:Dock(TOP)
	RynGateMenu.TextShouldFade:DockMargin(0, 6, 0, 0)
	RynGateMenu.TextShouldFade:SetWide(RynGateMenu.LeftPanel:GetWide())

	-------- Material Selection
	RynGateMenu.MatLbl = RynGateMenu.RightPanel:Add("DLabel")
	RynGateMenu.MatLbl:SetText("Material: ")
	RynGateMenu.MatLbl:Dock(TOP)

	RynGateMenu.MatSelect = RynGateMenu.RightPanel:Add("MatSelect")
	RynGateMenu.MatSelect:Dock(TOP)
	RynGateMenu.MatSelect:SetItemWidth(RynGateConfig.MaterialIconSize)
	RynGateMenu.MatSelect:SetItemHeight(RynGateConfig.MaterialIconSize)
	RynGateMenu.MatSelect:SetConVar("cl_ryngate_material")
	RunConsoleCommand("cl_ryngate_material", gate:GetMaterial())

	local materials = list.Get( "OverrideMaterials" )

	for i = 1, table.Count(materials) do
		RynGateMenu.MatSelect:AddMaterial(materials[i], materials[i])
	end

	materials = nil

	RynGateMenu.MatSelect:TestForChanges()

	-------- Color Selection
	local colorSelectSize = 128 * 1.34

	RynGateMenu.ColorLbl = RynGateMenu.RightPanel:Add("DLabel")
	RynGateMenu.ColorLbl:SetText("Color: ")
	RynGateMenu.ColorLbl:Dock(TOP)

	RynGateMenu.ColorPanel = RynGateMenu.RightPanel:Add("DPanel")
	RynGateMenu.ColorPanel:SetTall(colorSelectSize)
	RynGateMenu.ColorPanel:Dock(TOP)
	RynGateMenu.ColorPanel.Paint = function() end

	local gateColor = gate:GetColor()
	gateColor.a = (gate:GetCustomAlpha() * 255) or gateColor.a

	RynGateMenu.ColorSelect = RynGateMenu.ColorPanel:Add("DColorMixer")
	RynGateMenu.ColorSelect:SetSize(colorSelectSize * 1.5, colorSelectSize)
	RynGateMenu.ColorSelect:Dock(LEFT)
	RynGateMenu.ColorSelect:SetColor(gateColor)

	-------- Text Color Selection
	RynGateMenu.TextColorLbl = RynGateMenu.RightPanel:Add("DLabel")
	RynGateMenu.TextColorLbl:SetText("Text color: ")
	RynGateMenu.TextColorLbl:Dock(TOP)

	RynGateMenu.TextColorPanel = RynGateMenu.RightPanel:Add("DPanel")
	RynGateMenu.TextColorPanel:SetTall(colorSelectSize)
	RynGateMenu.TextColorPanel:Dock(TOP)
	RynGateMenu.TextColorPanel.Paint = function() end

	RynGateMenu.TextColorSelect = RynGateMenu.TextColorPanel:Add("DColorMixer")
	RynGateMenu.TextColorSelect:SetSize(colorSelectSize * 1.5, colorSelectSize)
	RynGateMenu.TextColorSelect:Dock(LEFT)
	RynGateMenu.TextColorSelect:SetColor(gate:GetTextColor())

	-------- ULib Groups selection
	if ulibExists then
		RynGateMenu.ULibLbl = RynGateMenu.RightPanel:Add("DLabel")
		RynGateMenu.ULibLbl:SetText("ULX/ULib Groups: (Selected ones CAN go through the gate)")
		RynGateMenu.ULibLbl:Dock(TOP)
		RynGateMenu.ULibLbl:DockMargin(0, 6, 0, 0)
		RynGateMenu.ULibLbl:SetWide(RynGateMenu.RightPanel:GetWide())

		RynGateMenu.ULibPanels = RynGateMenu.RightPanel:Add("DPanel")
		RynGateMenu.ULibPanels:SetWide(RynGateMenu.LeftPanel:GetWide())
		RynGateMenu.ULibPanels:Dock(TOP)
		RynGateMenu.ULibPanels.columns = {}
		RynGateMenu.ULibPanels.groups = {}
		RynGateMenu.ULibPanels.Paint = function(me, w, h)
			draw.RoundedBox(2, 0, 0, w, h, Color(200, 200, 200))
		end

		for i = 1, 3 do
			RynGateMenu.ULibPanels.columns[i] = RynGateMenu.ULibPanels:Add("DPanel")
			RynGateMenu.ULibPanels.columns[i]:Dock(LEFT)
			RynGateMenu.ULibPanels.columns[i]:SetWide(RynGateMenu.ULibPanels:GetWide()/3)
			RynGateMenu.ULibPanels.columns[i].Paint = function() end
		end

		local groups = ULib.ucl.groups

		local size = 0
		local currentGroup = 0
		local currentColumn = 0
		local groupCount = table.Count(groups)

		for k, v in pairs(groups) do
			if currentGroup % math.ceil(groupCount/3) == 0 then
				currentColumn = currentColumn + 1

				if currentColumn > 3 then
					currentColumn = 1
				end
			end

			currentGroup = currentGroup + 1
			local checklbl = RynGateMenu.ULibPanels.columns[currentColumn]:Add("DCheckBoxLabel")
			checklbl:SetText(k)
			checklbl.group = k
			checklbl:Dock(TOP)
			checklbl:SetTextColor(Color(50, 50, 50))
			checklbl:SizeToContents()
			checklbl:DockMargin(10, 3, 10, 3)
			checklbl:SetChecked(table.HasValue(RynGateMenu.previouslyAllowedGroups, k))

			table.insert(RynGateMenu.ULibPanels.groups, checklbl)

			if currentColumn == 1 then
				size = size + checklbl:GetTall() + 3
			end
		end

		RynGateMenu.ULibPanels:SetTall(size + 6)

		for i = 1, 3 do
			RynGateMenu.TeamPanels.columns[i]:SetTall(size + 6)
		end
	end

	-------- UTime section
	if utimeExists then
		RynGateMenu.UTimeSlider = RynGateMenu.RightPanel:Add("RYNSlider")
		RynGateMenu.UTimeSlider:DockMargin(0, 8, 0, 2)
		RynGateMenu.UTimeSlider:Dock(TOP)
		RynGateMenu.UTimeSlider:SetText("UTime: Allow players with a minimum of this playtime (in hours) (on the server) through this gate.\n(Has to be above 0 to have any effect)")
		RynGateMenu.UTimeSlider:SetMinMax(0, RynGateConfig.MaxPlaytime)
		RynGateMenu.UTimeSlider:SetDecimals(2)
		RynGateMenu.UTimeSlider:SetWide(RynGateMenu.RightPanel:GetWide())
		RynGateMenu.UTimeSlider:SetValue(gate:GetMinPlayTime())
	end

	-------- Admin & Server Gate only options

	if ply:IsAdmin() then
		-------- Admin only options:

		---- Is personal/server owned
		RynGateMenu.ServerOwnedCheckBox = RynGateMenu.RightPanel:Add("DCheckBoxLabel")
		RynGateMenu.ServerOwnedCheckBox:SetText("Is this gate owned by the server?")
		RynGateMenu.ServerOwnedCheckBox:SetTooltip("Enabling this allows all admins to configure the gate and you will no longed be the owner of the gate.")
		RynGateMenu.ServerOwnedCheckBox:Dock(TOP)
		RynGateMenu.ServerOwnedCheckBox:DockMargin(0, 8, 0, 2)
		RynGateMenu.ServerOwnedCheckBox:SetChecked(gate:GetIsServerOwned() or false)
		RynGateMenu.ServerOwnedCheckBox:SetWide(RynGateMenu.RightPanel:GetWide())

		if gate:GetIsServerOwned() then
			-------- Server Gate only options:

			---- Can be bypassed with swep?
			RynGateMenu.SWEPBypassCheckBox = RynGateMenu.RightPanel:Add("DCheckBoxLabel")
			RynGateMenu.SWEPBypassCheckBox:SetText("Can the weapons designed to bypass team gates bypass this gate?")
			--RynGateMenu.SWEPBypassCheckBox:SetTooltip("Enabling this allows all admins to configure the gate and you will no longed be the owner of the gate.")
			RynGateMenu.SWEPBypassCheckBox:Dock(TOP)
			RynGateMenu.SWEPBypassCheckBox:DockMargin(0, 8, 0, 2)
			RynGateMenu.SWEPBypassCheckBox:SetChecked(gate:GetSWEPCanBypass() or false)
			RynGateMenu.SWEPBypassCheckBox:SetWide(RynGateMenu.RightPanel:GetWide())
		end
	end

	-------- END OF THE MENU

	RynGateMenu:UpdateDermaSkin()
end)
