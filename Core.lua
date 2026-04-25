---------------------------------------------------------------------------
-- BazBrokerWidget — bridge LibDataBroker-1.1 feeds into BazWidgetDrawers
--
-- Each LDB data object (`type = "data source"` and `type = "launcher"`)
-- becomes its own dockable widget. The user enables/disables/reorders
-- them like any other BWD widget — no special UI for managing the list
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
        emptyText       = "—",    -- text shown when a feed has no value yet
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
    -- silently — the addon is still loaded but registers nothing.
    return
end

---------------------------------------------------------------------------
-- Feed handling
---------------------------------------------------------------------------

local function CreateWidgetForFeed(name, dataobj)
    if registered[name] then return end
    if not (addon.BuildFeedWidget) then
        -- Widget.lua hasn't loaded yet — shouldn't happen given TOC order,
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
        print(string.format("  |cff8888ff%d.|r %s |cff999999(%s)|r — %s",
            count, name, typ, label))
    end
    if count == 0 then
        self:Print("  No feeds registered. Load an addon that publishes LDB data.")
    end
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

BazCore:QueueForLogin(function()
    -- Initial pass: pick up everything already registered at login
    addon:RescanFeeds()
end)
