--[[
Allows admins to remove or confiscate weapons from players.
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

print("This server is running AWC by Rynoxx. Source code is available at https://github.com/Rynoxx/gmod-addon-collection")

AddCSLuaFile()

CreateConVar( "awc_allowed_usergroup", "superadmin", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Which usergroup should be allowed to check and confiscate weapons using the Admin Check & Confiscate weapons addon?")

local AdminCCConVar = GetConVar("awc_allowed_usergroup")

properties.Add("awc_contextmenu", {
	MenuLabel = "#awc_name",
	Order = 2000,
	MenuIcon = "icon16/gun.png",
	Filter = function(self, ent, ply)
		local ply = ply or LocalPlayer()

		if !IsValid(ent) or !IsValid(ply) then return false end

		return ent:IsPlayer() and ((ply.CheckGroup and ply:CheckGroup(AdminCCConVar:GetString())) or ply:IsUserGroup(AdminCCConVar:GetString()))
	end,
	Action = function(self, ent, trace, bDo, wepStr, action)
		local ply = LocalPlayer()

		if !self:Filter(ent, ply) then return end

		if CLIENT and !bDo then
			openCheckAndConfiscationMenu(self, ent)
		elseif bDo then
			self:MsgStart()
				net.WriteEntity( ent )
				net.WriteString( wepStr )
				net.WriteString( action )
			self:MsgEnd()
		end
	end,
	Receive = function(self, length, ply)
		local ent = net.ReadEntity()
		local weapon = net.ReadString()
		local action = net.ReadString()

		if !IsValid(ent) then return end

		if self:Filter(ent, ply) then
			if action == "remove" then
				ent:StripWeapon(weapon)
			elseif action == "take" then
				ent:StripWeapon(weapon)
				ply:Give(weapon)
			elseif action == "drop" then
				if ent.dropDRPWeapon then
					ent:dropDRPWeapon(ent:GetWeapon(weapon))
				else
					ent:DropNamedWeapon(weapon)
				end
			end

			if DarkRP.notify then
				DarkRP.notify(ent, NOTIFY_ERROR, 5, "An admin has " .. ((action == "drop" and "dropped") or ((action == "take" and "taken") or "removed")) .. " your " .. weapon)
			else
				ent:SendLua([[notification.AddLegacy("An admin has ]] .. ((action == "drop" and "dropped") or ((action == "take" and "taken") or "removed")) .. [[ your ]] .. weapon .. [[", NOTIFY_ERROR, 5)]])
			end
		end
	end
})

if CLIENT then
	language.Add("awc_name", "Check & Confiscate Weapons")
	language.Add("awc_info", "Click on the weapons to show you the options available.")

	language.Add("awc_remove_weapon", "Remove the weapon.")
	language.Add("awc_take_weapon", "Take the weapon.")
	language.Add("awc_drop_weapon", "Drop the weapon.")

	local borderSize = 2
	local borderColor = Color(0, 0, 0, 200)
	local labelBackgroundColor = Color(0, 0, 0, 220)

	local function drawOutlinedBox( x, y, w, h, thickness, clr )
		surface.SetDrawColor( clr )
		for i=0, thickness - 1 do
			surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
		end
	end

	function openCheckAndConfiscationMenu(property, ply)
		if !property then return end
		if !property:Filter(ply, LocalPlayer()) then return end

		local ccFrame = vgui.Create("DFrame")
		ccFrame:SetSize(ScrW()/2, ScrH()/2)
		ccFrame:SetTitle(language.GetPhrase("awc_name") .. " - " .. ply:Nick())
		ccFrame:Center()
		ccFrame:MakePopup()
		ccFrame.property = property

		ccFrame.InfoText = vgui.Create("DLabel", ccFrame)
		ccFrame.InfoText:SetPos(5, 30)
		ccFrame.InfoText:SetSize(ccFrame:GetWide() - 10, 16)
		ccFrame.InfoText:SetText("#awc_info")
		ccFrame.InfoText:SizeToContentsY()

		ccFrame.Scroll = vgui.Create("DScrollPanel", ccFrame)
		ccFrame.Scroll:SetSize(ccFrame:GetWide() - 10, ccFrame:GetTall() - 50 - ccFrame.InfoText:GetTall())
		ccFrame.Scroll:SetPos(5, 35 + ccFrame.InfoText:GetTall())

		function ccFrame:Reset()
			self.Scroll:Clear()

			self.List = vgui.Create("DIconLayout", self.Scroll)
			self.List:SetSize(self.Scroll:GetWide() - 15, self.Scroll:GetTall())
			self.List:SetPos(0, 0)
			self.List:SetSpaceY(5)
			self.List:SetSpaceX(5)

			local weapons = ply:GetWeapons()

			for k, v in pairs(weapons) do
				local ListItem = self.List:Add("DPanel")
				ListItem:SetSize(128, 128)
				ListItem.Paint = function(me, w, h)
					drawOutlinedBox(0, 0, w, h, borderSize, borderColor)
				end

				ListItem.OnCursorEntered = function(me)
					if !IsValid(me.LabelPanel) then return end

					me.LabelPanel:SetVisible(false)
				end

				ListItem.OnCursorExited = function(me)
					if !IsValid(me.LabelPanel) then return end
					me.LabelPanel:SetVisible(true)
				end

				local IconPathNew = "materials/entities/" .. v:GetClass() .. ".png"
				local IconPathOld = "vgui/entities/" .. v:GetClass() .. ".vmt"

				local function doPerformAction(strAction)
					property:Action(ply, LocalPlayer():GetEyeTrace(), true, v:GetClass(), strAction)
					self.List:Clear()
					timer.Simple(LocalPlayer():Ping()/100, function()
						if IsValid(self) then
							self:Reset()
						end
					end)
				end

				ListItem.Icon = vgui.Create("DImageButton", ListItem)
				ListItem.Icon:SetSize(ListItem:GetWide() - (borderSize * 2), ListItem:GetTall() - (borderSize * 2))
				ListItem.Icon:SetPos(borderSize, borderSize)
				ListItem.Icon:SetImage((file.Exists(IconPathNew, "GAME") and IconPathNew) or IconPathOld)
				ListItem.Icon.DoClick = function(me)
					local Menu = DermaMenu()

					Menu:AddOption("#awc_remove_weapon", function()
						doPerformAction("remove")
					end):SetIcon("icon16/delete.png")

					Menu:AddOption("#awc_take_weapon", function()
						doPerformAction("take")
					end):SetIcon("icon16/arrow_undo.png")

					Menu:AddOption("#awc_drop_weapon", function()
						doPerformAction("drop")
					end):SetIcon("icon16/arrow_down.png")

					Menu:Open()
				end

				ListItem.Icon.OnCursorEntered = function(me)
					me:GetParent().LabelPanel:SetVisible(false)
				end

				ListItem.Icon.OnCursorExited = function(me)
					me:GetParent().LabelPanel:SetVisible(true)
				end

				ListItem.LabelPanel = vgui.Create("DPanel", ListItem)
				ListItem.LabelPanel:SetSize(ListItem:GetWide() - (borderSize * 2), 16)
				ListItem.LabelPanel:SetPos(borderSize, ListItem:GetTall() - ListItem.LabelPanel:GetTall() - borderSize)
				ListItem.LabelPanel.Paint = function(me, w, h)
					draw.RoundedBox(0, 0, 0, w, h, labelBackgroundColor)
				end
				ListItem.LabelPanel.OnCursorEntered = function(me)
					me:SetVisible(false)
				end

				ListItem.LabelPanel.OnCursorExited = function(me)
					me:SetVisible(true)
				end

				ListItem.Label = vgui.Create("DLabel", ListItem.LabelPanel)
				ListItem.Label:SetText(v:GetPrintName())
				ListItem.Label:SizeToContents()
				ListItem.Label:Center()
			end
		end

		ccFrame:Reset()
	end
end
