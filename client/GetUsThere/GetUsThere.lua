local addonName = "GetUsThere"

local frame = CreateFrame("Frame", "GetUsThereFrame", UIParent)
frame:SetWidth(420)
frame:SetHeight(500)
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
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Get Us There")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
searchLabel:SetPoint("TOPLEFT", 24, -58)
searchLabel:SetText("Destination")

local searchBox = CreateFrame("EditBox", "GetUsThereSearchBox", frame, "InputBoxTemplate")
searchBox:SetWidth(250)
searchBox:SetHeight(24)
searchBox:SetPoint("TOPLEFT", 24, -78)
searchBox:SetAutoFocus(false)

local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
sendButton:SetWidth(100)
sendButton:SetHeight(24)
sendButton:SetPoint("LEFT", searchBox, "RIGHT", 14, 0)
sendButton:SetText("Send Us")
sendButton:Disable()

local resultsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultsLabel:SetPoint("TOPLEFT", 24, -112)
resultsLabel:SetText("Search Results")

local resultsDropDown = CreateFrame(
    "Frame",
    "GetUsThereResultsDropDown",
    frame,
    "UIDropDownMenuTemplate")
resultsDropDown:SetPoint("TOPLEFT", 5, -124)
UIDropDownMenu_SetWidth(resultsDropDown, 320)
UIDropDownMenu_SetText(resultsDropDown, "No search yet")

local selected = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
selected:SetPoint("TOPLEFT", 24, -164)
selected:SetJustifyH("LEFT")
selected:SetText("No destination selected.")

local worldTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
worldTitle:SetPoint("TOPLEFT", 24, -194)
worldTitle:SetText("World Coordinates")

local worldCoords = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
worldCoords:SetPoint("TOPLEFT", 24, -216)
worldCoords:SetJustifyH("LEFT")
worldCoords:SetText("Map: --\nX: --\nY: --\nZ: --")

local override = CreateFrame("CheckButton", "GetUsThereOverrideCheck", frame, "UICheckButtonTemplate")
override:SetPoint("TOPLEFT", 20, -284)

local overrideText = override:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
overrideText:SetPoint("LEFT", override, "RIGHT", 4, 0)
overrideText:SetText("Screw you! I'll go wherever I want, whenever I want")

local raw = CreateFrame("Frame", nil, frame)
raw:SetWidth(370)
raw:SetHeight(140)
raw:SetPoint("TOPLEFT", 24, -329)
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
    if not override:GetChecked() or pendingRawRequestId then
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

override:SetScript("OnClick", function(self)
    if self:GetChecked() then
        raw:Show()
    else
        raw:Hide()
    end

    UpdateRawButtonState()
end)

rawMapBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawXBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawYBox:SetScript("OnTextChanged", UpdateRawButtonState)
rawZBox:SetScript("OnTextChanged", UpdateRawButtonState)


local protocolState = {
    results = {},
    done = nil,
    teleported = nil,
    coordTeleported = nil,
    error = nil
}

local nextRequestId = 1
local pendingSearchRequestId = nil
local pendingTeleportRequestId = nil
local pendingTeleportGameTeleId = nil
local selectedDestination = nil

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
    selected:SetText(message or "No destination selected.")
    worldCoords:SetText("Map: --\nX: --\nY: --\nZ: --")
    sendButton:Disable()
end

local function ShowSelectedDestination(destination)
    selectedDestination = destination
    selected:SetText(destination.displayName .. " - " .. destination.category)
    worldCoords:SetText(string.format(
        "Map: %d\nX: %.2f\nY: %.2f\nZ: %.2f",
        destination.mapId,
        destination.x,
        destination.y,
        destination.z))

    if pendingTeleportRequestId then
        sendButton:Disable()
    else
        sendButton:Enable()
    end
end

local function SelectSearchResult(destination)
    ShowSelectedDestination(destination)
    UIDropDownMenu_SetText(resultsDropDown, destination.displayName)
end

UIDropDownMenu_Initialize(resultsDropDown, function(self, level)
    for index = 1, #protocolState.results do
        local destination = protocolState.results[index]
        local info = UIDropDownMenu_CreateInfo()

        info.text = destination.displayName .. " - " .. destination.category
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
            table.insert(protocolState.results, result)
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

            pendingSearchRequestId = nil
        end
    elseif kind == "TELEPORTED" and #fields == 4 then
        protocolState.teleported = {
            requestId = tonumber(fields[2]),
            gameTeleId = tonumber(fields[3]),
            status = fields[4]
        }

        if protocolState.teleported.requestId == pendingTeleportRequestId
            and protocolState.teleported.gameTeleId == pendingTeleportGameTeleId then
            pendingTeleportRequestId = nil
            pendingTeleportGameTeleId = nil

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
            UpdateRawButtonState()
        end
    elseif kind == "ERROR" and #fields >= 2 then
        protocolState.error = {
            code = fields[2],
            requestId = tonumber(fields[3]),
            contextId = tonumber(fields[4])
        }

        if protocolState.error.requestId == pendingSearchRequestId then
            ClearSelectedDestination("Server error: " .. protocolState.error.code)
            UIDropDownMenu_SetText(resultsDropDown, "Search failed")
            pendingSearchRequestId = nil
        end

        if protocolState.error.requestId == pendingTeleportRequestId
            and protocolState.error.contextId == pendingTeleportGameTeleId then
            pendingTeleportRequestId = nil
            pendingTeleportGameTeleId = nil

            if selectedDestination then
                selected:SetText(
                    selectedDestination.displayName ..
                    " - Server error: " ..
                    protocolState.error.code)
                sendButton:Enable()
            end
        end

        if protocolState.error.requestId == pendingRawRequestId
            and protocolState.error.contextId == pendingRawMapId then
            pendingRawRequestId = nil
            pendingRawMapId = nil
            UpdateRawButtonState()
        end
    end
end

local function SendSearch()
    local query = searchBox:GetText() or ""
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

    local requestId = AllocateRequestId()
    local command = "SEARCH"

    if override:GetChecked() then
        command = "SEARCH_TEST"
    end

    protocolState.results = {}
    protocolState.done = nil
    protocolState.error = nil
    pendingSearchRequestId = requestId

    ClearSelectedDestination("Searching for: " .. query)
    UIDropDownMenu_SetText(resultsDropDown, "Searching...")

    SendAddonMessage(
        addonName,
        command .. "\t" .. requestId .. "\t" .. query,
        "WHISPER",
        UnitName("player"))
end

local function SendSelectedDestination()
    if not selectedDestination or pendingTeleportRequestId then
        return
    end

    local requestId = AllocateRequestId()
    local command = "TELEPORT"

    if override:GetChecked() then
        command = "TELEPORT_TEST"
    end

    pendingTeleportRequestId = requestId
    pendingTeleportGameTeleId = selectedDestination.gameTeleId
    protocolState.teleported = nil
    protocolState.error = nil

    sendButton:Disable()

    SendAddonMessage(
        addonName,
        command .. "\t" .. requestId .. "\t" .. selectedDestination.gameTeleId,
        "WHISPER",
        UnitName("player"))
end

searchBox:SetMaxLetters(96)
searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    SendSearch()
end)

sendButton:SetScript("OnClick", function()
    SendSelectedDestination()
end)

local function SendRawCoordinates()
    if not override:GetChecked() or pendingRawRequestId then
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

frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
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
        frame:Show()
    end
end
