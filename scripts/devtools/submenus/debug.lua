----
-- Debug submenu.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-dev-tools](https://github.com/victorpopkov/dst-mod-dev-tools)
--
-- @module submenus.Debug
-- @see DevTools.CreateSubmenuInstFromData
-- @see menu.Menu
-- @see menu.Menu.AddSubmenu
-- @see menu.Submenu
-- @see submenus.Debug.DebugEventsOption
-- @see submenus.Debug.DebugOption
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1.0-alpha
----
require "devtools/constants"

local DebugEventsOption = require "devtools/submenus/debug/debugeventsoption"
local DebugOption = require "devtools/submenus/debug/debugoption"

local _TOGGLE_ALL_EVENTS = {
    ["ThePlayer"] = { "ActivatePlayer", "DeactivatePlayer" },
    ["ThePlayer.player_classified"] = { "ActivatePlayerClassified", "DeactivatePlayerClassified" },
    ["TheWorld"] = { "ActivateWorld", "DeactivateWorld" },
}

local _TOGGLE_ALL_REMOTES = {
    "RemoteActionButton",
    "RemoteAttackButton",
    "RemoteBufferedAction",
    "RemoteDirectWalking",
    "RemoteDragWalking",
    "RemoteDropItemFromInvTile",
    "RemoteInspectButton",
    "RemoteInspectItemFromInvTile",
    "RemoteMakeRecipeAtPoint",
    "RemoteMakeRecipeFromMenu",
    "RemotePredictWalking",
    "RemoteStopWalking",
    "RemoteUseItemFromInvTile",
}

local _TOGGLE_ALL_MOUSE_CLICKS = { "lmb", "rmb" }

return {
    label = "Debug",
    name = "DebugSubmenu",
    on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_PLAYER,
    options = {
        {
            type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
            options = {
                label = {
                    name = "Toggle All (Events)",
                    left = true,
                },
                name = "DebugToggleAllEvents",
                on_get_fn = function(_, submenu)
                    for debug_key, _ in pairs(_TOGGLE_ALL_EVENTS) do
                        if not submenu.debug:IsDebug(debug_key) then
                            return false
                        end
                    end
                    return true
                end,
                on_set_fn = function(_, submenu, value)
                    for debug_key, functions in pairs(_TOGGLE_ALL_EVENTS) do
                        if value ~= submenu.debug:IsDebug(debug_key) then
                            submenu.debug:SetIsDebug(debug_key, value)
                            local events = submenu.debug:GetEvents()
                            events[value and functions[1] or functions[2]](events)
                        end
                    end
                end,
            },
        },
        DebugOption("Toggle All (Mouse Clicks)", _TOGGLE_ALL_MOUSE_CLICKS),
        DebugOption(
            "Toggle All (Remotes)",
            _TOGGLE_ALL_REMOTES,
            MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NOT_MASTER_SIM
        ),
        DebugOption(
            "Toggle All (SendRPCToServer)",
            "rpc",
            MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NOT_MASTER_SIM
        ),
        { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
        {
            type = MOD_DEV_TOOLS.OPTION.SUBMENU,
            options = {
                label = "Events",
                name = "DebugEventsSubmenu",
                options = {
                    DebugEventsOption("ThePlayer", "ActivatePlayer", "DeactivatePlayer"),
                    DebugEventsOption(
                        "ThePlayer.player_classified",
                        "ActivatePlayerClassified",
                        "DeactivatePlayerClassified"
                    ),
                    { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                    DebugEventsOption("TheWorld", "ActivateWorld", "DeactivateWorld"),
                },
            },
        },
        {
            type = MOD_DEV_TOOLS.OPTION.SUBMENU,
            options = {
                label = "Mouse Clicks",
                name = "DebugMouseClicksSubmenu",
                options = {
                    DebugOption("Left Mouse Button (LMB)", "lmb"),
                    DebugOption("Right Mouse Button (RMB)", "rmb"),
                },
            },
        },
        {
            type = MOD_DEV_TOOLS.OPTION.SUBMENU,
            options = {
                label = "Remote",
                name = "DebugRemoteSubmenu",
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NOT_MASTER_SIM,
                options = {
                    DebugOption("Action Button", "RemoteActionButton"),
                    DebugOption("Attack Button", "RemoteAttackButton"),
                    DebugOption("Inspect Button", "RemoteInspectButton"),
                    { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                    DebugOption("Direct Walking", "RemoteDirectWalking"),
                    DebugOption("Drag Walking", "RemoteDragWalking"),
                    DebugOption("Predict Walking", "RemotePredictWalking"),
                    DebugOption("Stop Walking", "RemoteStopWalking"),
                    { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                    DebugOption("Drop Item From Inventory Tile", "RemoteDropItemFromInvTile"),
                    DebugOption("Inspect Item From Inventory Tile", "RemoteInspectItemFromInvTile"),
                    DebugOption("Use Item From Inventory Tile", "RemoteUseItemFromInvTile"),
                    { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                    DebugOption("Make Recipe At Point", "RemoteMakeRecipeAtPoint"),
                    DebugOption("Make Recipe From Menu", "RemoteMakeRecipeFromMenu"),
                    { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                    DebugOption("Buffered Action", "RemoteBufferedAction"),
                },
            },
        },
    },
}
