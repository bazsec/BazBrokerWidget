-- SPDX-License-Identifier: GPL-2.0-or-later
---------------------------------------------------------------------------
-- BazBrokerWidget - bridge LibDataBroker-1.1 feeds into BazWidgetDrawers
--
-- Each LDB data object (`type = "data source"` and `type = "launcher"`)
-- becomes its own dockable widget. The user enables/disables/reorders
-- them like any other BWD widget - no special UI for managing the list
-- because BWD already has all of that.
---------------------------------------------------------------------------

local ADDON_NAME = "BazBrokerWidget"

local addon
addon = BazCore:RegisterAddon(ADDON_NAME, {
    title         = "BazBrokerWidget",
    savedVariable = "BazBrokerWidgetDB",
    profiles      = true,
    defaults = {
        showLabel       = true,   -- show the feed's label next to its value
        showIcon        = true,   -- show the feed's icon
        emptyText       = "-",    -- text shown when a feed has no value yet
        autoEnableNew   = true,   -- auto-enable new feeds discovered after login
    },

    slash = { "/bbw", "/bazbroker" },
    commands = {
        list = {
            desc = "Print every LibDataBroker feed currently registered",
            handler = function()
                if addon.PrintFeedList then addon:PrintFeedList() end
            end,
        },
        rescan = {
            desc = "Rebuild widgets for all known LDB feeds (does not lose state)",
            handler = function()
                if addon.RescanFeeds then addon:RescanFeeds() end
            end,
        },
    },

    minimap = {
        label = "BazBrokerWidget",
        icon  = 134390,
    },
})

---------------------------------------------------------------------------
-- LibDataBroker hookup
---------------------------------------------------------------------------

local LDB           = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local registered    = {}  -- [feedName] = true once a widget exists for this feed
local pendingByName = {}  -- [feedName] = dataobj queued before BWD was ready

if not LDB then
    -- LDB couldn't load (extremely unlikely since we embed it). Bail
    -- silently - the addon is still loaded but registers nothing.
    return
end

---------------------------------------------------------------------------
-- Feed handling
---------------------------------------------------------------------------

local function CreateWidgetForFeed(name, dataobj)
    if registered[name] then return end
    if not (addon.BuildFeedWidget) then
        -- Widget.lua hasn't loaded yet - shouldn't happen given TOC order,
        -- but defensive: queue and try again from RescanFeeds.
        pendingByName[name] = dataobj
        return
    end
    addon:BuildFeedWidget(name, dataobj)
    registered[name] = true
end

function addon:RescanFeeds()
    if not LDB then return end
    for name, dataobj in LDB:DataObjectIterator() do
        CreateWidgetForFeed(name, dataobj)
    end
    -- Drain anything that queued up before BWD was ready
    for name, dataobj in pairs(pendingByName) do
        CreateWidgetForFeed(name, dataobj)
        pendingByName[name] = nil
    end
end

function addon:PrintFeedList()
    if not LDB then
        self:Print("LibDataBroker is not available.")
        return
    end
    local count = 0
    self:Print("Registered LibDataBroker feeds:")
    for name, dataobj in LDB:DataObjectIterator() do
        count = count + 1
        local typ = dataobj.type or "unknown"
        local label = dataobj.label or name
        print(string.format("  |cff8888ff%d.|r %s |cff999999(%s)|r - %s",
            count, name, typ, label))
    end
    if count == 0 then
        self:Print("  No feeds registered. Load an addon that publishes LDB data.")
    end
end

---------------------------------------------------------------------------
-- Options pages
---------------------------------------------------------------------------

local function GetLandingPage()
    return BazCore:CreateLandingPage("BazBrokerWidget", {
        subtitle    = "LibDataBroker > BazWidgetDrawers bridge",
        description = "Surfaces every LibDataBroker (LDB) feed as its own " ..
            "dockable widget inside BazWidgetDrawers. Any addon that " ..
            "publishes via LDB - Bagnon, Recount, BugSack, Skada, and " ..
            "many others - appears automatically as a draggable widget " ..
            "you can show, hide, reorder, or float.",
        features = "One BWD widget per LDB feed. " ..
            "Live updates on text/value/icon/label changes. " ..
            "Late-registering feeds are picked up automatically. " ..
            "Click forwards to the feed's launcher action; hover shows " ..
            "the feed's native tooltip.",
        guide = {
            { "Install an LDB addon", "Anything with a minimap data button or LDB-publishing description" },
            { "Open BazWidgetDrawers settings", "Each feed appears as its own widget on the Widgets page" },
            { "Enable / drag / float", "Use BWD's normal widget controls" },
            { "/bbw list", "Prints every feed currently registered for inspection" },
        },
    })
end

local function GetSettingsPage()
    return {
        name = "Settings",
        type = "group",
        args = {
            intro = {
                order = 0.1,
                type  = "lead",
                text  = "Configure how each LibDataBroker feed renders inside its widget.",
            },
            displayHeader = {
                order = 1,
                type  = "header",
                name  = "Display",
            },
            showIcon = {
                order = 2,
                type  = "toggle",
                name  = "Show Icon",
                desc  = "Show the feed's icon at the left of each widget.",
                get   = function() return addon:GetSetting("showIcon") ~= false end,
                set   = function(_, val) addon:SetSetting("showIcon", val) end,
            },
            showLabel = {
                order = 3,
                type  = "toggle",
                name  = "Show Label",
                desc  = "Show the feed's label (e.g. addon name) next to the value.",
                get   = function() return addon:GetSetting("showLabel") ~= false end,
                set   = function(_, val) addon:SetSetting("showLabel", val) end,
            },
            emptyText = {
                order = 4,
                type  = "input",
                name  = "Empty-Value Placeholder",
                desc  = "Shown when a feed has no current value (e.g. before its first update).",
                get   = function() return addon:GetSetting("emptyText") or "-" end,
                set   = function(_, val) addon:SetSetting("emptyText", val) end,
            },

            discoveryHeader = {
                order = 10,
                type  = "header",
                name  = "Discovery",
            },
            autoEnableNew = {
                order = 11,
                type  = "toggle",
                name  = "Auto-Enable New Feeds",
                desc  = "When a new LDB feed registers (after login), enable its widget automatically. Disable to let new feeds default to off.",
                get   = function() return addon:GetSetting("autoEnableNew") ~= false end,
                set   = function(_, val) addon:SetSetting("autoEnableNew", val) end,
            },
            rescanFeeds = {
                order = 12,
                type  = "execute",
                name  = "Rescan Feeds",
                desc  = "Re-check the LDB registry and create widgets for any feeds that were missed.",
                func  = function()
                    if addon.RescanFeeds then addon:RescanFeeds() end
                    addon:Print("Rescan complete.")
                end,
            },
            printFeeds = {
                order = 13,
                type  = "execute",
                name  = "Print Feed List",
                desc  = "Print every LDB feed currently registered to the chat frame.",
                func  = function()
                    if addon.PrintFeedList then addon:PrintFeedList() end
                end,
            },
        },
    }
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

-- Late-arriving feeds: many addons register their LDB data after PLAYER_LOGIN
-- (e.g. inside a delayed init or on first event). Listening for this
-- callback catches them as they appear.
LDB.RegisterCallback(addon, "LibDataBroker_DataObjectCreated", function(_, name, dataobj)
    CreateWidgetForFeed(name, dataobj)
end)

addon.config.onLoad = function(self)
    -- Bottom tab + landing page
    BazCore:RegisterOptionsTable(ADDON_NAME, GetLandingPage)
    BazCore:AddToSettings(ADDON_NAME, "BazBrokerWidget")

    -- General Settings sub-page
    BazCore:RegisterOptionsTable(ADDON_NAME .. "-Settings", GetSettingsPage)
    BazCore:AddToSettings(ADDON_NAME .. "-Settings", "General Settings", ADDON_NAME)
end

BazCore:QueueForLogin(function()
    -- Initial pass: pick up everything already registered at login
    addon:RescanFeeds()
end)
