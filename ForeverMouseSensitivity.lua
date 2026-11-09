local addonName, ns = ...

local MIN, MAX, STEP, DEFAULT = 0.1, 100, 0.01, 1.0
local PREFIX = "|cff88ccffForeverMouseSensitivity|r"

ns.db = { sensitivity = DEFAULT }

-- Explicit state: desired (db) -> displayed (UI) -> applied (CVars). `applySensitivity` is the single transition.
local function roundStep(v)
    return math.floor(v / STEP + 0.5) * STEP
end

local function normalize(v)
    local n = tonumber(v)
    if not n then return nil end
    n = math.max(MIN, math.min(MAX, roundStep(n)))
    return n
end

local function fmt(v)
    return string.format("%.2f", v)
end

local function setStatus(msg, ok)
    if not ns.statusText then return end
    if ok == true then
        ns.statusText:SetTextColor(0.4, 1, 0.4)
    elseif ok == false then
        ns.statusText:SetTextColor(1, 0.4, 0.4)
    else
        ns.statusText:SetTextColor(1, 0.82, 0)
    end
    ns.statusText:SetText(msg or "")
end

local function applyCVars(v)
    local s = tostring(v)
    local ok1 = C_CVar.SetCVar("cameraYawMoveSpeed", s)
    local ok2 = C_CVar.SetCVar("cameraPitchMoveSpeed", s)
    return ok1 ~= nil and ok2 ~= nil
end

local panel = CreateFrame("Frame")
panel.name = "Forever Mouse Sensitivity"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Forever Mouse Sensitivity")

local slider = CreateFrame("Slider", addonName .. "Slider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
slider:SetMinMaxValues(MIN, MAX)
slider:SetValueStep(STEP)
slider:SetObeyStepOnDrag(true)
slider:SetWidth(240)

local low = _G[slider:GetName() .. "Low"]
local high = _G[slider:GetName() .. "High"]
local text = _G[slider:GetName() .. "Text"]
if low then low:SetText(tostring(MIN)) end
if high then high:SetText(tostring(MAX)) end
if text then text:SetText("Sensitivity") end

local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)

local editBox = CreateFrame("EditBox", addonName .. "EditBox", panel, "InputBoxTemplate")
editBox:SetPoint("LEFT", valueText, "RIGHT", 8, 0)
editBox:SetSize(60, 20)
editBox:SetAutoFocus(false)
editBox:SetNumeric(false)
editBox:SetMaxLetters(6)

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
statusText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
statusText:SetText("")
ns.statusText = statusText

local syncingUI = false
local function syncUI(v)
    syncingUI = true
    slider:SetValue(v)
    valueText:SetText(fmt(v))
    if not editBox:HasFocus() then
        editBox:SetText(fmt(v))
    end
    syncingUI = false
end

local function applySensitivity(raw, opts)
    opts = opts or {}
    local v = normalize(raw)
    if not v then
        local msg = "Sensitivity must be between " .. MIN .. " and " .. MAX
        setStatus(msg, false)
        if opts.chat ~= false then print(PREFIX .. ": " .. msg) end
        if opts.restoreUI then syncUI(ns.db.sensitivity or DEFAULT) end
        return false
    end

    ns.db.sensitivity = v
    if not opts.keepUI then syncUI(v) end

    local ok = applyCVars(v)
    ns.applyState = ok and "applied" or "failed" -- states: applied|failed (e.g. combat/locked)
    if ok then
        setStatus("Applied " .. fmt(v), true)
        if opts.chat then print(PREFIX .. " set to " .. fmt(v)) end
    else
        setStatus("Could not apply (combat or locked) - saved " .. fmt(v), false)
        if opts.chat ~= false then print(PREFIX .. ": could not apply (in combat or locked)") end
    end
    return ok
end

slider:SetScript("OnValueChanged", function(self, val)
    if syncingUI then return end
    local v = normalize(val) or DEFAULT
    valueText:SetText(fmt(v))
    if not editBox:HasFocus() then
        editBox:SetText(fmt(v))
    end
end)

editBox:SetScript("OnEnterPressed", function(self)
    applySensitivity(self:GetText(), { chat = false, restoreUI = true })
    self:ClearFocus()
end)
editBox:SetScript("OnEscapePressed", function(self)
    self:SetText(fmt(ns.db.sensitivity or DEFAULT))
    self:ClearFocus()
end)

local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -24)
resetBtn:SetSize(100, 24)
resetBtn:SetText("Reset")
resetBtn:SetScript("OnClick", function()
    applySensitivity(DEFAULT, { chat = false })
end)

local applyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
applyBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
applyBtn:SetSize(100, 24)
applyBtn:SetText("Apply")
applyBtn:SetScript("OnClick", function()
    local v = tonumber(editBox:GetText())
    if not v then v = slider:GetValue() end
    applySensitivity(v, { chat = false, restoreUI = true })
end)

local function openSettings()
    if Settings and Settings.OpenToCategory and ns.categoryID then
        Settings.OpenToCategory(ns.categoryID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

SLASH_FOREVERMOUSESENSITIVITY1 = "/sens"
SLASH_FOREVERMOUSESENSITIVITY2 = "/sensitivity"
SlashCmdList["FOREVERMOUSESENSITIVITY"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        openSettings()
        return
    end
    if msg:lower() == "reset" then
        applySensitivity(DEFAULT, { chat = true })
        return
    end
    applySensitivity(msg, { chat = true, restoreUI = true })
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    ForeverMouseSensitivityDB = ForeverMouseSensitivityDB or { sensitivity = DEFAULT }
    ns.db = ForeverMouseSensitivityDB
    ns.db.sensitivity = normalize(ns.db.sensitivity) or DEFAULT
    syncUI(ns.db.sensitivity)
    applySensitivity(ns.db.sensitivity, { chat = false, keepUI = true })

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ns.category = category
        ns.categoryID = category.GetID and category:GetID() or category.ID
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        ns.category = panel
    end
end)

function ForeverMouseSensitivity_OnAddonCompartmentClick()
    openSettings()
end

function ForeverMouseSensitivity_OnAddonCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Mouse Sensitivity")
    GameTooltip:AddLine("Click to open settings", 1, 1, 1)
    local v = ns.db and ns.db.sensitivity
    if v then GameTooltip:AddLine("Current: " .. fmt(normalize(v) or DEFAULT), 0.8, 0.8, 0.8) end
    GameTooltip:Show()
end

function ForeverMouseSensitivity_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
