std = "lua51"
max_line_length = false
ignore = {
    "113", -- accessing undefined variable (WoW API globals)
    "211", -- unused variable
    "212", -- unused argument
    "213", -- unused loop variable
    "122", -- setting read-only field: test mock defines WoW globals on _G
}
globals = {
    "ForeverMouseSensitivityDB",
    "ForeverMouseSensitivity_OnAddonCompartmentClick",
    "ForeverMouseSensitivity_OnAddonCompartmentEnter",
    "ForeverMouseSensitivity_OnAddonCompartmentLeave",
    "SLASH_FOREVERMOUSESENSITIVITY1",
    "SLASH_FOREVERMOUSESENSITIVITY2",
    "SlashCmdList",
}
read_globals = {
    "C_CVar",
    "CreateFrame",
    "GameTooltip",
    "InterfaceOptionsFrame_OpenToCategory",
    "InterfaceOptions_AddCategory",
    "Settings",
    "_G",
}
