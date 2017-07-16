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

local math = math
local rynSlider = {}

AccessorFunc(rynSlider, "i_MinValue", "Min")
AccessorFunc(rynSlider, "i_MaxValue", "Max")
AccessorFunc(rynSlider, "i_Val", "Value")
AccessorFunc(rynSlider, "i_Decimals", "Decimals")
AccessorFunc(rynSlider, "s_ConVar", "ConVar")

function rynSlider:Init()
	self.i_Decimals = 0
	self.i_MinValue = -1
	self.i_MaxValue = 1
	self.font = "default"
	self.h = 24
	self.panelHeightDecrease = 2

	self.label = self:Add("DLabel")
	self.label:SetText("")
	self.label:SetTall(0)
	self.label:Dock(TOP)
	self.label:DockMargin(0, 0, 0, 2)

	self.panel = self:Add("DPanel")
	self.panel.Paint = function() end
	self.panel:Dock(TOP)

	self.slider = self.panel:Add("DSlider")
	self.slider:Dock(RIGHT)
	self.slider:SetTrapInside(true)
	self.slider:SetSize(math.Clamp(self:GetWide(), 50, ScrW()) * 0.8, self.slider:GetTall())
	self.slider.TranslateValues = function(me, x, y) return self:TranslateValues(x, y) end
	Derma_Hook( self.slider, "Paint", "Paint", "NumSlider" )

	self.oldSetWide = self.oldSetWide or self.SetWide
	self.oldSetSize = self.oldSetSize or self.SetSize
	self.oldSetTall = self.oldSetTall or self.SetTall

	self.SetWide = function(me, width)
		me.panel:SetWide(width)
		me.slider:SetWide(me.panel:GetWide() * 0.8)
		me.wang:SetWide(me.panel:GetWide() * 0.15)
		me:oldSetWide(width)
	end

	self.SetSize = function(me, w, h)
		me:oldSetSize(w, h)
		me.panel:SetSize(w, h - me.panelHeightDecrease - me.label:GetTall())
		me.slider:SetWide(me.panel:GetWide() * 0.8)
		me.wang:SetWide(me.panel:GetWide() * 0.15)
	end

	self.SetTall = function(me, height)
		me.h = height
		me:oldSetTall(me.h + me.label:GetTall())
		me.panel:SetTall(me.h - me.panelHeightDecrease)
	end

	self.wang = self.panel:Add("DNumberWang")
	self.wang:SetMinMax(self.i_MinValue, self.i_MaxValue)
	self.wang:SetDecimals(self.i_Decimals)
	self.wang:SetAllowNonAsciiCharacters(false)
	self.wang:Dock(LEFT)
	self.wang.OnValueChanged = function(me, val)
		if self:GetValue() == val then return end

		if tonumber(val) > me:GetMax() then
			me:SetFraction(1)
			return
		elseif tonumber(val) < me:GetMin() then
			me:SetFraction(0)
			return
		else
			self:SetValue(val)
		end
	end

	self:SetValue(math.Round((self.i_MaxValue + self.i_MinValue)/2), self.i_Decimals)
	self:SetTall(self.h)
end

function rynSlider:SetText(txt)
	self.label:SetText(txt)
	self.label:SizeToContents()
	self:SetTall(self.h)
end

function rynSlider:GetText()
	return self.label:GetText()
end

function rynSlider:Paint(w, h) end

function rynSlider:SetConVar(str)
	self:SetValue(GetConVarNumber(str))
	self.s_ConVar = str
end

function rynSlider:SetFraction( fFraction )
	self:SetValue( math.Clamp(self.i_MinValue + (fFraction * (self.i_MaxValue - self.i_MinValue)), self.i_MinValue, self.i_MaxValue) )
end

function rynSlider:GetFraction()
	return math.Clamp((self.i_Val - self.i_MinValue) / (self.i_MaxValue - self.i_MinValue), 0, 1)
end

function rynSlider:TranslateValues(x, y)
	self:SetFraction(x)
	return x, y
end

function rynSlider:SetMinMax(min, max)
	self.i_MinValue = math.Clamp(min, min - 1, max - 1)
	self.i_MaxValue = math.Clamp(max, min + 1, max + 1)
	self.slider:SetSlideX(math.Clamp(self.slider:GetSlideX(), 0, 1))
	self.slider:SetNotches(self.i_MaxValue - self.i_MinValue)
	self.wang:SetMinMax(self.i_MinValue, self.i_MaxValue)
	self:SetValue(math.Clamp(self.i_Val, min, max))
end

function rynSlider:SetMin(min)
	self.i_MinValue = math.Clamp(min, min - 1, self.i_MaxValue - 1)
	self.slider:SetNotches(self.i_MaxValue - self.i_MinValue)
	self:SetValue(math.Clamp(self.i_Val, min, self.i_MaxValue))
end

function rynSlider:SetMax(max)
	self.i_MaxValue = math.Clamp(max, self.i_MinValue + 1, max + 1)
	self.slider:SetNotches(self.i_MaxValue - self.i_MinValue)
	self:SetValue(math.Clamp(self.i_Val, self.i_MinValue + 1, max + 1))
end

function rynSlider:GetMinMax()
	return self.i_MinValue, self.i_MaxValue
end

function rynSlider:SetValue(float)
	local oldVal = self.i_Val
	self.i_Val = math.Clamp(math.Round(float, self.i_Decimals), self.i_MinValue, self.i_MaxValue)
	self.slider:SetSlideX(self:GetFraction())

	if oldVal != self.i_Val then
		self.wang:SetFraction(self:GetFraction())

		if self:GetConVar() and self:GetConVar() != "" then
			RunConsoleCommand(self:GetConVar(), self:GetValue())
		end

		if self.OnValueChanged then
			self:OnValueChanged(self.i_Val)
		end
	end
end

function rynSlider:SetDecimals(dec)
	self.i_Decimals = math.max(dec, 0)
	self.wang:SetDecimals(self.i_Decimals)
end

vgui.Register("RYNSlider", rynSlider, "DPanel")
