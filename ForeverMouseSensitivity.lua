local addonName, ns = ...

local MIN, MAX = 0, 100
local DEFAULT_YAW, DEFAULT_PITCH = 90.00, 45.00
local PREFIX = "|cff88ccffForeverMouseSensitivity|r"

ns.db = {}

local function normalize(v)
    local n = tonumber(v)
    if not n then return nil end
    if n < MIN or n > MAX then return nil end
    return tonumber(string.format("%.2f", n))
end

local function fmt2(v)
    return string.format("%.2f", tonumber(v) or 0)
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
    local yaw = tonumber(fmt2(v))
    local pitch = tonumber(string.format("%.2f", yaw * DEFAULT_PITCH / DEFAULT_YAW))
    if pitch < MIN then pitch = MIN end
    if pitch > MAX then pitch = MAX end
    local ok1 = C_CVar.SetCVar("cameraYawMoveSpeed", fmt2(yaw))
    local ok2 = C_CVar.SetCVar("cameraPitchMoveSpeed", fmt2(pitch))
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
slider:SetValueStep(0.01)
slider:SetObeyStepOnDrag(false)
slider:SetWidth(240)

local low = _G[slider:GetName() .. "Low"]
local high = _G[slider:GetName() .. "High"]
local text = _G[slider:GetName() .. "Text"]
if low then low:SetText("0.00") end
if high then high:SetText("100.00") end
if text then text:SetText("Sensitivity") end

local editBox = CreateFrame("EditBox", addonName .. "EditBox", panel, "InputBoxTemplate")
editBox:SetPoint("LEFT", slider, "RIGHT", 12, 0)
editBox:SetSize(72, 20)
editBox:SetAutoFocus(false)
editBox:SetNumeric(false)
editBox:SetMaxLetters(6)
editBox:SetFontObject(GameFontHighlight)
editBox:SetTextColor(1, 1, 1)

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
statusText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
statusText:SetText("")
ns.statusText = statusText

local syncingUI = false
local function syncUI(v, force)
    syncingUI = true
    local n = tonumber(fmt2(v))
    slider:SetValue(n)
    if force or not editBox:HasFocus() then
        editBox:SetText(fmt2(n))
    end
    syncingUI = false
end

local flashCheck = function() end

local function applySensitivity(raw, opts)
    opts = opts or {}
    local v = normalize(raw)
    if not v then
        setStatus("Value must be between 0.00 and 100.00", false)
        if opts.restoreUI then syncUI(ns.db.sensitivity or DEFAULT_YAW) end
        return false
    end

    ns.db.sensitivity = v
    if not opts.keepUI then syncUI(v) end

    local ok = applyCVars(v)
    ns.applyState = ok and "applied" or "failed"
    if ok then
        if opts.status ~= false then
            setStatus("")
            flashCheck()
        end
    else
        if opts.status ~= false then setStatus("Could not apply (combat or locked) - saved " .. fmt2(v), false) end
    end
    return ok
end

slider:SetScript("OnValueChanged", function(self, val)
    if syncingUI then return end
    editBox:SetText(fmt2(val))
end)

local function nudge(step, down)
    local base = normalize(editBox:GetText()) or ns.db.sensitivity or DEFAULT_YAW
    local delta = down and -step or step
    local target = tonumber(fmt2(base + delta))
    if target < MIN then target = MIN end
    if target > MAX then target = MAX end
    applySensitivity(target)
end

local function stepButton(label, step, down)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(56, 18)
    b:SetText(label)
    b:SetScript("OnClick", function() nudge(step, down) end)
    return b
end

local up1 = stepButton("+0.01", 0.01, false)
local up2 = stepButton("+0.10", 0.10, false)
local up3 = stepButton("+1", 1, false)
local down1 = stepButton("-0.01", 0.01, true)
local down2 = stepButton("-0.10", 0.10, true)
local down3 = stepButton("-1", 1, true)

up1:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -20)
up2:SetPoint("LEFT", up1, "RIGHT", 4, 0)
up3:SetPoint("LEFT", up2, "RIGHT", 4, 0)
down1:SetPoint("TOPLEFT", up1, "BOTTOMLEFT", 0, -4)
down2:SetPoint("LEFT", down1, "RIGHT", 4, 0)
down3:SetPoint("LEFT", down2, "RIGHT", 4, 0)

editBox:SetScript("OnEnterPressed", function(self)
    applySensitivity(self:GetText())
    self:ClearFocus()
    syncUI(ns.db.sensitivity or DEFAULT_YAW, true)
end)
editBox:SetScript("OnEscapePressed", function(self)
    self:SetText(fmt2(ns.db.sensitivity or DEFAULT_YAW))
    self:ClearFocus()
end)
editBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
end)
editBox:SetScript("OnShow", function(self)
    self:SetText(fmt2(ns.db and ns.db.sensitivity or DEFAULT_YAW))
    self:SetCursorPosition(0)
end)

local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetPoint("TOPLEFT", down1, "BOTTOMLEFT", 0, -12)
resetBtn:SetSize(100, 24)
resetBtn:SetText("Reset")
resetBtn:SetScript("OnClick", function()
    applySensitivity(DEFAULT_YAW, { restoreUI = true })
end)

local applyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
applyBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
applyBtn:SetSize(100, 24)
applyBtn:SetText("Apply")
applyBtn:SetScript("OnClick", function()
    applySensitivity(editBox:GetText())
    editBox:ClearFocus()
    syncUI(ns.db.sensitivity or DEFAULT_YAW, true)
end)

local check = panel:CreateTexture(nil, "ARTWORK")
check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
check:SetWidth(20)
check:SetHeight(20)
check:SetPoint("LEFT", applyBtn, "RIGHT", 8, 0)
check:Hide()

local checkTimer = CreateFrame("Frame")
checkTimer:Hide()
local checkElapsed = 0
checkTimer:SetScript("OnUpdate", function(self, elapsed)
    checkElapsed = checkElapsed + elapsed
    if checkElapsed >= 1.5 then
        check:Hide()
        self:Hide()
    end
end)

flashCheck = function()
    checkElapsed = 0
    check:Show()
    checkTimer:Show()
end

panel:SetScript("OnShow", function()
    syncUI(ns.db.sensitivity or DEFAULT_YAW, true)
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
        applySensitivity(DEFAULT_YAW, { restoreUI = true })
        return
    end
    applySensitivity(msg, { restoreUI = true })
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    ForeverMouseSensitivityDB = ForeverMouseSensitivityDB or {}
    ns.db = ForeverMouseSensitivityDB
    local v = normalize(ns.db.sensitivity)
    if not v then v = DEFAULT_YAW end
    ns.db.sensitivity = v
    syncUI(v, true)
    local ok = applySensitivity(v, { keepUI = true, status = false })
    if ok then
        print(PREFIX .. " loaded: " .. fmt2(v))
    else
        print(PREFIX .. " loaded: " .. fmt2(v) .. " (could not apply - combat or locked)")
    end

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
    if v then GameTooltip:AddLine("Current: " .. fmt2(v), 0.8, 0.8, 0.8) end
    GameTooltip:Show()
end

function ForeverMouseSensitivity_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
