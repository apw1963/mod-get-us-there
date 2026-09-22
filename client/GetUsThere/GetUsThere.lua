local addonName = "GetUsThere"

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

local function CreateCategoryTab(text, scope, x, width)
    local button =
        CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", x, -136)
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

local override = CreateFrame("CheckButton", "GetUsThereOverrideCheck", frame, "UICheckButtonTemplate")
override:SetPoint("TOPLEFT", 20, -416)

local overrideText = override:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
overrideText:SetPoint("LEFT", override, "RIGHT", 4, 0)
overrideText:SetText("Screw you! I'll go where I want, whenever I want.")

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

        if override:GetChecked() then
            command = "SEARCH_SCOPE_TEST"
        end
    elseif override:GetChecked() then
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

    if override:GetChecked() then
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
        if categoryTabs[index] == button then
            categoryTabs[index]:Disable()
        else
            categoryTabs[index]:Enable()
        end
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
