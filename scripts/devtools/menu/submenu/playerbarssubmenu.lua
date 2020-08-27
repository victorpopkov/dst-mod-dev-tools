----
-- Player bars submenu.
--
-- Extends `menu.submenu.Submenu`.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-dev-tools](https://github.com/victorpopkov/dst-mod-dev-tools)
--
-- @classmod menu.submenu.PlayerBarsSubmenu
-- @see menu.submenu.Submenu
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1.0-alpha
----
require "class"

local Submenu = require "devtools/menu/submenu/submenu"

local PlayerBarsSubmenu = Class(Submenu, function(
    self,
    root,
    devtools,
    worlddevtools,
    playerdevtools,
    screen
)
    Submenu._ctor(self, root, "Player Bars", "PlayerBarsSubmenu", screen, #root + 1)

    -- general
    self.console = playerdevtools.console
    self.devtools = devtools
    self.player = playerdevtools
    self.world = worlddevtools

    if self.world and self.player and self.player:IsAdmin() and self.console and screen then
        self:AddSelectedPlayerLabelPrefix(devtools, playerdevtools)
        self:AddOptions()
        self:AddToRoot()
    end
end)

--- Helpers
-- @section helpers

local function AddFullOption(self, is_inst_in_wereness_form)
    self:AddDoActionOption({
        label = "Full",
        on_accept_fn = function()
            self.console:SetMaxHealthPercent(100)
            self.console:SetHealthPercent(100)
            self.console:SetHungerPercent(100)
            self.console:SetSanityPercent(100)
            self.console:SetMoisturePercent(0)
            self.console:SetTemperature(20)

            if is_inst_in_wereness_form then
                self.console:SetWerenessPercent(100)
            end

            self:UpdateScreen("selected")
        end,
    })
end

local function AddPlayerBarOption(self, label, getter, setter, min, max, step)
    min = min ~= nil and min or 1
    max = max ~= nil and max or 100
    step = step ~= nil and step or 5

    self:AddNumericToggleOption({
        label = label,
        min = min,
        max = max,
        step = step,
        on_cursor_fn = function()
            self:UpdateScreen("selected")
        end,
        on_get_fn = function()
            return math.floor(self.player[getter](self.player))
        end,
        on_set_fn = function(value)
            self.console[setter](self.console, value)
            self:UpdateScreen("selected")
        end,
    })
end

--- General
-- @section general

--- Adds options.
function PlayerBarsSubmenu:AddOptions()
    local player = self.player:GetSelected()
    local is_inst_in_wereness_form = player
        and player:HasTag("werehuman")
        and self.player:GetWerenessMode() ~= 0

    AddFullOption(self, is_inst_in_wereness_form)

    if self.player:IsOwner(player) or not self.player:IsReal(player) then
        self:AddDividerOption()
        AddPlayerBarOption(self, "Health", "GetHealthPercent", "SetHealthPercent")
        AddPlayerBarOption(self, "Hunger", "GetHungerPercent", "SetHungerPercent")
        AddPlayerBarOption(self, "Sanity", "GetSanityPercent", "SetSanityPercent")

        self:AddDividerOption()
        AddPlayerBarOption(self, "Maximum Health", "GetMaxHealthPercent", "SetMaxHealthPercent", 25)

        self:AddDividerOption()
        AddPlayerBarOption(self, "Moisture", "GetMoisturePercent", "SetMoisturePercent", 0)
        AddPlayerBarOption(self, "Temperature", "GetTemperature", "SetTemperature", -20, 90)

        if is_inst_in_wereness_form then
            AddPlayerBarOption(self, "Wereness", "GetWerenessPercent", "SetWerenessPercent")
        end
    end
end

return PlayerBarsSubmenu
