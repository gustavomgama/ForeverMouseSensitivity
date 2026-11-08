local addonName, ns = ...

ns.db = { sensitivity = 1.0 }

local function apply()
    local n = tonumber(ns.db.sensitivity) or 1.0
    n = math.max(0.1, math.min(100, n))
    ns.db.sensitivity = n
    local v = tostring(n)
    local ok1 = C_CVar.SetCVar("cameraYawMoveSpeed", v)
    local ok2 = C_CVar.SetCVar("cameraPitchMoveSpeed", v)
    if ok1 == nil or ok2 == nil then
        print("|cffff0000ForeverMouseSensitivity|r: could not apply (in combat or locked)")
        return false
    end
    print("|cff00ff00ForeverMouseSensitivity|r set to " .. v)
    return true
end

local panel = CreateFrame("Frame")
panel.name = "Forever Mouse Sensitivity"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Forever Mouse Sensitivity")

local slider = CreateFrame("Slider", addonName .. "Slider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
slider:SetMinMaxValues(0.1, 100)
slider:SetValueStep(0.01)
slider:SetObeyStepOnDrag(true)
slider:SetWidth(240)

local low = _G[slider:GetName() .. "Low"]
local high = _G[slider:GetName() .. "High"]
local text = _G[slider:GetName() .. "Text"]
if low then low:SetText("0.1") end
if high then high:SetText("100") end
if text then text:SetText("Sensitivity") end

local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)

local editBox = CreateFrame("EditBox", addonName .. "EditBox", panel, "InputBoxTemplate")
editBox:SetPoint("LEFT", valueText, "RIGHT", 8, 0)
editBox:SetSize(60, 20)
editBox:SetAutoFocus(false)
editBox:SetNumeric(false)
editBox:SetMaxLetters(6)

slider:SetScript("OnValueChanged", function(self, val)
    val = math.floor(val * 100 + 0.5) / 100
    valueText:SetText(string.format("%.2f", val))
    if not editBox:HasFocus() then
        editBox:SetText(string.format("%.2f", val))
    end
end)

editBox:SetScript("OnEnterPressed", function(self)
    local n = tonumber(self:GetText())
    if not n or n < 0.1 or n > 100 then
        print("Sensitivity must be between 0.1 and 100")
        self:SetText(string.format("%.2f", ns.db.sensitivity or 1.0))
        return
    end
    ns.db.sensitivity = n
    slider:SetValue(n)
    apply()
    self:ClearFocus()
end)
editBox:SetScript("OnEscapePressed", function(self)
    self:SetText(string.format("%.2f", ns.db.sensitivity or 1.0))
    self:ClearFocus()
end)

local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -20)
resetBtn:SetSize(100, 24)
resetBtn:SetText("Reset")
resetBtn:SetScript("OnClick", function()
    slider:SetValue(1.0)
    ns.db.sensitivity = 1.0
    apply()
end)

local applyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
applyBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
applyBtn:SetSize(100, 24)
applyBtn:SetText("Apply")
applyBtn:SetScript("OnClick", function()
    local v = tonumber(editBox:GetText())
    if not v then
        v = slider:GetValue()
        v = math.floor(v * 100 + 0.5) / 100
    end
    if v < 0.1 or v > 100 then
        print("Sensitivity must be between 0.1 and 100")
        return
    end
    ns.db.sensitivity = v
    slider:SetValue(v)
    apply()
end)

SLASH_FOREVERMOUSESENSITIVITY1 = "/sens"
SLASH_FOREVERMOUSESENSITIVITY2 = "/sensitivity"
SlashCmdList["FOREVERMOUSESENSITIVITY"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        if Settings and Settings.OpenToCategory and ns.categoryID then
            Settings.OpenToCategory(ns.categoryID)
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(panel)
            InterfaceOptionsFrame_OpenToCategory(panel)
        end
        return
    end
    if msg:lower() == "reset" then
        ns.db.sensitivity = 1.0
        slider:SetValue(1.0)
        apply()
        return
    end
    local n = tonumber(msg)
    if not n or n < 0.1 or n > 100 then
        print("Usage: /sens <number 0.1-100>  or  /sens reset")
        return
    end
    ns.db.sensitivity = n
    slider:SetValue(n)
    apply()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    ForeverMouseSensitivityDB = ForeverMouseSensitivityDB or { sensitivity = 1.0 }
    ns.db = ForeverMouseSensitivityDB
    ns.db.sensitivity = tonumber(ns.db.sensitivity) or 1.0
    slider:SetValue(ns.db.sensitivity)
    editBox:SetText(string.format("%.2f", ns.db.sensitivity))
    apply()

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
    if Settings and Settings.OpenToCategory and ns.categoryID then
        Settings.OpenToCategory(ns.categoryID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

function ForeverMouseSensitivity_OnAddonCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Mouse Sensitivity")
    GameTooltip:AddLine("Click to open settings", 1, 1, 1)
    GameTooltip:Show()
end

function ForeverMouseSensitivity_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
