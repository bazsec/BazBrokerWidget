---------------------------------------------------------------------------
-- BazBrokerWidget User Manual
-- Registered with BazCore so it appears in the User Manual tab.
---------------------------------------------------------------------------

if not BazCore or not BazCore.RegisterUserGuide then return end

BazCore:RegisterUserGuide("BazBrokerWidget", {
    title = "BazBrokerWidget",
    intro = "Surfaces LibDataBroker (LDB) feeds as dockable widgets inside BazWidgetDrawers. Every addon that publishes data via LDB shows up as its own widget you can dock, float, reorder, or disable.",
    pages = {
        {
            title = "Welcome",
            blocks = {
                { type = "lead", text = "If you have an addon that publishes a LibDataBroker feed (Bagnon, Recount, Skada, BugSack, almost anything with a minimap data button), BazBrokerWidget mirrors that feed as a small icon + label + value widget inside BazWidgetDrawers." },
                { type = "h2", text = "What is LibDataBroker?" },
                { type = "paragraph", text = "LibDataBroker (LDB) is a shared library that lots of addons use to publish data - a numeric value, a status string, an icon - without caring how it gets displayed. Display addons like Bazooka, ChocolateBar, or TitanPanel consume those feeds and arrange them in bars. BazBrokerWidget is a display, scoped to fit inside the BazWidgetDrawers drawer." },
                { type = "note", style = "tip", text = "You don't need to do anything special to use it. Install BazBrokerWidget alongside any LDB-publishing addon and the feeds appear automatically in the BWD widget list." },
            },
        },
        {
            title = "Using It",
            blocks = {
                { type = "h3", text = "Each feed is its own widget" },
                { type = "paragraph", text = "When BazBrokerWidget loads, it scans every registered LDB feed and creates one BWD widget per feed. They appear in the BWD options under the Widgets page with names like \"Bagnon\", \"Skada\", etc." },
                { type = "list", items = {
                    "Click a widget's |cffffd700Enable|r toggle to show/hide it",
                    "Drag widgets in the drawer to reorder",
                    "Right-click the widget header > Float to detach it from the drawer",
                    "Click the widget itself to invoke the feed's normal action (open the addon's UI, etc.)",
                    "Hover for the feed's tooltip",
                }},
                { type = "note", style = "info", text = "Feeds register at different times during boot - some on PLAYER_LOGIN, some on first event. BazBrokerWidget listens for late registrations and adds widgets as they appear, so you don't need to /reload after enabling another addon." },
            },
        },
        {
            title = "Slash Commands",
            blocks = {
                { type = "table",
                  columns = { "Command", "Action" },
                  rows = {
                      { "/bbw",          "Open the BazBrokerWidget settings page" },
                      { "/bbw list",     "Print every LDB feed currently registered" },
                      { "/bbw rescan",   "Rebuild widgets for all known feeds (rarely needed)" },
                      { "/bazbroker",    "Alias for /bbw" },
                  }},
            },
        },
        {
            title = "Tips",
            blocks = {
                { type = "list", items = {
                    "Install Bagnon, Recount, BugSack, or any addon with an \"LDB feed\" listed in its description",
                    "If a widget appears empty, the feed may not have populated its value yet - interact with that addon once",
                    "Use BWD's per-widget enable to hide noisy feeds you don't care about",
                }},
            },
        },
    },
})
