---------------------------------------------------------------------------
-- BazBrokerWidget — per-feed widget factory
--
-- For every LibDataBroker data object, build a small horizontal widget:
--
--   [icon]  Label                    Value
--
-- and register it with BazWidgetDrawers via the standard
-- RegisterDockableWidget API. The widget mirrors the live LDB attributes
-- (text/value/icon/label) by subscribing to LibDataBroker_AttributeChanged
-- callbacks scoped to the feed's name.
---------------------------------------------------------------------------

local ADDON_NAME = "BazBrokerWidget"
local addon = BazCore:GetAddon(ADDON_NAME)
if not addon then return end

local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
if not LDB then return end

local DESIGN_WIDTH  = 200
local DESIGN_HEIGHT = 22
local ICON_SIZE     = 16
local PAD           = 4

local function SafeStr(v)
    if v == nil then return "" end
    if type(v) == "string" then return v end
    return tostring(v)
end

local function ApplyIcon(widget, dataobj)
    if not widget.icon then return end
    if dataobj.icon then
        widget.icon:SetTexture(dataobj.icon)
        if dataobj.iconCoords then
            widget.icon:SetTexCoord(unpack(dataobj.iconCoords))
        else
            widget.icon:SetTexCoord(0, 1, 0, 1)
        end
        if dataobj.iconR and dataobj.iconG and dataobj.iconB then
            widget.icon:SetVertexColor(dataobj.iconR, dataobj.iconG, dataobj.iconB)
        else
            widget.icon:SetVertexColor(1, 1, 1)
        end
        widget.icon:Show()
    else
        widget.icon:Hide()
    end
end

local function ApplyText(widget, dataobj)
    -- Some feeds publish only `value` + `suffix`, others publish a
    -- pre-formatted `text`. Prefer `text` when set, fall back to
    -- `value (suffix)` when not.
    local valueText = dataobj.text
    if not valueText or valueText == "" then
        local v = dataobj.value
        if v ~= nil and v ~= "" then
            local s = dataobj.suffix
            valueText = s and (SafeStr(v) .. " " .. SafeStr(s)) or SafeStr(v)
        end
    end
    if not valueText or valueText == "" then
        valueText = addon:GetSetting("emptyText") or "—"
    end
    widget.value:SetText(valueText)
end

local function ApplyLabel(widget, name, dataobj)
    if not addon:GetSetting("showLabel") then
        widget.label:SetText("")
        return
    end
    local label = dataobj.label
    if not label or label == "" then label = name end
    widget.label:SetText(label)
end

---------------------------------------------------------------------------
-- Frame builder
---------------------------------------------------------------------------

local function BuildFrame(name, dataobj)
    local frame = CreateFrame("Button", "BazBrokerWidget_" .. name, UIParent)
    frame:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)
    frame:RegisterForClicks("AnyUp")
    frame:EnableMouse(true)

    -- Subtle hover highlight (matches BWD widget chrome)
    local hover = frame:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)
    frame.hover = hover

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", PAD, 0)
    frame.icon = icon

    -- Label (left)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", icon, "RIGHT", PAD, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.85, 0.85, 0.85)
    frame.label = label

    -- Value (right)
    local value = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("RIGHT", -PAD, 0)
    value:SetJustifyH("RIGHT")
    value:SetTextColor(1, 0.82, 0)
    frame.value = value

    -- Don't let the label overlap the value — clamp label to the gap
    label:SetPoint("RIGHT", value, "LEFT", -PAD, 0)
    label:SetWordWrap(false)
    label:SetNonSpaceWrap(false)

    -- Click forwards to the feed's OnClick handler if present
    frame:SetScript("OnClick", function(self, button)
        if dataobj.OnClick then
            local ok, err = pcall(dataobj.OnClick, self, button)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end)

    -- Hover highlight + tooltip forwarding. LDB exposes either OnEnter
    -- (full custom tooltip) or OnTooltipShow (called with GameTooltip).
    frame:SetScript("OnEnter", function(self)
        self.hover:SetColorTexture(1, 1, 1, 0.06)
        if dataobj.OnEnter then
            pcall(dataobj.OnEnter, self)
        elseif dataobj.OnTooltipShow then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            pcall(dataobj.OnTooltipShow, GameTooltip)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        self.hover:SetColorTexture(1, 1, 1, 0)
        if dataobj.OnLeave then
            pcall(dataobj.OnLeave, self)
        else
            GameTooltip:Hide()
        end
    end)

    return frame
end

---------------------------------------------------------------------------
-- Public: build + register a feed widget with BWD
---------------------------------------------------------------------------

function addon:BuildFeedWidget(name, dataobj)
    local frame = BuildFrame(name, dataobj)
    ApplyIcon(frame, dataobj)
    ApplyLabel(frame, name, dataobj)
    ApplyText(frame, dataobj)

    BazCore:RegisterDockableWidget({
        id           = "bazbroker_" .. name,
        label        = dataobj.label or name,
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = frame,
        -- BWD's Settings list reads widget.tags and renders each as a
        -- coloured badge after the label. We mark every LDB-bridged
        -- widget so users can spot them at a glance — they're not
        -- "real" Baz Suite widgets, they're whatever third-party
        -- addon (Bagnon, Recount, etc.) is publishing the feed.
        tags = { { text = "LDB", color = "60a0ff" } },
        GetStatusText = function()
            return frame.value:GetText() or "", 1, 0.82, 0
        end,
    })

    -- Keep the widget in sync with live LDB attribute changes. Each feed
    -- fires a per-attribute callback; we listen to the four that affect
    -- our render.
    local function OnAttr(_, _, _, _, dobj)
        if dobj ~= dataobj then return end  -- defensive: same name only
        ApplyIcon(frame, dobj)
        ApplyLabel(frame, name, dobj)
        ApplyText(frame, dobj)
    end
    LDB.RegisterCallback(frame, "LibDataBroker_AttributeChanged_" .. name .. "_text",  OnAttr)
    LDB.RegisterCallback(frame, "LibDataBroker_AttributeChanged_" .. name .. "_value", OnAttr)
    LDB.RegisterCallback(frame, "LibDataBroker_AttributeChanged_" .. name .. "_label", OnAttr)
    LDB.RegisterCallback(frame, "LibDataBroker_AttributeChanged_" .. name .. "_icon",  OnAttr)
end
