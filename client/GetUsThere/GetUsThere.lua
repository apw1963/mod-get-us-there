local addonName = "GetUsThere"

local savedVariablesSchemaVersion = 1

local defaultUiScalePercent = 100
local minimumUiScalePercent = 70
local maximumUiScalePercent = 150
local uiScaleStepPercent = 5

local defaultWindowOpacityPercent = 100
local minimumWindowOpacityPercent = 50
local maximumWindowOpacityPercent = 100
local windowOpacityStepPercent = 5

local defaultTextSizePercent = 100
local minimumTextSizePercent = 80
local maximumTextSizePercent = 140
local textSizeStepPercent = 5

local defaultShowRawCoordinates = true
local ApplyRawVisibility = nil

local defaultRememberWindowPosition = true
local rememberWindowPositionCheck = nil
local RestoreSavedWindowPosition = nil

local defaultLockWindowPosition = false
local lockWindowPositionCheck = nil

local defaultHideInCombat = true
local hideInCombatCheck = nil

local defaultRestoreAfterCombat = true
local restoreAfterCombatCheck = nil

-- Session-only combat visibility state. Never persist these values.
local combatHideActive = false
local restoreMainAfterCombat = false
local restoreOptionsAfterCombat = false

local function NormalizeUiScalePercent(value)
    value = tonumber(value)

    if not value
        or value < minimumUiScalePercent
        or value > maximumUiScalePercent then
        return defaultUiScalePercent
    end

    return math.floor(
        (value + (uiScaleStepPercent / 2)) / uiScaleStepPercent)
        * uiScaleStepPercent
end

local function ApplyUiScalePercent(value)
    local normalized = NormalizeUiScalePercent(value)

    if GetUsThereFrame then
        GetUsThereFrame:SetScale(normalized / 100)
    end

    if GetUsThereScaleSlider
        and GetUsThereScaleSlider:GetValue() ~= normalized then
        GetUsThereScaleSlider:SetValue(normalized)
    end

    if GetUsThereScaleSliderText then
        GetUsThereScaleSliderText:SetText(
            "UI Scale: " .. normalized .. "%")
    end

    return normalized
end

local function NormalizeWindowOpacityPercent(value)
    value = tonumber(value)

    if not value
        or value < minimumWindowOpacityPercent
        or value > maximumWindowOpacityPercent then
        return defaultWindowOpacityPercent
    end

    return math.floor(
        (value + (windowOpacityStepPercent / 2)) / windowOpacityStepPercent)
        * windowOpacityStepPercent
end

local function ApplyWindowOpacityPercent(value)
    local normalized = NormalizeWindowOpacityPercent(value)

    if GetUsThereFrame then
        GetUsThereFrame:SetAlpha(normalized / 100)
    end

    if GetUsThereOpacitySlider
        and GetUsThereOpacitySlider:GetValue() ~= normalized then
        GetUsThereOpacitySlider:SetValue(normalized)
    end

    if GetUsThereOpacitySliderText then
        GetUsThereOpacitySliderText:SetText(
            "Window Opacity: " .. normalized .. "%")
    end

    return normalized
end

local function NormalizeTextSizePercent(value)
    value = tonumber(value)

    if not value
        or value < minimumTextSizePercent
        or value > maximumTextSizePercent then
        return defaultTextSizePercent
    end

    return math.floor(
        (value + (textSizeStepPercent / 2)) / textSizeStepPercent)
        * textSizeStepPercent
end

local textFontBaselines = setmetatable({}, { __mode = "k" })

local dropdownTextFont = CreateFont("GetUsThereDropdownTextFont")
local dropdownFontPath, dropdownFontSize, dropdownFontFlags =
    GameFontHighlightSmallLeft:GetFont()

local function ApplyDropdownTextAppearance(sizePercent)
    if not dropdownTextFont
        or type(dropdownFontPath) ~= "string"
        or type(dropdownFontSize) ~= "number" then
        return
    end

    dropdownTextFont:SetFont(
        dropdownFontPath,
        dropdownFontSize * (sizePercent / 100),
        dropdownFontFlags or "")
end

local function ApplyTextStyleToFont(fontInstance, sizePercent)
    if not fontInstance
        or not fontInstance.GetFont
        or not fontInstance.SetFont then
        return
    end

    local baseline = textFontBaselines[fontInstance]

    if not baseline then
        local fontPath, fontSize, fontFlags = fontInstance:GetFont()

        if type(fontPath) ~= "string" or type(fontSize) ~= "number" then
            return
        end

        baseline = {
            path = fontPath,
            size = fontSize,
            flags = fontFlags or ""
        }

        textFontBaselines[fontInstance] = baseline
    end

    fontInstance:SetFont(
        baseline.path,
        baseline.size * (sizePercent / 100),
        baseline.flags)
end

local function ApplyTextStyleToFrame(root, sizePercent, visited)
    if not root or visited[root] then
        return
    end

    visited[root] = true

    if root.GetObjectType and root:GetObjectType() == "EditBox" then
        ApplyTextStyleToFont(root, sizePercent)
    end

    if root.GetFontString then
        ApplyTextStyleToFont(
            root:GetFontString(),
            sizePercent)
    end

    if root.GetRegions then
        local regions = { root:GetRegions() }

        for _, region in ipairs(regions) do
            if region
                and region.GetObjectType
                and region:GetObjectType() == "FontString" then
                ApplyTextStyleToFont(
                    region,
                    sizePercent)
            end
        end
    end

    if root.GetChildren then
        local children = { root:GetChildren() }

        for _, child in ipairs(children) do
            ApplyTextStyleToFrame(
                child,
                sizePercent,
                visited)
        end
    end
end

local function ApplyTextAppearance(sizeValue)
    local normalized = NormalizeTextSizePercent(sizeValue)

    if GetUsThereTextSizeSlider
        and GetUsThereTextSizeSlider:GetValue() ~= normalized then
        GetUsThereTextSizeSlider:SetValue(normalized)
    end

    if GetUsThereTextSizeSliderText then
        GetUsThereTextSizeSliderText:SetText(
            "Text Size: " .. normalized .. "%")
    end

    ApplyDropdownTextAppearance(normalized)

    local visited = {}

    ApplyTextStyleToFrame(
        GetUsThereFrame,
        normalized,
        visited)

    ApplyTextStyleToFrame(
        GetUsThereOptionsFrame,
        normalized,
        visited)

    return normalized
end

local savedVariablesFrame = CreateFrame("Frame")

savedVariablesFrame:RegisterEvent("ADDON_LOADED")
savedVariablesFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= addonName then
        return
    end

    if type(GetUsThereDB) ~= "table" then
        GetUsThereDB = {}
    end

    if type(GetUsThereDB.schemaVersion) ~= "number" then
        GetUsThereDB.schemaVersion = savedVariablesSchemaVersion
    end

    if type(GetUsThereDB.preferences) ~= "table" then
        GetUsThereDB.preferences = {}
    end

    GetUsThereDB.preferences.uiScalePercent =
        ApplyUiScalePercent(GetUsThereDB.preferences.uiScalePercent)

    GetUsThereDB.preferences.windowOpacityPercent =
        ApplyWindowOpacityPercent(
            GetUsThereDB.preferences.windowOpacityPercent)

    GetUsThereDB.preferences.textSizePercent =
        NormalizeTextSizePercent(
            GetUsThereDB.preferences.textSizePercent)

    -- Removed Appearance option: discard legacy saved Text Outline state.
    GetUsThereDB.preferences.textOutline = nil

    if type(GetUsThereDB.preferences.showRawCoordinates) ~= "boolean" then
        GetUsThereDB.preferences.showRawCoordinates =
            defaultShowRawCoordinates
    end

    if type(GetUsThereDB.preferences.rememberWindowPosition) ~= "boolean" then
        GetUsThereDB.preferences.rememberWindowPosition =
            defaultRememberWindowPosition
    end

    if type(GetUsThereDB.preferences.lockWindowPosition) ~= "boolean" then
        GetUsThereDB.preferences.lockWindowPosition =
            defaultLockWindowPosition
    end

    if type(GetUsThereDB.preferences.hideInCombat) ~= "boolean" then
        GetUsThereDB.preferences.hideInCombat =
            defaultHideInCombat
    end

    if type(GetUsThereDB.preferences.restoreAfterCombat) ~= "boolean" then
        GetUsThereDB.preferences.restoreAfterCombat =
            defaultRestoreAfterCombat
    end

    if rememberWindowPositionCheck then
        rememberWindowPositionCheck:SetChecked(
            GetUsThereDB.preferences.rememberWindowPosition)
    end

    if lockWindowPositionCheck then
        lockWindowPositionCheck:SetChecked(
            GetUsThereDB.preferences.lockWindowPosition)
    end

    if hideInCombatCheck then
        hideInCombatCheck:SetChecked(
            GetUsThereDB.preferences.hideInCombat)
    end

    if restoreAfterCombatCheck then
        restoreAfterCombatCheck:SetChecked(
            GetUsThereDB.preferences.restoreAfterCombat)
    end

    GetUsThereDB.preferences.textSizePercent =
        ApplyTextAppearance(
            GetUsThereDB.preferences.textSizePercent)

    if RestoreSavedWindowPosition then
        RestoreSavedWindowPosition()
    end

    if ApplyRawVisibility then
        ApplyRawVisibility()
    end

    -- Session-only travel authority and request state must never be persisted here.
    self:UnregisterEvent("ADDON_LOADED")
end)

local frame = CreateFrame("Frame", "GetUsThereFrame", UIParent)
frame:SetWidth(560)
frame:SetHeight(600)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)

local validWindowAnchorPoints = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true
}

local function IsFiniteWindowCoordinate(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function IsMainWindowPositionLocked()
    return type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table"
        and GetUsThereDB.preferences.lockWindowPosition == true
end

local function SaveCurrentWindowPosition()
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table"
        or not GetUsThereDB.preferences.rememberWindowPosition then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)

    if not validWindowAnchorPoints[point]
        or not validWindowAnchorPoints[relativePoint]
        or not IsFiniteWindowCoordinate(x)
        or not IsFiniteWindowCoordinate(y) then
        return
    end

    GetUsThereDB.preferences.windowPosition = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end

RestoreSavedWindowPosition = function()
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table"
        or not GetUsThereDB.preferences.rememberWindowPosition then
        return
    end

    local saved = GetUsThereDB.preferences.windowPosition

    if type(saved) ~= "table" then
        return
    end

    if not validWindowAnchorPoints[saved.point]
        or not validWindowAnchorPoints[saved.relativePoint]
        or not IsFiniteWindowCoordinate(saved.x)
        or not IsFiniteWindowCoordinate(saved.y) then
        GetUsThereDB.preferences.windowPosition = nil
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(
        saved.point,
        UIParent,
        saved.relativePoint,
        saved.x,
        saved.y)
end

frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    if IsMainWindowPositionLocked() then
        return
    end

    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveCurrentWindowPosition()
end)

frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Get Us There")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local optionsFrame =
    CreateFrame("Frame", "GetUsThereOptionsFrame", UIParent)

optionsFrame:SetWidth(420)
optionsFrame:SetHeight(580)
optionsFrame:SetPoint("CENTER")
optionsFrame:SetClampedToScreen(true)
optionsFrame:SetFrameStrata("DIALOG")
optionsFrame:SetMovable(true)
optionsFrame:EnableMouse(true)
optionsFrame:RegisterForDrag("LeftButton")

optionsFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

optionsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

optionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
optionsFrame:Hide()

local optionsTitle =
    optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

optionsTitle:SetPoint("TOP", 0, -18)
optionsTitle:SetText("Get Us There Options")

local optionsClose =
    CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")

optionsClose:SetPoint("TOPRIGHT", -5, -5)

local optionsIntro =
    optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

optionsIntro:SetPoint("TOPLEFT", 28, -62)
optionsIntro:SetWidth(360)
optionsIntro:SetJustifyH("LEFT")
optionsIntro:SetText(
    "Choose a category to configure Get Us There.")

local appearancePanel = CreateFrame("Frame", nil, optionsFrame)
appearancePanel:SetWidth(364)
appearancePanel:SetHeight(400)
appearancePanel:SetPoint("TOPLEFT", 28, -150)

local windowPanel = CreateFrame("Frame", nil, optionsFrame)
windowPanel:SetWidth(364)
windowPanel:SetHeight(400)
windowPanel:SetPoint("TOPLEFT", 28, -150)

local displayPanel = CreateFrame("Frame", nil, optionsFrame)
displayPanel:SetWidth(364)
displayPanel:SetHeight(400)
displayPanel:SetPoint("TOPLEFT", 28, -150)

local optionsTabs = {}

local function SetOptionsTabAppearance(button, isActive)
    local fontString = button:GetFontString()
    local yOffset = -108

    button:Enable()
    button:ClearAllPoints()

    if isActive then
        yOffset = -104
        button:SetHeight(26)
        button:SetAlpha(1.0)
        button:SetPoint("TOPLEFT", button.tabX, yOffset)
        button:LockHighlight()

        if fontString then
            fontString:SetTextColor(1.0, 0.82, 0.0)
        end
    else
        button:SetHeight(22)
        button:SetAlpha(0.65)
        button:SetPoint("TOPLEFT", button.tabX, yOffset)
        button:UnlockHighlight()

        if fontString then
            fontString:SetTextColor(0.62, 0.62, 0.62)
        end
    end
end

local function SelectOptionsPanel(panelKey)
    appearancePanel:Hide()
    windowPanel:Hide()
    displayPanel:Hide()

    local panel = nil

    if panelKey == "APPEARANCE" then
        panel = appearancePanel
    elseif panelKey == "WINDOW" then
        panel = windowPanel
    elseif panelKey == "DISPLAY" then
        panel = displayPanel
    else
        panelKey = "APPEARANCE"
        panel = appearancePanel
    end

    panel:Show()

    for key, button in pairs(optionsTabs) do
        SetOptionsTabAppearance(button, key == panelKey)
    end
end

local function CreateOptionsTab(key, text, x)
    local button =
        CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")

    button.tabX = x
    button:SetWidth(110)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", x, -108)
    button:SetAlpha(0.65)
    button:SetText(text)

    button:SetScript("OnClick", function()
        SelectOptionsPanel(key)
    end)

    optionsTabs[key] = button
    return button
end

CreateOptionsTab("APPEARANCE", "Appearance", 28)
CreateOptionsTab("WINDOW", "Window", 146)
CreateOptionsTab("DISPLAY", "Display", 264)

SelectOptionsPanel("APPEARANCE")

local scaleSlider =
    CreateFrame(
        "Slider",
        "GetUsThereScaleSlider",
        appearancePanel,
        "OptionsSliderTemplate")

scaleSlider:SetWidth(220)
scaleSlider:SetHeight(16)
scaleSlider:SetPoint("TOPLEFT", appearancePanel, "TOPLEFT", 8, -30)
scaleSlider:SetMinMaxValues(minimumUiScalePercent, maximumUiScalePercent)
scaleSlider:SetValueStep(uiScaleStepPercent)
scaleSlider:SetValue(defaultUiScalePercent)

if GetUsThereScaleSliderLow then
    GetUsThereScaleSliderLow:SetText(minimumUiScalePercent .. "%")
end

if GetUsThereScaleSliderHigh then
    GetUsThereScaleSliderHigh:SetText(maximumUiScalePercent .. "%")
end

if GetUsThereScaleSliderText then
    GetUsThereScaleSliderText:SetText(
        "UI Scale: " .. defaultUiScalePercent .. "%")
end

scaleSlider:SetScript("OnValueChanged", function(self, value)
    local normalized = NormalizeUiScalePercent(value)

    if math.abs(value - normalized) > 0.01 then
        self:SetValue(normalized)
        return
    end

    if type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table" then
        GetUsThereDB.preferences.uiScalePercent = normalized
    end

    ApplyUiScalePercent(normalized)
end)

local opacitySlider =
    CreateFrame(
        "Slider",
        "GetUsThereOpacitySlider",
        appearancePanel,
        "OptionsSliderTemplate")

opacitySlider:SetWidth(220)
opacitySlider:SetHeight(16)
opacitySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -42)
opacitySlider:SetMinMaxValues(
    minimumWindowOpacityPercent,
    maximumWindowOpacityPercent)
opacitySlider:SetValueStep(windowOpacityStepPercent)
opacitySlider:SetValue(defaultWindowOpacityPercent)

if GetUsThereOpacitySliderLow then
    GetUsThereOpacitySliderLow:SetText(minimumWindowOpacityPercent .. "%")
end

if GetUsThereOpacitySliderHigh then
    GetUsThereOpacitySliderHigh:SetText(maximumWindowOpacityPercent .. "%")
end

if GetUsThereOpacitySliderText then
    GetUsThereOpacitySliderText:SetText(
        "Window Opacity: " .. defaultWindowOpacityPercent .. "%")
end

opacitySlider:SetScript("OnValueChanged", function(self, value)
    local normalized = NormalizeWindowOpacityPercent(value)

    if math.abs(value - normalized) > 0.01 then
        self:SetValue(normalized)
        return
    end

    if type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table" then
        GetUsThereDB.preferences.windowOpacityPercent = normalized
    end

    ApplyWindowOpacityPercent(normalized)
end)

local textSizeSlider =
    CreateFrame(
        "Slider",
        "GetUsThereTextSizeSlider",
        appearancePanel,
        "OptionsSliderTemplate")

textSizeSlider:SetWidth(220)
textSizeSlider:SetHeight(16)
textSizeSlider:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -42)
textSizeSlider:SetMinMaxValues(
    minimumTextSizePercent,
    maximumTextSizePercent)
textSizeSlider:SetValueStep(textSizeStepPercent)
textSizeSlider:SetValue(defaultTextSizePercent)

if GetUsThereTextSizeSliderLow then
    GetUsThereTextSizeSliderLow:SetText(minimumTextSizePercent .. "%")
end

if GetUsThereTextSizeSliderHigh then
    GetUsThereTextSizeSliderHigh:SetText(maximumTextSizePercent .. "%")
end

if GetUsThereTextSizeSliderText then
    GetUsThereTextSizeSliderText:SetText(
        "Text Size: " .. defaultTextSizePercent .. "%")
end

textSizeSlider:SetScript("OnValueChanged", function(self, value)
    local normalized = NormalizeTextSizePercent(value)

    if math.abs(value - normalized) > 0.01 then
        self:SetValue(normalized)
        return
    end

    if type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table" then
        GetUsThereDB.preferences.textSizePercent = normalized
    end

    ApplyTextAppearance(normalized)
end)

local optionsVersion =
    optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

optionsVersion:SetPoint("BOTTOMLEFT", 28, 26)
optionsVersion:SetText(
    "Version: " .. (GetAddOnMetadata(addonName, "Version") or "unknown"))

local optionsButton =
    CreateFrame(
        "Button",
        "GetUsThereOptionsButton",
        frame,
        "UIPanelButtonTemplate")

optionsButton:SetWidth(62)
optionsButton:SetHeight(22)
optionsButton:SetPoint("TOPRIGHT", -31, -8)
optionsButton:SetText("Options")

optionsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Get Us There Options")
    GameTooltip:Show()
end)

optionsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

optionsButton:SetScript("OnClick", function()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end)

local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
searchLabel:SetPoint("TOPLEFT", 24, -58)
searchLabel:SetText("All Destinations")

local searchBox = CreateFrame("EditBox", "GetUsThereSearchBox", frame, "InputBoxTemplate")
searchBox:SetWidth(380)
searchBox:SetHeight(24)
searchBox:SetPoint("TOPLEFT", 24, -78)
searchBox:SetAutoFocus(false)

local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
sendButton:SetWidth(100)
sendButton:SetHeight(24)
sendButton:SetPoint("LEFT", searchBox, "RIGHT", 14, 0)
sendButton:SetText("Send Us")
sendButton:Disable()

local categoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryLabel:SetPoint("TOPLEFT", 24, -116)
categoryLabel:SetText("Browse by Category")

local categoryTabs = {}

local function SetCategoryTabAppearance(button, isActive)
    local fontString = button:GetFontString()
    local yOffset = -136

    button:Enable()
    button:ClearAllPoints()

    if isActive then
        yOffset = -132
        button:SetHeight(26)
        button:SetAlpha(1.0)
        button:SetPoint("TOPLEFT", button.tabX, yOffset)
        button:LockHighlight()

        if fontString then
            fontString:SetTextColor(1.0, 0.82, 0.0)
        end
    else
        button:SetHeight(22)
        button:SetAlpha(0.65)
        button:SetPoint("TOPLEFT", button.tabX, yOffset)
        button:UnlockHighlight()

        if fontString then
            fontString:SetTextColor(0.62, 0.62, 0.62)
        end
    end
end

local function CreateCategoryTab(text, scope, x, width)
    local button =
        CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button.tabX = x
    button:SetWidth(width)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", x, -136)
    button:SetAlpha(0.65)
    button:SetText(text)
    button.searchScope = scope
    button.searchLabel = text
    table.insert(categoryTabs, button)
    return button
end

CreateCategoryTab("Cities", "CITIES", 24, 78)
CreateCategoryTab("Settlements", "SETTLEMENTS", 106, 96)
CreateCategoryTab("Dungeons & Raids", "DUNGEONS_RAIDS", 206, 132)
CreateCategoryTab("Leveling Zones", "LEVELING_ZONES", 342, 118)

local categorySearchLabel =
    frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categorySearchLabel:SetPoint("TOPLEFT", 24, -170)
categorySearchLabel:SetText("Search Cities")

local categorySearchBox =
    CreateFrame(
        "EditBox",
        "GetUsThereCategorySearchBox",
        frame,
        "InputBoxTemplate")
categorySearchBox:SetWidth(380)
categorySearchBox:SetHeight(24)
categorySearchBox:SetPoint("TOPLEFT", 24, -190)
categorySearchBox:SetAutoFocus(false)

local resultsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultsLabel:SetPoint("TOPLEFT", 24, -224)
resultsLabel:SetText("Search Results")

local resultsDropDown = CreateFrame(
    "Frame",
    "GetUsThereResultsDropDown",
    frame,
    "UIDropDownMenuTemplate")
resultsDropDown:SetPoint("TOPLEFT", 5, -236)
UIDropDownMenu_SetWidth(resultsDropDown, 430)
UIDropDownMenu_SetText(resultsDropDown, "No search yet")

local selected = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
selected:SetPoint("TOPLEFT", 24, -276)
selected:SetJustifyH("LEFT")
selected:SetText("No destination selected.")

local ownerStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ownerStatus:SetPoint("TOPLEFT", 24, -296)
ownerStatus:SetJustifyH("LEFT")
ownerStatus:SetTextColor(1, 0.2, 0.2)
ownerStatus:SetText("")
ownerStatus:Hide()

local arrivalLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
arrivalLabel:SetPoint("TOPLEFT", 250, -326)
arrivalLabel:SetText("Arrival")
arrivalLabel:Hide()

local arrivalDropDown = CreateFrame(
    "Frame",
    "GetUsThereArrivalDropDown",
    frame,
    "UIDropDownMenuTemplate")
arrivalDropDown:SetPoint("TOPLEFT", 228, -336)
UIDropDownMenu_SetWidth(arrivalDropDown, 185)
UIDropDownMenu_SetText(arrivalDropDown, "No arrival choices")
arrivalDropDown:Hide()

local worldTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
worldTitle:SetPoint("TOPLEFT", 24, -326)
worldTitle:SetText("World Coordinates")

local worldCoords = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
worldCoords:SetPoint("TOPLEFT", 24, -348)
worldCoords:SetJustifyH("LEFT")
worldCoords:SetText("Map: --\nX: --\nY: --\nZ: --")

local overrideEnabled = false

local override = CreateFrame(
    "Button",
    "GetUsThereOverrideButton",
    frame,
    "UIPanelButtonTemplate")
override:SetWidth(90)
override:SetHeight(24)
override:SetPoint("TOPLEFT", 20, -416)

local overrideHelp = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight")
overrideHelp:SetPoint("LEFT", override, "RIGHT", 8, 0)
overrideHelp:SetText("Screw you! I'll go where I want, whenever I want.")

local function IsOverrideEnabled()
    return overrideEnabled
end

local function UpdateOverrideButtonAppearance()
    local fontString = override:GetFontString()

    if overrideEnabled then
        override:SetText("Enabled")

        if fontString then
            fontString:SetTextColor(0.2, 1.0, 0.2)
        end
    else
        override:SetText("Disabled")

        if fontString then
            fontString:SetTextColor(1.0, 0.2, 0.2)
        end
    end
end

UpdateOverrideButtonAppearance()

local raw = CreateFrame("Frame", nil, frame)
raw:SetWidth(370)
raw:SetHeight(140)
raw:SetPoint("TOPLEFT", 24, -461)
raw:Hide()

local warning = raw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
warning:SetPoint("TOPLEFT", 0, 0)
warning:SetText("Raw coordinates bypass curated safe destinations.")

local rawLabel = raw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rawLabel:SetPoint("TOPLEFT", 0, -24)
rawLabel:SetText("Raw Coordinates")

local rawMapLabel = raw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rawMapLabel:SetPoint("TOPLEFT", 0, -48)
rawMapLabel:SetText("Map")

local rawMapBox = CreateFrame("EditBox", "GetUsThereRawMapBox", raw, "InputBoxTemplate")
rawMapBox:SetWidth(70)
rawMapBox:SetHeight(24)
rawMapBox:SetPoint("TOPLEFT", 0, -62)
rawMapBox:SetAutoFocus(false)
rawMapBox:SetMaxLetters(10)

local rawXLabel = raw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rawXLabel:SetPoint("TOPLEFT", 90, -48)
rawXLabel:SetText("X")

local rawXBox = CreateFrame("EditBox", "GetUsThereRawXBox", raw, "InputBoxTemplate")
rawXBox:SetWidth(80)
rawXBox:SetHeight(24)
rawXBox:SetPoint("TOPLEFT", 90, -62)
rawXBox:SetAutoFocus(false)
rawXBox:SetMaxLetters(24)

local rawYLabel = raw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rawYLabel:SetPoint("TOPLEFT", 185, -48)
rawYLabel:SetText("Y")

local rawYBox = CreateFrame("EditBox", "GetUsThereRawYBox", raw, "InputBoxTemplate")
rawYBox:SetWidth(80)
rawYBox:SetHeight(24)
rawYBox:SetPoint("TOPLEFT", 185, -62)
rawYBox:SetAutoFocus(false)
rawYBox:SetMaxLetters(24)

local rawZLabel = raw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rawZLabel:SetPoint("TOPLEFT", 280, -48)
rawZLabel:SetText("Z")

local rawZBox = CreateFrame("EditBox", "GetUsThereRawZBox", raw, "InputBoxTemplate")
rawZBox:SetWidth(80)
rawZBox:SetHeight(24)
rawZBox:SetPoint("TOPLEFT", 280, -62)
rawZBox:SetAutoFocus(false)
rawZBox:SetMaxLetters(24)

local rawButton = CreateFrame("Button", nil, raw, "UIPanelButtonTemplate")
rawButton:SetWidth(170)
rawButton:SetHeight(24)
rawButton:SetPoint("TOPLEFT", 0, -104)
rawButton:SetText("Send Us Exactly Here")
rawButton:Disable()

local pendingRawRequestId = nil
local pendingRawMapId = nil

local function ParseRawMapId()
    local text = rawMapBox:GetText() or ""

    if not string.match(text, "^%d+$") then
        return nil
    end

    local value = tonumber(text)

    if not value
        or value < 0
        or value > 4294967295
        or value ~= math.floor(value) then
        return nil
    end

    return value
end

local function ParseRawCoordinate(editBox)
    local text = editBox:GetText() or ""
    local value = tonumber(text)

    if not value or value ~= value
        or value == math.huge
        or value == -math.huge then
        return nil
    end

    return value
end

local function UpdateRawButtonState()
    if not IsOverrideEnabled() or pendingRawRequestId then
        rawButton:Disable()
        return
    end

    local mapId = ParseRawMapId()
    local x = ParseRawCoordinate(rawXBox)
    local y = ParseRawCoordinate(rawYBox)
    local z = ParseRawCoordinate(rawZBox)

    if mapId and x and y and z then
        rawButton:Enable()
    else
        rawButton:Disable()
    end
end

local showRawCoordinatesCheck =
    CreateFrame(
        "CheckButton",
        "GetUsThereShowRawCoordinatesCheck",
        displayPanel,
        "UICheckButtonTemplate")

showRawCoordinatesCheck:SetPoint(
    "TOPLEFT",
    displayPanel,
    "TOPLEFT",
    4,
    -12)
showRawCoordinatesCheck:SetChecked(defaultShowRawCoordinates)

local showRawCoordinatesText =
    showRawCoordinatesCheck:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight")

showRawCoordinatesText:SetPoint(
    "LEFT",
    showRawCoordinatesCheck,
    "RIGHT",
    4,
    0)
showRawCoordinatesText:SetText("Show Manual Map / X / Y / Z Controls")

local showRawCoordinatesHelp =
    displayPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall")

showRawCoordinatesHelp:SetPoint(
    "TOPLEFT",
    showRawCoordinatesCheck,
    "BOTTOMLEFT",
    24,
    -2)
showRawCoordinatesHelp:SetWidth(345)
showRawCoordinatesHelp:SetJustifyH("LEFT")
showRawCoordinatesHelp:SetText(
    "Shows the manual coordinate panel when Screw You! is enabled. " ..
    "This does not hide or disable Screw You!, which can also request " ..
    "override travel for searched destinations.")

rememberWindowPositionCheck =
    CreateFrame(
        "CheckButton",
        "GetUsThereRememberWindowPositionCheck",
        windowPanel,
        "UICheckButtonTemplate")

rememberWindowPositionCheck:SetPoint(
    "TOPLEFT",
    windowPanel,
    "TOPLEFT",
    4,
    -12)
rememberWindowPositionCheck:SetChecked(defaultRememberWindowPosition)

local rememberWindowPositionText =
    rememberWindowPositionCheck:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight")

rememberWindowPositionText:SetPoint(
    "LEFT",
    rememberWindowPositionCheck,
    "RIGHT",
    4,
    0)
rememberWindowPositionText:SetText("Remember Window Position")

local rememberWindowPositionHelp =
    windowPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall")

rememberWindowPositionHelp:SetPoint(
    "TOPLEFT",
    rememberWindowPositionCheck,
    "BOTTOMLEFT",
    24,
    -2)
rememberWindowPositionHelp:SetWidth(345)
rememberWindowPositionHelp:SetJustifyH("LEFT")
rememberWindowPositionHelp:SetText(
    "Restores the main Get Us There window to its last dragged position. " ..
    "When disabled, the next reload starts the main window centered.")

rememberWindowPositionCheck:SetScript("OnClick", function(self)
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table" then
        return
    end

    local enabled = self:GetChecked() and true or false
    GetUsThereDB.preferences.rememberWindowPosition = enabled

    if enabled then
        SaveCurrentWindowPosition()
    else
        GetUsThereDB.preferences.windowPosition = nil
    end
end)

lockWindowPositionCheck =
    CreateFrame(
        "CheckButton",
        "GetUsThereLockWindowPositionCheck",
        windowPanel,
        "UICheckButtonTemplate")

lockWindowPositionCheck:SetPoint(
    "TOPLEFT",
    rememberWindowPositionHelp,
    "BOTTOMLEFT",
    -24,
    -12)
lockWindowPositionCheck:SetChecked(defaultLockWindowPosition)

local lockWindowPositionText =
    lockWindowPositionCheck:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight")

lockWindowPositionText:SetPoint(
    "LEFT",
    lockWindowPositionCheck,
    "RIGHT",
    4,
    0)
lockWindowPositionText:SetText("Lock Window Position")

local lockWindowPositionHelp =
    windowPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall")

lockWindowPositionHelp:SetPoint(
    "TOPLEFT",
    lockWindowPositionCheck,
    "BOTTOMLEFT",
    24,
    -2)
lockWindowPositionHelp:SetWidth(345)
lockWindowPositionHelp:SetJustifyH("LEFT")
lockWindowPositionHelp:SetText(
    "Prevents the main Get Us There window from being dragged. " ..
    "Its remembered position is kept and can be used again when unlocked.")

lockWindowPositionCheck:SetScript("OnClick", function(self)
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table" then
        return
    end

    GetUsThereDB.preferences.lockWindowPosition =
        self:GetChecked() and true or false
end)

hideInCombatCheck =
    CreateFrame(
        "CheckButton",
        "GetUsThereHideInCombatCheck",
        windowPanel,
        "UICheckButtonTemplate")

hideInCombatCheck:SetPoint(
    "TOPLEFT",
    lockWindowPositionHelp,
    "BOTTOMLEFT",
    -24,
    -12)

hideInCombatCheck:SetChecked(defaultHideInCombat)

local hideInCombatText =
    hideInCombatCheck:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight")

hideInCombatText:SetPoint(
    "LEFT",
    hideInCombatCheck,
    "RIGHT",
    4,
    0)

hideInCombatText:SetText("Hide in Combat")

local hideInCombatHelp =
    windowPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall")

hideInCombatHelp:SetPoint(
    "TOPLEFT",
    hideInCombatCheck,
    "BOTTOMLEFT",
    24,
    -2)

hideInCombatHelp:SetWidth(345)
hideInCombatHelp:SetJustifyH("LEFT")
hideInCombatHelp:SetText(
    "Automatically hides the main Get Us There window and Options window " ..
    "when combat begins.")

hideInCombatCheck:SetScript("OnClick", function(self)
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table" then
        return
    end

    GetUsThereDB.preferences.hideInCombat =
        self:GetChecked() and true or false
end)

restoreAfterCombatCheck =
    CreateFrame(
        "CheckButton",
        "GetUsThereRestoreAfterCombatCheck",
        windowPanel,
        "UICheckButtonTemplate")

restoreAfterCombatCheck:SetPoint(
    "TOPLEFT",
    hideInCombatHelp,
    "BOTTOMLEFT",
    -24,
    -12)

restoreAfterCombatCheck:SetChecked(defaultRestoreAfterCombat)

local restoreAfterCombatText =
    restoreAfterCombatCheck:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight")

restoreAfterCombatText:SetPoint(
    "LEFT",
    restoreAfterCombatCheck,
    "RIGHT",
    4,
    0)

restoreAfterCombatText:SetText("Restore After Combat")

local restoreAfterCombatHelp =
    windowPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall")

restoreAfterCombatHelp:SetPoint(
    "TOPLEFT",
    restoreAfterCombatCheck,
    "BOTTOMLEFT",
    24,
    -2)

restoreAfterCombatHelp:SetWidth(345)
restoreAfterCombatHelp:SetJustifyH("LEFT")
restoreAfterCombatHelp:SetText(
    "When Hide in Combat is enabled, restores whichever Get Us There " ..
    "windows were open when combat began. Windows already closed stay closed.")

restoreAfterCombatCheck:SetScript("OnClick", function(self)
    if type(GetUsThereDB) ~= "table"
        or type(GetUsThereDB.preferences) ~= "table" then
        return
    end

    GetUsThereDB.preferences.restoreAfterCombat =
        self:GetChecked() and true or false
end)

local function IsHideInCombatEnabled()
    return type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table"
        and GetUsThereDB.preferences.hideInCombat == true
end

local function IsRestoreAfterCombatEnabled()
    return type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table"
        and GetUsThereDB.preferences.restoreAfterCombat == true
end

ApplyRawVisibility = function()
    local showRaw = defaultShowRawCoordinates

    if type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table"
        and type(GetUsThereDB.preferences.showRawCoordinates) == "boolean" then
        showRaw = GetUsThereDB.preferences.showRawCoordinates
    end

    showRawCoordinatesCheck:SetChecked(showRaw)

    if showRaw and IsOverrideEnabled() then
        raw:Show()
    else
        raw:Hide()
    end

    UpdateRawButtonState()
end

showRawCoordinatesCheck:SetScript("OnClick", function(self)
    if type(GetUsThereDB) == "table"
        and type(GetUsThereDB.preferences) == "table" then
        GetUsThereDB.preferences.showRawCoordinates =
            self:GetChecked() and true or false
    end

    ApplyRawVisibility()
end)

override:SetScript("OnClick", function()
    overrideEnabled = not overrideEnabled
    UpdateOverrideButtonAppearance()
    ApplyRawVisibility()
end)

rawMapBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawXBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawYBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawZBox:SetScript("OnTextChanged", UpdateRawButtonState)


local protocolState = {
    results = {},
    arrivalChoices = {},
    destinationStatus = {},
    settlementFactionStatus = {},
    destinationFactionStatus = {},
    rivalCapitalFactionStatus = {},
    levelRestrictionStatus = {},
    done = nil,
    teleported = nil,
    choiceTeleported = nil,
    coordTeleported = nil,
    error = nil
}

local nextRequestId = 1
local pendingSearchRequestId = nil
local pendingSearchAutoOpen = false
local lastSearchSentAt = -1000
local lastSearchQuery = nil
local lastSearchScope = nil
local pendingTeleportRequestId = nil
local pendingTeleportGameTeleId = nil
local pendingTeleportChoiceId = nil
local selectedDestination = nil
local selectedArrivalChoice = nil
local activeSearchScope = "CITIES"
local ClearCuratedSearchStateAfterRawTeleport = nil

local function AllocateRequestId()
    local requestId = nextRequestId
    nextRequestId = nextRequestId + 1

    if nextRequestId > 4294967295 then
        nextRequestId = 1
    end

    return requestId
end

local function ClearSelectedDestination(message)
    selectedDestination = nil
    selectedArrivalChoice = nil
    selected:SetText(message or "No destination selected.")
    ownerStatus:SetText("")
    ownerStatus:Hide()
    UIDropDownMenu_SetText(arrivalDropDown, "No arrival choices")
    arrivalLabel:Hide()
    arrivalDropDown:Hide()
    worldCoords:SetText("Map: --\nX: --\nY: --\nZ: --")
    sendButton:Disable()
end

local function ShowSelectedDestination(destination)
    selectedDestination = destination

    if destination.levelRestriction then
        selected:SetText(string.format(
            "%s - %s | Level %d; %d+ needed (recommended %d)",
            destination.displayName,
            destination.category,
            destination.levelRestriction.playerLevel,
            destination.levelRestriction.minimumAllowedLevel,
            destination.levelRestriction.recommendedLevel))
    elseif destination.rivalCapitalFaction then
        selected:SetText(string.format(
            "%s - Server error: RIVAL_CAPITAL_BLOCKED",
            destination.displayName))
    else
        selected:SetText(
            destination.displayName .. " - " .. destination.category)
    end

    local playerFaction = UnitFactionGroup("player")

    local opposingFaction =
        (destination.destinationFaction == "HORDE"
            and playerFaction == "Alliance")
        or (destination.destinationFaction == "ALLIANCE"
            and playerFaction == "Horde")

    if opposingFaction then
        ownerStatus:SetTextColor(1, 0.2, 0.2)

        if destination.destinationFactionBlocked then
            ownerStatus:SetText(
                "Enable Screw You! and defy restrictions at your own peril, explorer.")
        else
            ownerStatus:SetText(
                "Opposing faction territory. Proceed at your own peril, explorer.")
        end

        ownerStatus:Show()
    elseif destination.wintergraspOwner == "HORDE" then
        ownerStatus:SetTextColor(1, 0.2, 0.2)
        ownerStatus:SetText("Held By Horde")
        ownerStatus:Show()
    elseif destination.wintergraspOwner == "ALLIANCE" then
        ownerStatus:SetTextColor(1, 0.2, 0.2)
        ownerStatus:SetText("Held By Alliance")
        ownerStatus:Show()
    elseif destination.settlementFaction == "HORDE" then
        if playerFaction == "Horde" then
            ownerStatus:SetTextColor(0.2, 1, 0.2)
        else
            ownerStatus:SetTextColor(1, 0.2, 0.2)
        end
        ownerStatus:SetText("Horde Settlement")
        ownerStatus:Show()
    elseif destination.settlementFaction == "ALLIANCE" then
        if playerFaction == "Alliance" then
            ownerStatus:SetTextColor(0.2, 1, 0.2)
        else
            ownerStatus:SetTextColor(1, 0.2, 0.2)
        end
        ownerStatus:SetText("Alliance Settlement")
        ownerStatus:Show()
    else
        ownerStatus:SetText("")
        ownerStatus:Hide()
    end

    selectedArrivalChoice = nil

    local choices =
        protocolState.arrivalChoices[destination.gameTeleId]

    if choices and #choices > 0 then
        for index = 1, #choices do
            if choices[index].isDefault then
                selectedArrivalChoice = choices[index]
                break
            end
        end

        if selectedArrivalChoice then
            UIDropDownMenu_SetText(
                arrivalDropDown,
                selectedArrivalChoice.displayLabel)
        else
            UIDropDownMenu_SetText(
                arrivalDropDown,
                "Choose arrival")
        end

        arrivalLabel:Show()
        arrivalDropDown:Show()
    else
        UIDropDownMenu_SetText(
            arrivalDropDown,
            "No arrival choices")
        arrivalLabel:Hide()
        arrivalDropDown:Hide()
    end

    worldCoords:SetText(string.format(
        "Map: %d\nX: %.2f\nY: %.2f\nZ: %.2f",
        destination.mapId,
        destination.x,
        destination.y,
        destination.z))

    if pendingTeleportRequestId then
        sendButton:Disable()
    elseif choices and #choices > 0
        and not selectedArrivalChoice then
        sendButton:Disable()
    else
        sendButton:Enable()
    end
end

local function SelectSearchResult(destination)
    ShowSelectedDestination(destination)
    UIDropDownMenu_SetText(resultsDropDown, destination.displayName)
end

UIDropDownMenu_Initialize(arrivalDropDown, function(self, level)
    if not selectedDestination then
        return
    end

    local choices =
        protocolState.arrivalChoices[selectedDestination.gameTeleId]

    if not choices then
        return
    end

    for index = 1, #choices do
        local choice = choices[index]
        local info = UIDropDownMenu_CreateInfo()
        info.fontObject = dropdownTextFont

        info.text = choice.displayLabel
        info.checked =
            selectedArrivalChoice
            and selectedArrivalChoice.choiceId == choice.choiceId

        info.func = function()
            selectedArrivalChoice = choice
            UIDropDownMenu_SetText(
                arrivalDropDown,
                choice.displayLabel)

            if not pendingTeleportRequestId then
                sendButton:Enable()
            end
        end

        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_Initialize(resultsDropDown, function(self, level)
    for index = 1, #protocolState.results do
        local destination = protocolState.results[index]
        local info = UIDropDownMenu_CreateInfo()
        info.fontObject = dropdownTextFont

        if destination.rivalCapitalFaction then
            info.text = string.format(
                "%s - %s | RIVAL_CAPITAL_BLOCKED",
                destination.displayName,
                destination.category)
        elseif destination.levelRestriction then
            info.text = string.format(
                "%s - %s | Level %d; %d+ needed",
                destination.displayName,
                destination.category,
                destination.levelRestriction.playerLevel,
                destination.levelRestriction.minimumAllowedLevel)
        else
            info.text =
                destination.displayName .. " - " .. destination.category
        end

        info.func = function()
            SelectSearchResult(destination)
        end

        UIDropDownMenu_AddButton(info, level)
    end
end)

local function SplitProtocolFields(message)
    local fields = {}

    for field in string.gmatch(message .. "\t", "(.-)\t") do
        table.insert(fields, field)
    end

    return fields
end

local function ParseServerMessage(message)
    local fields = SplitProtocolFields(message)
    local kind = fields[1]

    if kind == "RESULT" and #fields == 11 then
        local result = {
            requestId = tonumber(fields[2]),
            gameTeleId = tonumber(fields[3]),
            displayName = fields[4],
            category = fields[5],
            recommendedLevel = tonumber(fields[6]),
            groupTeleportAllowed = fields[7] == "1",
            mapId = tonumber(fields[8]),
            x = tonumber(fields[9]),
            y = tonumber(fields[10]),
            z = tonumber(fields[11])
        }

        if result.requestId and result.gameTeleId and result.mapId
            and result.x and result.y and result.z
            and result.requestId == pendingSearchRequestId then
            result.wintergraspOwner =
                protocolState.destinationStatus[result.gameTeleId]
            result.settlementFaction =
                protocolState.settlementFactionStatus[result.gameTeleId]

            local destinationFactionStatus =
                protocolState.destinationFactionStatus[result.gameTeleId]

            if destinationFactionStatus then
                result.destinationFaction =
                    destinationFactionStatus.faction
                result.destinationFactionBlocked =
                    destinationFactionStatus.blocked
            end

            result.rivalCapitalFaction =
                protocolState.rivalCapitalFactionStatus[result.gameTeleId]
            result.levelRestriction =
                protocolState.levelRestrictionStatus[result.gameTeleId]
            table.insert(protocolState.results, result)
        end
    elseif kind == "CHOICE" and #fields == 7 then
        local choice = {
            requestId = tonumber(fields[2]),
            gameTeleId = tonumber(fields[3]),
            choiceId = tonumber(fields[4]),
            arrivalMode = fields[5],
            displayLabel = fields[6],
            isDefault = fields[7] == "1"
        }

        if choice.requestId == pendingSearchRequestId
            and choice.gameTeleId
            and choice.choiceId
            and choice.choiceId >= 1
            and choice.choiceId <= 65535
            and (choice.arrivalMode == "OUTSIDE"
                or choice.arrivalMode == "INSIDE")
            and choice.displayLabel ~= ""
            and (fields[7] == "0" or fields[7] == "1") then
            local choices =
                protocolState.arrivalChoices[choice.gameTeleId]

            if not choices then
                choices = {}
                protocolState.arrivalChoices[choice.gameTeleId] = choices
            end

            local duplicate = false

            for index = 1, #choices do
                if choices[index].choiceId == choice.choiceId then
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                table.insert(choices, choice)
            end
        end
    elseif kind == "STATUS" and #fields == 7 then
        local requestId = tonumber(fields[2])
        local gameTeleId = tonumber(fields[3])
        local statusType = fields[4]
        local playerLevel = tonumber(fields[5])
        local recommendedLevel = tonumber(fields[6])
        local minimumAllowedLevel = tonumber(fields[7])

        if requestId == pendingSearchRequestId
            and gameTeleId
            and statusType == "LEVEL_TOO_LOW"
            and playerLevel
            and recommendedLevel
            and minimumAllowedLevel
            and playerLevel >= 1
            and recommendedLevel >= 1
            and minimumAllowedLevel >= 1
            and minimumAllowedLevel <= recommendedLevel
            and playerLevel < minimumAllowedLevel then
            local status = {
                playerLevel = playerLevel,
                recommendedLevel = recommendedLevel,
                minimumAllowedLevel = minimumAllowedLevel
            }

            protocolState.levelRestrictionStatus[gameTeleId] = status

            for index = 1, #protocolState.results do
                local destination = protocolState.results[index]

                if destination.gameTeleId == gameTeleId then
                    destination.levelRestriction = status
                end
            end
        end
    elseif kind == "STATUS" and #fields == 5 then
        local requestId = tonumber(fields[2])
        local gameTeleId = tonumber(fields[3])
        local statusType = fields[4]
        local statusValue = fields[5]

        if requestId == pendingSearchRequestId
            and gameTeleId
            and statusType == "WINTERGRASP_OWNER"
            and (statusValue == "HORDE"
                or statusValue == "ALLIANCE"
                or statusValue == "UNKNOWN") then
            protocolState.destinationStatus[gameTeleId] = statusValue

            for index = 1, #protocolState.results do
                local destination = protocolState.results[index]

                if destination.gameTeleId == gameTeleId then
                    destination.wintergraspOwner = statusValue
                end
            end
        elseif requestId == pendingSearchRequestId
            and gameTeleId
            and statusType == "DESTINATION_FACTION"
            and (statusValue == "HORDE_ALLOWED"
                or statusValue == "HORDE_BLOCKED"
                or statusValue == "ALLIANCE_ALLOWED"
                or statusValue == "ALLIANCE_BLOCKED") then
            local faction = nil
            local blocked = false

            if statusValue == "HORDE_ALLOWED" then
                faction = "HORDE"
            elseif statusValue == "HORDE_BLOCKED" then
                faction = "HORDE"
                blocked = true
            elseif statusValue == "ALLIANCE_ALLOWED" then
                faction = "ALLIANCE"
            elseif statusValue == "ALLIANCE_BLOCKED" then
                faction = "ALLIANCE"
                blocked = true
            end

            protocolState.destinationFactionStatus[gameTeleId] = {
                faction = faction,
                blocked = blocked
            }

            for index = 1, #protocolState.results do
                local destination = protocolState.results[index]

                if destination.gameTeleId == gameTeleId then
                    destination.destinationFaction = faction
                    destination.destinationFactionBlocked = blocked
                end
            end
        elseif requestId == pendingSearchRequestId
            and gameTeleId
            and statusType == "SETTLEMENT_FACTION"
            and (statusValue == "HORDE"
                or statusValue == "ALLIANCE"
                or statusValue == "NEUTRAL") then
            protocolState.settlementFactionStatus[gameTeleId] = statusValue

            for index = 1, #protocolState.results do
                local destination = protocolState.results[index]

                if destination.gameTeleId == gameTeleId then
                    destination.settlementFaction = statusValue
                end
            end
        elseif requestId == pendingSearchRequestId
            and gameTeleId
            and statusType == "RIVAL_CAPITAL_BLOCKED"
            and (statusValue == "HORDE"
                or statusValue == "ALLIANCE") then
            protocolState.rivalCapitalFactionStatus[gameTeleId] = statusValue

            for index = 1, #protocolState.results do
                local destination = protocolState.results[index]

                if destination.gameTeleId == gameTeleId then
                    destination.rivalCapitalFaction = statusValue
                end
            end
        end
    elseif kind == "DONE" and #fields == 3 then
        protocolState.done = {
            requestId = tonumber(fields[2]),
            resultCount = tonumber(fields[3])
        }

        if protocolState.done.requestId == pendingSearchRequestId then
            if #protocolState.results == 1 then
                SelectSearchResult(protocolState.results[1])
            elseif #protocolState.results > 1 then
                ClearSelectedDestination("Choose a destination from Search Results.")
                UIDropDownMenu_SetText(
                    resultsDropDown,
                    #protocolState.results .. " destinations found")
            else
                ClearSelectedDestination("No destination found.")
                UIDropDownMenu_SetText(resultsDropDown, "No destinations found")
            end

            if pendingSearchAutoOpen
                and #protocolState.results > 1 then
                CloseDropDownMenus(1)
                ToggleDropDownMenu(1, nil, resultsDropDown)
            end

            pendingSearchRequestId = nil
            pendingSearchAutoOpen = false
        end
    elseif kind == "TELEPORTED" and #fields == 4 then
        protocolState.teleported = {
            requestId = tonumber(fields[2]),
            gameTeleId = tonumber(fields[3]),
            status = fields[4]
        }

        if protocolState.teleported.requestId == pendingTeleportRequestId
            and protocolState.teleported.gameTeleId == pendingTeleportGameTeleId
            and pendingTeleportChoiceId == nil then
            pendingTeleportRequestId = nil
            pendingTeleportGameTeleId = nil

            if selectedDestination then
                sendButton:Enable()
            end
        end
    elseif kind == "CHOICE_TELEPORTED" and #fields == 5 then
        protocolState.choiceTeleported = {
            requestId = tonumber(fields[2]),
            gameTeleId = tonumber(fields[3]),
            choiceId = tonumber(fields[4]),
            status = fields[5]
        }

        if protocolState.choiceTeleported.requestId == pendingTeleportRequestId
            and protocolState.choiceTeleported.gameTeleId == pendingTeleportGameTeleId
            and protocolState.choiceTeleported.choiceId == pendingTeleportChoiceId then
            pendingTeleportRequestId = nil
            pendingTeleportGameTeleId = nil
            pendingTeleportChoiceId = nil

            if selectedDestination then
                sendButton:Enable()
            end
        end
    elseif kind == "COORD_TELEPORTED" and #fields == 4 then
        protocolState.coordTeleported = {
            requestId = tonumber(fields[2]),
            mapId = tonumber(fields[3]),
            status = fields[4]
        }

        if protocolState.coordTeleported.requestId == pendingRawRequestId
            and protocolState.coordTeleported.mapId == pendingRawMapId then
            pendingRawRequestId = nil
            pendingRawMapId = nil

            if protocolState.coordTeleported.status == "OK"
                and ClearCuratedSearchStateAfterRawTeleport then
                ClearCuratedSearchStateAfterRawTeleport()
            end

            UpdateRawButtonState()
        end
    elseif kind == "ERROR" and #fields >= 2 then
        protocolState.error = {
            code = fields[2],
            requestId = tonumber(fields[3]),
            contextId = tonumber(fields[4]),
            choiceId = tonumber(fields[5])
        }

        if protocolState.error.requestId == pendingSearchRequestId then
            ClearSelectedDestination("Server error: " .. protocolState.error.code)
            UIDropDownMenu_SetText(resultsDropDown, "Search failed")
            pendingSearchRequestId = nil
            pendingSearchAutoOpen = false
        end

        if protocolState.error.requestId == pendingTeleportRequestId
            and protocolState.error.contextId == pendingTeleportGameTeleId
            and (pendingTeleportChoiceId == nil
                or protocolState.error.choiceId == pendingTeleportChoiceId) then
            pendingTeleportRequestId = nil
            pendingTeleportGameTeleId = nil
            pendingTeleportChoiceId = nil

            if selectedDestination then
                selected:SetText(
                    selectedDestination.displayName ..
                    " - Server error: " ..
                    protocolState.error.code)

                local choices =
                    protocolState.arrivalChoices[
                        selectedDestination.gameTeleId]

                if choices and #choices > 0
                    and not selectedArrivalChoice then
                    sendButton:Disable()
                else
                    sendButton:Enable()
                end
            end
        end

        if protocolState.error.requestId == pendingRawRequestId
            and protocolState.error.contextId == pendingRawMapId then
            pendingRawRequestId = nil
            pendingRawMapId = nil

            ClearSelectedDestination(
                "Raw coordinate error: " .. protocolState.error.code)

            UpdateRawButtonState()
        end
    end
end

local function SendSearch(editBox, scope, autoOpen)
    local query = editBox:GetText() or ""
    query = string.gsub(query, "^%s+", "")
    query = string.gsub(query, "%s+$", "")

    if query == "" then
        ClearSelectedDestination("Enter a destination.")
        return
    end

    if string.len(query) > 96 or string.find(query, "[%c]") then
        ClearSelectedDestination("Destination search is invalid.")
        return
    end

    if pendingSearchRequestId
        and lastSearchQuery == query
        and lastSearchScope == scope then
        return
    end

    local requestId = AllocateRequestId()
    local command = "SEARCH"

    if scope then
        command = "SEARCH_SCOPE"

        if IsOverrideEnabled() then
            command = "SEARCH_SCOPE_TEST"
        end
    elseif IsOverrideEnabled() then
        command = "SEARCH_TEST"
    end

    protocolState.results = {}
    protocolState.arrivalChoices = {}
    protocolState.destinationStatus = {}
    protocolState.settlementFactionStatus = {}
    protocolState.destinationFactionStatus = {}
    protocolState.levelRestrictionStatus = {}
    protocolState.rivalCapitalFactionStatus = {}
    protocolState.done = nil
    protocolState.error = nil
    pendingSearchRequestId = requestId
    pendingSearchAutoOpen = autoOpen and true or false
    lastSearchSentAt = GetTime()
    lastSearchQuery = query
    lastSearchScope = scope

    ClearSelectedDestination("Searching for: " .. query)
    UIDropDownMenu_SetText(resultsDropDown, "Searching...")

    local payload = command .. "\t" .. requestId

    if scope then
        payload = payload .. "\t" .. scope
    end

    payload = payload .. "\t" .. query

    SendAddonMessage(
        addonName,
        payload,
        "WHISPER",
        UnitName("player"))
end

local autocompleteDelay = 0.40
local clientSearchMinimumInterval = 0.30
local queuedSearchElapsed = 0
local queuedSearchDelay = 0
local queuedSearchEditBox = nil
local queuedSearchScope = nil
local queuedSearchAutoOpen = false
local queuedSearchFrame = CreateFrame("Frame")
queuedSearchFrame:Hide()

local function CancelQueuedSearch()
    queuedSearchElapsed = 0
    queuedSearchDelay = 0
    queuedSearchEditBox = nil
    queuedSearchScope = nil
    queuedSearchAutoOpen = false
    queuedSearchFrame:Hide()
end

ClearCuratedSearchStateAfterRawTeleport = function()
    CancelQueuedSearch()
    CloseDropDownMenus(1)

    searchBox:SetText("")
    searchBox:ClearFocus()
    categorySearchBox:SetText("")
    categorySearchBox:ClearFocus()

    pendingSearchRequestId = nil
    pendingSearchAutoOpen = false
    lastSearchQuery = nil
    lastSearchScope = nil

    protocolState.results = {}
    protocolState.arrivalChoices = {}
    protocolState.destinationStatus = {}
    protocolState.settlementFactionStatus = {}
    protocolState.destinationFactionStatus = {}
    protocolState.levelRestrictionStatus = {}
    protocolState.rivalCapitalFactionStatus = {}
    protocolState.done = nil

    ClearSelectedDestination("Raw coordinate teleport complete.")
    UIDropDownMenu_SetText(resultsDropDown, "No search yet")
end

local function QueueSearch(editBox, scope, autoOpen, delay)
    CancelQueuedSearch()

    queuedSearchEditBox = editBox
    queuedSearchScope = scope
    queuedSearchAutoOpen = autoOpen and true or false
    queuedSearchDelay = delay or 0
    queuedSearchElapsed = 0

    queuedSearchFrame:Show()
end

queuedSearchFrame:SetScript("OnUpdate", function(self, elapsed)
    queuedSearchElapsed = queuedSearchElapsed + elapsed

    if queuedSearchElapsed < queuedSearchDelay then
        return
    end

    local editBox = queuedSearchEditBox
    local scope = queuedSearchScope
    local autoOpen = queuedSearchAutoOpen

    CancelQueuedSearch()

    if editBox then
        SendSearch(editBox, scope, autoOpen)
    end
end)

local function ScheduleAutocomplete(editBox, scope, userInput)
    if not userInput then
        return
    end

    CancelQueuedSearch()

    -- Text changed after a request was sent. Invalidate that request
    -- immediately so late RESULT/STATUS/DONE packets cannot repopulate
    -- suggestions for text the player has already changed.
    pendingSearchRequestId = nil
    pendingSearchAutoOpen = false

    protocolState.results = {}
    protocolState.arrivalChoices = {}
    protocolState.destinationStatus = {}
    protocolState.settlementFactionStatus = {}
    protocolState.destinationFactionStatus = {}
    protocolState.levelRestrictionStatus = {}
    protocolState.rivalCapitalFactionStatus = {}
    protocolState.done = nil
    protocolState.error = nil

    CloseDropDownMenus(1)

    local query = editBox:GetText() or ""
    query = string.gsub(query, "^%s+", "")
    query = string.gsub(query, "%s+$", "")

    if query == "" then
        ClearSelectedDestination("Enter a destination.")
        UIDropDownMenu_SetText(resultsDropDown, "No search yet")
        return
    end

    if string.len(query) > 96 or string.find(query, "[%c]") then
        ClearSelectedDestination("Destination search is invalid.")
        UIDropDownMenu_SetText(resultsDropDown, "Search unavailable")
        return
    end

    ClearSelectedDestination("Searching as you type: " .. query)
    UIDropDownMenu_SetText(resultsDropDown, "Type-ahead pending...")

    QueueSearch(editBox, scope, true, autocompleteDelay)
end

local function SendSearchFromEnter(editBox, scope)
    CancelQueuedSearch()

    local query = editBox:GetText() or ""
    query = string.gsub(query, "^%s+", "")
    query = string.gsub(query, "%s+$", "")

    -- If autocomplete already sent this exact authoritative search,
    -- Enter reuses it instead of generating an identical second request.
    -- It also converts the pending request to normal Enter behavior so
    -- DONE does not automatically open the suggestions dropdown.
    if pendingSearchRequestId
        and lastSearchQuery == query
        and lastSearchScope == scope then
        pendingSearchAutoOpen = false
        return
    end

    local delay =
        clientSearchMinimumInterval - (GetTime() - lastSearchSentAt)

    if delay > 0 then
        QueueSearch(editBox, scope, false, delay)
    else
        SendSearch(editBox, scope, false)
    end
end

frame:SetScript("OnHide", function()
    CancelQueuedSearch()

    -- A closed window must not retain ownership of a search response
    -- that may arrive after the player has dismissed the interface.
    pendingSearchRequestId = nil
    pendingSearchAutoOpen = false

    optionsFrame:Hide()
end)

local function SendSelectedDestination()
    if not selectedDestination or pendingTeleportRequestId then
        return
    end

    local choices =
        protocolState.arrivalChoices[selectedDestination.gameTeleId]
    local useChoice = choices and #choices > 0

    if useChoice and not selectedArrivalChoice then
        sendButton:Disable()
        return
    end

    local requestId = AllocateRequestId()
    local command = "TELEPORT"

    if useChoice then
        command = "TELEPORT_CHOICE"
    end

    if IsOverrideEnabled() then
        if useChoice then
            command = "TELEPORT_CHOICE_TEST"
        else
            command = "TELEPORT_TEST"
        end
    end

    pendingTeleportRequestId = requestId
    pendingTeleportGameTeleId = selectedDestination.gameTeleId
    pendingTeleportChoiceId = nil

    if useChoice then
        pendingTeleportChoiceId = selectedArrivalChoice.choiceId
    end

    protocolState.teleported = nil
    protocolState.choiceTeleported = nil
    protocolState.error = nil

    sendButton:Disable()

    local payload =
        command ..
        "\t" .. requestId ..
        "\t" .. selectedDestination.gameTeleId

    if useChoice then
        payload =
            payload ..
            "\t" .. selectedArrivalChoice.choiceId
    end

    SendAddonMessage(
        addonName,
        payload,
        "WHISPER",
        UnitName("player"))
end

local function ActivateCategoryTab(button)
    CancelQueuedSearch()
    CloseDropDownMenus(1)

    activeSearchScope = button.searchScope
    categorySearchLabel:SetText("Search " .. button.searchLabel)
    categorySearchBox:SetText("")
    categorySearchBox:ClearFocus()

    pendingSearchRequestId = nil
    pendingSearchAutoOpen = false
    protocolState.results = {}
    protocolState.arrivalChoices = {}
    protocolState.destinationStatus = {}
    protocolState.settlementFactionStatus = {}
    protocolState.destinationFactionStatus = {}
    protocolState.levelRestrictionStatus = {}
    protocolState.rivalCapitalFactionStatus = {}
    protocolState.done = nil
    protocolState.error = nil

    ClearSelectedDestination(
        "Search " .. button.searchLabel .. " destinations.")
    UIDropDownMenu_SetText(resultsDropDown, "No search yet")

    for index = 1, #categoryTabs do
        SetCategoryTabAppearance(
            categoryTabs[index],
            categoryTabs[index] == button)
    end
end

for index = 1, #categoryTabs do
    local button = categoryTabs[index]
    button:SetScript("OnClick", function(self)
        ActivateCategoryTab(self)
    end)
end

ActivateCategoryTab(categoryTabs[1])

searchBox:SetMaxLetters(96)
searchBox:SetScript("OnTextChanged", function(self, userInput)
    ScheduleAutocomplete(self, nil, userInput)
end)
searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    SendSearchFromEnter(self, nil)
end)

categorySearchBox:SetMaxLetters(96)
categorySearchBox:SetScript("OnTextChanged", function(self, userInput)
    ScheduleAutocomplete(self, activeSearchScope, userInput)
end)
categorySearchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    SendSearchFromEnter(self, activeSearchScope)
end)

sendButton:SetScript("OnClick", function()
    SendSelectedDestination()
end)

local function SendRawCoordinates()
    if not IsOverrideEnabled() or pendingRawRequestId then
        return
    end

    local mapId = ParseRawMapId()
    local x = ParseRawCoordinate(rawXBox)
    local y = ParseRawCoordinate(rawYBox)
    local z = ParseRawCoordinate(rawZBox)

    if not mapId or not x or not y or not z then
        UpdateRawButtonState()
        return
    end

    local requestId = AllocateRequestId()

    pendingRawRequestId = requestId
    pendingRawMapId = mapId
    protocolState.coordTeleported = nil
    protocolState.error = nil

    rawButton:Disable()

    SendAddonMessage(
        addonName,
        "TELEPORT_COORD_TEST" ..
            "\t" .. requestId ..
            "\t" .. mapId ..
            "\t" .. string.format("%.9g", x) ..
            "\t" .. string.format("%.9g", y) ..
            "\t" .. string.format("%.9g", z),
        "WHISPER",
        UnitName("player"))
end

rawButton:SetScript("OnClick", function()
    SendRawCoordinates()
end)

local function IsRelevantGroupInCombat()
    if UnitAffectingCombat("player") then
        return true
    end

    local raidMembers = GetNumRaidMembers()

    if raidMembers and raidMembers > 0 then
        for index = 1, raidMembers do
            if UnitAffectingCombat("raid" .. index) then
                return true
            end
        end

        return false
    end

    local partyMembers = GetNumPartyMembers()

    if partyMembers and partyMembers > 0 then
        for index = 1, partyMembers do
            if UnitAffectingCombat("party" .. index) then
                return true
            end
        end
    end

    return false
end

local function HandleCombatStart()
    combatHideActive = false
    restoreMainAfterCombat = false
    restoreOptionsAfterCombat = false

    if not IsHideInCombatEnabled() then
        return
    end

    combatHideActive = true

    -- Snapshot both windows before frame:Hide(), because the main frame's
    -- OnHide handler also hides the Options window.
    restoreMainAfterCombat = frame:IsShown()
    restoreOptionsAfterCombat = optionsFrame:IsShown()

    if restoreMainAfterCombat then
        frame:Hide()
    elseif restoreOptionsAfterCombat then
        optionsFrame:Hide()
    end
end

local function HandleCombatEnd()
    local restoreMain = restoreMainAfterCombat
    local restoreOptions = restoreOptionsAfterCombat

    combatHideActive = false
    restoreMainAfterCombat = false
    restoreOptionsAfterCombat = false

    if not IsRestoreAfterCombatEnabled() then
        return
    end

    if restoreMain then
        frame:Show()
    end

    if restoreOptions then
        optionsFrame:Show()
    end
end

local function EvaluateGroupCombatState()
    local groupInCombat = IsRelevantGroupInCombat()

    if groupInCombat then
        if not combatHideActive then
            HandleCombatStart()
        end
    elseif combatHideActive then
        HandleCombatEnd()
    end
end

frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_FLAGS")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_REGEN_ENABLED"
        or event == "UNIT_FLAGS"
        or event == "PARTY_MEMBERS_CHANGED"
        or event == "RAID_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD" then
        EvaluateGroupCombatState()
        return
    end

    if event ~= "CHAT_MSG_ADDON" then
        return
    end

    if prefix ~= addonName or sender ~= UnitName("player") then
        return
    end

    ParseServerMessage(message)
end)

SLASH_GETUSTHERE1 = "/gut"
SlashCmdList["GETUSTHERE"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        if combatHideActive and IsHideInCombatEnabled() then
            return
        end

        frame:Show()
    end
end
