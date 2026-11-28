---@type QuestieCompat
local QuestieCompat = QuestieLoader:ImportModule("QuestieCompat")

---@class TrackerHeaderFrame
local TrackerHeaderFrame = QuestieLoader:CreateModule("TrackerHeaderFrame")
-------------------------
--Import QuestieTracker modules.
-------------------------
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
---@type TrackerUtils
local TrackerUtils = QuestieLoader:ImportModule("TrackerUtils")
-------------------------
--Import Questie modules.
-------------------------
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")
---@type QuestieJourney
local QuestieJourney = QuestieLoader:ImportModule("QuestieJourney")
---@type QuestLogCache
local QuestLogCache = QuestieLoader:ImportModule("QuestLogCache")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieLoader:ImportModule("QuestieOptionsEngine")

local LSM30 = LibStub("LibSharedMedia-3.0")

local headerFrame, trackerBaseFrame

local CLASSIC_HEADER_ATLAS = "ui-questtracker-primary-objective-header"
-- The primary atlas has a transparent gutter after its right-hand trim.
local CLASSIC_ART_WIDTH_SCALE = 1.045
local HEADER_ICON_OFFSET = 6
local HEADER_LABEL_GAP = 2
local CLASSIC_REFERENCE_FONT_SIZE = 13
local CLASSIC_HEADER_HEIGHT = 26
local CLASSIC_TITLE_INSET = 8
local CLASSIC_TOGGLE_WIDTH = 13
local CLASSIC_TOGGLE_HEIGHT = 14
local CLASSIC_TOGGLE_INSET = 6
local CLASSIC_TOGGLE_LABEL_GAP = 5
local CLASSIC_TOGGLE_SPACE = CLASSIC_TOGGLE_WIDTH + CLASSIC_TOGGLE_INSET + CLASSIC_TOGGLE_LABEL_GAP

local function _HasAtlas(atlas)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
end

local function _UpdateClassicHeaderWidth()
    if not headerFrame.classicTheme then
        return
    end

    local trackedQuests = headerFrame.trackedQuests
    local width = math.max(1, trackerBaseFrame:GetWidth())
    local clickWidth = math.max(1, width - headerFrame.classicTitleInset)
    headerFrame.classicArt:SetWidth(width * headerFrame.classicArtWidthScale)
    trackedQuests:SetWidth(clickWidth)
    trackedQuests.label:SetWidth(math.max(1, clickWidth - headerFrame.classicToggleSpace))
end

local function _IsHeaderHovered(frame)
    return frame:IsMouseOver() or frame.trackedQuests:IsMouseOver() or frame.questieIcon:IsMouseOver()
end

local function _FadeHeaderOptionsButton(frame, elapsed)
    local icon = frame.questieIcon
    local alpha = icon:GetAlpha()
    local step = elapsed / 0.16
    local nextAlpha
    if _IsHeaderHovered(frame) then
        nextAlpha = math.min(1, alpha + step)
    else
        nextAlpha = math.max(0, alpha - step)
    end
    if nextAlpha ~= alpha then
        icon:SetAlpha(nextAlpha)
    end
end

function TrackerHeaderFrame.Initialize(baseFrame, OnTrackedQuestClick)
    trackerBaseFrame = baseFrame
    headerFrame = CreateFrame("Button", "Questie_HeaderFrame", trackerBaseFrame)

    local classicArt = headerFrame:CreateTexture(nil, "BACKGROUND")
    classicArt:SetPoint("TOPLEFT")
    headerFrame.classicArtWidthScale = 1
    if _HasAtlas(CLASSIC_HEADER_ATLAS) then
        classicArt:SetAtlas(CLASSIC_HEADER_ATLAS, false)
        headerFrame.classicArtWidthScale = CLASSIC_ART_WIDTH_SCALE
    elseif _HasAtlas("Objective-Header") then
        classicArt:SetAtlas("Objective-Header", false)
    else
        classicArt:SetColorTexture(0.15, 0.09, 0.04, 0.94)
    end
    classicArt:Hide()
    headerFrame.classicArt = classicArt

    TrackerHeaderFrame.PositionTrackerHeaderFrame()

    -- Questie Icon Settings
    local questieIcon = CreateFrame("Button", nil, trackerBaseFrame)
    questieIcon:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
    questieIcon:SetAlpha(1)

    -- Questie Icon Texture Settings
    questieIcon.texture = questieIcon:CreateTexture(nil, "BACKGROUND", nil, 0)
    questieIcon.texture:SetTexture(Questie.icons["complete"])
    questieIcon.texture:SetPoint("CENTER", 0, 0)

    questieIcon:EnableMouse(true)
    questieIcon:RegisterForDrag("LeftButton")
    questieIcon:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    questieIcon:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            if QuestieJourney:IsShown() then
                QuestieJourney:ToggleJourneyWindow()
            end
            QuestieOptionsEngine:ToggleConfigWindow()

            return
        elseif button == "RightButton" then
            if QuestieOptionsEngine:IsShown() then
                QuestieOptionsEngine:ToggleConfigWindow()
            end
            QuestieJourney:ToggleJourneyWindow()

            return
        end
    end)

    questieIcon:SetScript("OnEnter", function(self)
        if InCombatLockdown() then
            if GameTooltip:IsShown() then
                GameTooltip:Hide()
                return
            end
        end
        GameTooltip._owner = self
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:AddDoubleLine(Questie:Colorize(l10n("Quest Tracker"), "gold"), Questie:Colorize(QuestieLib:GetAddonVersionString(), "gray"))
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(Questie:Colorize(l10n("Left Click"), "lightBlue"), Questie:Colorize(l10n("Toggle Options"), "white"))
        GameTooltip:AddDoubleLine(Questie:Colorize(l10n("Right Click"), "lightBlue"), Questie:Colorize(l10n("Toggle My Journey"), "white"))
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(
            Questie:Colorize(l10n("Left Click + Hold"), "lightBlue"),
            Questie:Colorize(l10n("Drag while Unlocked"), "white")
        )
        GameTooltip:AddDoubleLine(
            Questie:Colorize(l10n("Ctrl + Left Click + Hold"), "lightBlue"),
            Questie:Colorize(l10n("Drag while Locked"), "white")
        )

        GameTooltip:Show()

        TrackerFadeTicker.Unfade(self)
    end)

    questieIcon:SetScript("OnLeave", function(self)
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end

        TrackerFadeTicker.Fade(self)
    end)

    questieIcon:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    questieIcon:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)

    questieIcon:Hide()
    headerFrame.questieIcon = questieIcon

    -- Questie Tracked Quests Settings
    local trackedQuests = CreateFrame("Button", nil, trackerBaseFrame)
    trackedQuests:SetPoint("TOPLEFT", questieIcon, "TOPLEFT", 10, 0)

    -- Questie Tracked Quests Label
    trackedQuests.label = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trackedQuests.label:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)

    local classicToggle = trackedQuests:CreateTexture(nil, "ARTWORK")
    classicToggle:Hide()
    trackedQuests.classicToggle = classicToggle

    trackedQuests.SetMode = function(self, mode)
        if mode ~= self.mode then
            self.mode = mode
        end
    end

    if Questie.db.char.isTrackerExpanded then
        trackedQuests:SetMode(1)
    else
        trackedQuests:SetMode(0)
    end

    trackedQuests:EnableMouse(true)
    trackedQuests:RegisterForDrag("LeftButton")
    trackedQuests:RegisterForClicks("RightButtonUp", "LeftButtonUp")

    trackedQuests:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            return
        end

        if self.mode == 1 then
            Questie.Debug(Questie.DEBUG_DEVELOP, "[TrackerHeaderFrame:OnClick] - Tracker Minimized")

            self:SetMode(0)
            Questie.db.char.isTrackerExpanded = false
        else
            Questie.Debug(Questie.DEBUG_DEVELOP, "[TrackerHeaderFrame:OnClick] - Tracker Maximized")

            self:SetMode(1)
            Questie.db.char.isTrackerExpanded = true
        end

        QuestieCombatQueue:Queue(function()
            OnTrackedQuestClick()
        end)
    end)

    trackedQuests:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    trackedQuests:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)
    trackedQuests:SetScript("OnEnter", TrackerFadeTicker.Unfade)
    trackedQuests:SetScript("OnLeave", TrackerFadeTicker.Fade)

    trackedQuests:Hide()

    headerFrame.trackedQuests = trackedQuests
    trackerBaseFrame:HookScript("OnSizeChanged", _UpdateClassicHeaderWidth)

    if Questie.db.profile.trackerHeaderEnabled or (not TrackerUtils.HasQuest()) then
        headerFrame:SetSize(1, Questie.db.profile.trackerFontSizeHeader) -- Width is updated later on
    else
        headerFrame:SetSize(1, 1)
    end

    headerFrame:SetFrameLevel(0)

    headerFrame:Hide()

    TrackerHeaderFrame.headerFrame = headerFrame

    return headerFrame
end

function TrackerHeaderFrame:Update()
    local trackerFontSizeHeader = Questie.db.profile.trackerFontSizeHeader
    local trackerFontSizeZone = Questie.db.profile.trackerFontSizeZone

    if Questie.db.profile.trackerHeaderEnabled or (not TrackerUtils.HasQuest()) then
        local classicTheme = Questie.db.profile.trackerClassicHeaderTheme
        local trackedQuests = headerFrame.trackedQuests
        local label = trackedQuests.label
        local expanded = Questie.db.char.isTrackerExpanded
        local scale = classicTheme and trackerFontSizeHeader / CLASSIC_REFERENCE_FONT_SIZE or 1
        local height = classicTheme and CLASSIC_HEADER_HEIGHT * scale or trackerFontSizeHeader + 5
        local showHeaderIcon = not (classicTheme and Questie.db.profile.trackerHideClassicHeaderIcon)
        local iconOffsetX = HEADER_ICON_OFFSET * scale
        local iconOffsetY = classicTheme and (trackerFontSizeHeader - height) / 2 or 0
        local classicTitleInset = showHeaderIcon and (iconOffsetX + trackerFontSizeHeader + HEADER_LABEL_GAP * scale)
            or CLASSIC_TITLE_INSET * scale
        headerFrame.classicTitleInset = classicTitleInset
        headerFrame.classicToggleSpace = CLASSIC_TOGGLE_SPACE * scale
        headerFrame.classicTheme = classicTheme
        headerFrame.classicArt:SetShown(classicTheme)
        trackedQuests.classicToggle:SetShown(classicTheme)
        if classicTheme then
            headerFrame.classicArt:SetHeight(height)
            local atlas = expanded and "ui-questtrackerbutton-collapse-all" or "ui-questtrackerbutton-expand-all"
            if _HasAtlas(atlas) then
                trackedQuests.classicToggle:SetAtlas(atlas, false)
            else
                local icon = expanded and "UI-MinusButton-Up" or "UI-PlusButton-Up"
                trackedQuests.classicToggle:SetTexture("Interface\\Buttons\\" .. icon)
            end
            trackedQuests.classicToggle:SetSize(CLASSIC_TOGGLE_WIDTH * scale, CLASSIC_TOGGLE_HEIGHT * scale)
            trackedQuests.classicToggle:SetPoint("RIGHT", -CLASSIC_TOGGLE_INSET * scale, 0)
        else
            label:SetWidth(0)
        end

        headerFrame:ClearAllPoints()
        headerFrame.questieIcon.texture:SetWidth(trackerFontSizeHeader)
        headerFrame.questieIcon.texture:SetHeight(trackerFontSizeHeader)

        headerFrame.questieIcon:ClearAllPoints()
        headerFrame.questieIcon:SetWidth(trackerFontSizeHeader)
        headerFrame.questieIcon:SetHeight(trackerFontSizeHeader)
        headerFrame.questieIcon:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", iconOffsetX, iconOffsetY)
        headerFrame.questieIcon:SetShown(showHeaderIcon)

        label:SetFont(LSM30:Fetch("font", Questie.db.profile.trackerFontHeader), trackerFontSizeHeader, Questie.db.profile.trackerFontOutline)
        if label.SetMaxLines then
            label:SetMaxLines(classicTheme and 1 or 0)
        end

        local maxQuestAmount = "/" .. C_QuestLog.GetMaxNumQuestsCanAccept()

        if expanded then
            local activeQuests = QuestLogCache.GetQuestCount()
            label:SetText(l10n("Quest Tracker") .. " " .. tostring(activeQuests) .. maxQuestAmount)
        else
            label:SetText(l10n("Quest Tracker") .. (classicTheme and "" or " +"))
        end

        label:ClearAllPoints()
        trackedQuests:ClearAllPoints()
        local headerExtraWidth = trackerFontSizeHeader
        if classicTheme then
            label:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", classicTitleInset, iconOffsetY)
            trackedQuests:SetHeight(height)
            trackedQuests:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", classicTitleInset, 0)
            headerExtraWidth = classicTitleInset + headerFrame.classicToggleSpace
        else
            label:SetPoint("TOPLEFT", headerFrame.questieIcon, "TOPRIGHT", HEADER_LABEL_GAP, 0)
            trackedQuests:SetHeight(trackerFontSizeHeader)
            trackedQuests:SetPoint("TOPLEFT", headerFrame.questieIcon, "TOPRIGHT", HEADER_LABEL_GAP, 0)
        end
        local labelWidth = label:GetUnboundedStringWidth()
        trackedQuests:SetWidth(labelWidth)
        trackedQuests:SetMode(expanded and 1 or 0)
        trackedQuests:Show()

        headerFrame:SetWidth(labelWidth + headerExtraWidth)
        headerFrame:SetHeight(height)
        _UpdateClassicHeaderWidth()
        headerFrame:Show()

        TrackerHeaderFrame.PositionTrackerHeaderFrame(headerFrame, trackerBaseFrame)

        local fadeOptionsButton = showHeaderIcon and Questie.db.profile.trackerFadeHeaderOptionsButton
        if fadeOptionsButton then
            if not headerFrame:GetScript("OnUpdate") then
                headerFrame.questieIcon:SetAlpha(_IsHeaderHovered(headerFrame) and 1 or 0)
                headerFrame:SetScript("OnUpdate", _FadeHeaderOptionsButton)
            end
        else
            headerFrame:SetScript("OnUpdate", nil)
            headerFrame.questieIcon:SetAlpha(1)
        end

        QuestieCompat.SetResizeBounds(trackerBaseFrame, headerFrame.trackedQuests.label:GetUnboundedStringWidth(), trackerFontSizeHeader)
    else
        headerFrame.classicTheme = false
        headerFrame:SetScript("OnUpdate", nil)
        headerFrame:Hide()

        headerFrame.questieIcon.texture:SetWidth(trackerFontSizeZone)
        headerFrame.questieIcon.texture:SetHeight(trackerFontSizeZone)

        headerFrame.questieIcon:ClearAllPoints()
        headerFrame.questieIcon:SetWidth(trackerFontSizeZone)
        headerFrame.questieIcon:SetHeight(trackerFontSizeZone)
        headerFrame.questieIcon:SetAlpha(0)

        if Questie.db.profile.moveHeaderToBottom then
            headerFrame.questieIcon:SetPoint("BOTTOMRIGHT", trackerBaseFrame, "BOTTOMRIGHT", -4, 8)
        else
            headerFrame.questieIcon:SetPoint("TOPRIGHT", trackerBaseFrame, "TOPRIGHT", -4, -8)
        end

        headerFrame.questieIcon:Show()

        headerFrame.trackedQuests:Hide()
    end
end

function TrackerHeaderFrame.PositionTrackerHeaderFrame()
    if Questie.db.profile.moveHeaderToBottom then
        -- Move tracker header to the bottom
        headerFrame:SetPoint("BOTTOMLEFT", trackerBaseFrame, "BOTTOMLEFT", 0, 5)
    else
        if Questie.db.char.isTrackerExpanded then
            -- Move tracker header to the top
            headerFrame:SetPoint("TOPLEFT", trackerBaseFrame, "TOPLEFT", 0, -10)
        else
            -- Tracker minimized. Move tracker header to the bottom
            headerFrame:SetPoint("BOTTOMLEFT", trackerBaseFrame, "BOTTOMLEFT", 0, 5)
        end
    end
end
