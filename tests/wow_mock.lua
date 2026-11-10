-- Minimal WoW API mock for ForeverMouseSensitivity wiring tests. Not a full client.
local M = {}

local function class(base)
  base.__index = base
  return setmetatable({}, base)
end

local Widget = {}
function Widget:SetPoint() end
function Widget:SetSize() end
function Widget:SetWidth() end
function Widget:SetHeight() end
function Widget:SetText(t) self.text = t end
function Widget:GetText() return self.text or "" end
function Widget:SetTextColor(r, g, b) self.color = { r, g, b } end
function Widget:SetFontObject() end
function Widget:SetCursorPosition() end
function Widget:SetScript(event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end
function Widget:GetScript(event) return self.scripts and self.scripts[event] end
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:GetName() return self._name end
function Widget:EnableKeyboard() end
function Widget:HighlightText() self.highlighted = true end

local FontString = setmetatable({}, { __index = Widget })
FontString.__index = FontString
local function newFontString(name)
  return setmetatable({ _name = name, kind = "FontString" }, FontString)
end

local EditBox = setmetatable({}, { __index = Widget })
EditBox.__index = EditBox
function EditBox:SetAutoFocus() end
function EditBox:SetNumeric() end
function EditBox:SetMaxLetters() end
function EditBox:HasFocus() return self.focused end
function EditBox:ClearFocus() self.focused = false end
function EditBox:Focus() self.focused = true end
function EditBox:Enter(text)
  self.text = text
  local fn = self.scripts and self.scripts.OnEnterPressed
  if fn then fn(self) end
end
local function newEditBox(name)
  return setmetatable({ _name = name, kind = "EditBox" }, EditBox)
end

local Slider = setmetatable({}, { __index = Widget })
Slider.__index = Slider
function Slider:SetMinMaxValues(min, max) self.min, self.max = min, max end
function Slider:SetValueStep() end
function Slider:SetObeyStepOnDrag() end
function Slider:SetValue(v)
  self.value = v
  local fn = self.scripts and self.scripts.OnValueChanged
  if fn then fn(self, v) end
end
function Slider:GetValue() return self.value end
local function newSlider(name)
  return setmetatable({ _name = name, kind = "Slider", value = 0 }, Slider)
end

local Texture = setmetatable({}, { __index = Widget })
Texture.__index = Texture
function Texture:SetTexture(t) self.texture = t end
function Texture:SetVertexColor(r, g, b) self.color = { r, g, b } end
local function newTexture()
  return setmetatable({ kind = "Texture", shown = false }, Texture)
end

local Button = setmetatable({}, { __index = Widget })
Button.__index = Button
function Button:Click()
  local fn = self.scripts and self.scripts.OnClick
  if fn then fn(self) end
end
local function newButton(name)
  return setmetatable({ _name = name, kind = "Button" }, Button)
end

local Frame = setmetatable({}, { __index = Widget })
Frame.__index = Frame
function Frame:CreateFontString(_, _, _)
  local fs = newFontString()
  self.fontStrings = self.fontStrings or {}
  table.insert(self.fontStrings, fs)
  return fs
end
function Frame:RegisterEvent(ev) self.events = self.events or {}; self.events[ev] = true end
function Frame:CreateTexture()
  local t = newTexture()
  self.textures = self.textures or {}
  table.insert(self.textures, t)
  table.insert(M.textures, t)
  return t
end
local function newFrame(name)
  return setmetatable({ _name = name, kind = "Frame" }, Frame)
end

function M.reset(opts)
  opts = opts or {}
  M.frames = {}
  M.textures = {}
  M.eventFrames = {}
  M.prints = {}
  M.cvarCalls = {}
  M.cvars = opts.cvars or { cameraYawMoveSpeed = "1.00", cameraPitchMoveSpeed = "1.00" }
  M.cvarLocked = opts.cvarLocked or false
  M.ns = {}
  M.settingsRegistered = nil
  M.settingsOpened = nil
  M.shift = opts.shift or false
  M.ctrl = opts.ctrl or false

  _G.SlashCmdList = _G.SlashCmdList or {}
  _G.ForeverMouseSensitivityDB = opts.db
  _G.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    table.insert(M.prints, table.concat(parts, " "))
  end
  _G.IsShiftKeyDown = function() return M.shift end
  _G.IsControlKeyDown = function() return M.ctrl end

  _G.C_CVar = {
    SetCVar = function(name, value)
      table.insert(M.cvarCalls, { name = name, value = value })
      if M.cvarLocked then return nil end
      M.cvars[name] = value
      return true
    end,
    GetCVar = function(name) return M.cvars[name] end,
  }

  _G.Settings = opts.noSettings and nil or {
    RegisterCanvasLayoutCategory = function(panel, name)
      local cat = { panel = panel, name = name, GetID = function() return 42 end }
      M.settingsRegistered = cat
      return cat
    end,
    RegisterAddOnCategory = function(cat) M.settingsRegisteredCategory = cat end,
    OpenToCategory = function(id) M.settingsOpened = id end,
  }
  _G.InterfaceOptions_AddCategory = function(panel) M.legacySettings = panel end
  _G.InterfaceOptionsFrame_OpenToCategory = function(panel) M.legacyOpened = panel end

  _G.GameTooltip = {
    lines = {},
    SetOwner = function() end,
    SetText = function(_, t) _G.GameTooltip.title = t end,
    AddLine = function(_, t) table.insert(_G.GameTooltip.lines, t) end,
    Show = function() end,
    Hide = function() end,
  }

  _G.CreateFrame = function(kind, name, parent, template)
    local f
    if kind == "Slider" then
      f = newSlider(name)
      if name then
        _G[name .. "Low"] = newFontString(name .. "Low")
        _G[name .. "High"] = newFontString(name .. "High")
        _G[name .. "Text"] = newFontString(name .. "Text")
      end
    elseif kind == "EditBox" then
      f = newEditBox(name)
    elseif kind == "Button" then
      f = newButton(name)
    else
      f = newFrame(name)
    end
    f.parent = parent
    f.template = template
    if name then _G[name] = f end
    table.insert(M.frames, f)
    if kind == "Frame" then table.insert(M.eventFrames, f) end
    return f
  end
end

function M.fireEvent(event, ...)
  for _, f in ipairs(M.eventFrames) do
    local fn = f.scripts and f.scripts.OnEvent
    if fn and (not f.events or f.events[event]) then fn(f, event, ...) end
  end
end

function M.findCheckTexture()
  for _, t in ipairs(M.textures) do
    if t.texture and t.texture:match("UI%-CheckBox%-Check") then return t end
  end
end

function M.findEditBox()
  for _, f in ipairs(M.frames) do
    if f.kind == "EditBox" then return f end
  end
end

function M.findButton(text)
  for _, f in ipairs(M.frames) do
    if f.kind == "Button" and f.text == text then return f end
  end
end

function M.findLastPrint(pattern)
  for i = #M.prints, 1, -1 do
    if M.prints[i]:match(pattern) then return M.prints[i] end
  end
end

return M
