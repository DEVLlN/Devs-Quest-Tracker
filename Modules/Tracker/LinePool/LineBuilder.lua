-- Builds the header, title and objective lines of the tracker sections.
-- A section decides what to show, the builder decides how a line is sized and placed.
---@class LineBuilder
local LineBuilder = QuestieLoader:CreateModule("LineBuilder")

---@type TrackerLayout
local TrackerLayout = QuestieLoader:ImportModule("TrackerLayout")
---@type TrackerLinePool
local TrackerLinePool = QuestieLoader:ImportModule("TrackerLinePool")
---@type TrackerUtils
local TrackerUtils = QuestieLoader:ImportModule("TrackerUtils")

---@class HeaderLineOptions
---@field key string The collapsedZones key, e.g. "Elwynn Forest", "Achievements" or "Recipes"
---@field text string The shown text, e.g. "Achievements: 3/10"
---@field collapsedText string? Defaults to text .. " +"
---@field questZone boolean? Whether this is a quest group eligible for zone auto-expansion

--- Zero out the minAllQuestsInZone table of a zone, when it holds no more quest ids.
---@param key string
---@param collapsed boolean
local function _CleanUpMinAllQuestsInZone(key, collapsed)
    local minAllQuests = Questie.db.char.minAllQuestsInZone[key]
    if minAllQuests == nil or minAllQuests.isTrue or collapsed then
        return
    end

    for minQuestId, _ in pairs(minAllQuests) do
        if type(minQuestId) == "number" then
            return
        end
    end

    Questie.db.char.minAllQuestsInZone[key] = nil
end

---@alias LineClickMode "quest"|"achieve"|"recipe"

---@param line TrackerLineFrame
---@param clickMode LineClickMode
---@param target table The quest, achievement or recipe stored on the line
---@param objective table?
local function _SetTarget(line, clickMode, target, objective)
    line:SetOnClick(clickMode)
    if clickMode == "recipe" then
        line:SetRecipe(target)
    else
        line:SetQuest(target)
        line:SetObjective(objective)
    end
end

---@param options HeaderLineOptions
---@return TrackerLineFrame|nil line, boolean collapsed
function LineBuilder.AddHeader(options)
    local line = TrackerLinePool.GetNextLine()
    if (not line) then
        return nil, false
    end

    local margins = TrackerLayout.GetMargins()
    local collapsed
    if options.questZone then
        collapsed = TrackerUtils.IsQuestZoneCollapsed(options.key)
    else
        collapsed = Questie.db.char.collapsedZones[options.key] == true
    end
    line.expandZone.isQuestZone = options.questZone

    line:SetMode("zone")
    line:SetZone(options.key)
    line.expandQuest:Hide()
    line.criteriaMark:Hide()
    line.playButton:Hide()

    line.label:ClearAllPoints()
    line.label:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)

    if collapsed then
        line.expandZone:SetMode(0)
        line.label:SetText("|cFFC0C0C0" .. (options.collapsedText or (options.text .. " +")) .. "|r")
    else
        line.expandZone:SetMode(1)
        line.label:SetText("|cFFC0C0C0" .. options.text .. "|r")
    end

    _CleanUpMinAllQuestsInZone(options.key, collapsed)

    TrackerLayout.UpdateWidth(line.label:GetUnboundedStringWidth() + margins.left + margins.right)
    line.label:SetWidth(TrackerLayout.GetBaseFrameWidth() - margins.left - margins.right)
    line:SetWidth(line.label:GetWidth())
    TrackerLayout.TrackLineWidth(line.label:GetUnboundedStringWidth() + margins.left)

    line.expandZone:ClearAllPoints()
    line.expandZone:SetPoint("TOPLEFT", line.label, "TOPLEFT", 0, 0)
    -- The label can be wider than its text while the tracker is laid out, so the click area follows the text
    line.expandZone:SetWidth(line.label:GetUnboundedStringWidth())
    line.expandZone:SetHeight(line.label:GetHeight())
    line.expandZone:Show()

    -- Adds 4 pixels between the header and the first title
    line:SetHeight(line.label:GetHeight() + 4)
    line:Show()
    line.label:Show()
    line.Quest = nil
    line.Objective = nil
    line.Recipe = nil

    return line, collapsed
end

---@class TitleLineOptions
---@field text string The shown text, it is colored yellow unless colored is set
---@field colored boolean? The text already carries its color
---@field clickMode LineClickMode
---@field target table The quest, achievement or recipe stored on the line
---@field collapseId number? Shows the expand button and uses collapsedQuests[collapseId]
---@field zoneKey string? The collapsedZones key of the header above, for the minAllQuestsInZone bookkeeping

---@param options TitleLineOptions
---@return TrackerLineFrame|nil line, boolean collapsed
function LineBuilder.AddTitle(options)
    local line = TrackerLinePool.GetNextLine()
    if (not line) then
        return nil, false
    end

    local margins = TrackerLayout.GetMargins()
    local collapseId = options.collapseId
    local collapsed = collapseId ~= nil and Questie.db.char.collapsedQuests[collapseId] and true or false

    -- Achievement titles must not be mistaken for quest titles by TrackerLinePool.ForEachQuestTitleLine
    line:SetMode(options.clickMode == "achieve" and "achieve" or "quest")
    _SetTarget(line, options.clickMode, options.target)
    line.expandZone:Hide()
    line.criteriaMark:Hide()
    -- Quest titles show the play button. VoiceOver's SetPlayButton skips an unchanged quest, so it must not be hidden here.
    if options.clickMode ~= "quest" then
        line.playButton:Hide()
    end

    line.titleMarginLeft = margins.quest
    line.label:ClearAllPoints()
    line.label:SetPoint("TOPLEFT", line, "TOPLEFT", line.titleMarginLeft, 0)

    line.questFocus:SetSize(margins.focusButtonSize, margins.focusButtonSize)
    line.questFocus:ClearAllPoints()
    line.questFocus:SetPoint("TOPRIGHT", line, "TOPLEFT", margins.focusButtonRight, 1 + (margins.focusButtonSize - margins.buttonSize) / 2)

    -- Vertically centered on the other buttons, since it is bigger
    line.playButton:SetSize(margins.playButtonSize, margins.playButtonSize)
    line.playButton:ClearAllPoints()
    line.playButton:SetPoint("CENTER", line, "TOPLEFT", margins.playButtonRight - margins.playButtonSize / 2, 1 - margins.buttonSize / 2)

    if collapseId == nil then
        line.expandQuest:Hide()
    else
        line.expandQuest:Show()
        line.expandQuest:ClearAllPoints()
        line.expandQuest:SetPoint("TOPRIGHT", line, "TOPLEFT", margins.expandQuestRight, 1)
        line.expandQuest.zoneId = options.zoneKey

        -- The minAllQuestsInZone table is always blank until a player Shift+Clicks the zone header (MouseDown).
        -- QuestieTracker:Update is triggered and the table is then filled with all ids in the same zone.
        local minAllQuests = options.zoneKey and Questie.db.char.minAllQuestsInZone[options.zoneKey]
        if minAllQuests and minAllQuests.isTrue then
            minAllQuests[collapseId] = true
        end

        line.expandQuest:SetMode(collapsed and 0 or 1)
    end

    if options.colored then
        line.label:SetText(options.text)
    else
        line.label:SetText("|cFFFFFF00" .. options.text .. "|r")
    end

    TrackerLayout.UpdateWidth(line.label:GetUnboundedStringWidth() + margins.quest + margins.right)
    line.label:SetWidth(math.max(1, TrackerLayout.GetBaseFrameWidth() - margins.quest - margins.right))
    line:SetWidth(line.label:GetWidth() + margins.quest)
    TrackerLayout.TrackLineWidth(line.label:GetUnboundedStringWidth() + margins.quest)

    -- Adds 4 pixels between the title and the first objective
    line:SetHeight(line.label:GetHeight() + 4)
    line:Show()
    line.label:Show()

    return line, collapsed
end

---@class ObjectiveLineOptions
---@field text string
---@field clickMode LineClickMode
---@field target table The quest, achievement or recipe stored on the line
---@field objective table? The quest objective, for combat text updates
---@field marginLeft number? Defaults to TrackerLayout.GetMargins().objective
---@field rightInset number? Room for quest item buttons on the right

---@param options ObjectiveLineOptions
---@return TrackerLineFrame|nil
function LineBuilder.AddObjective(options)
    local line = TrackerLinePool.GetNextLine()
    if (not line) then
        return nil
    end

    local marginLeft = options.marginLeft or TrackerLayout.GetMargins().objective

    line:SetMode("objective")
    line.questItemInset = options.rightInset or 0
    _SetTarget(line, options.clickMode, options.target, options.objective)
    line.expandZone:Hide()
    line.expandQuest:Hide()
    line.criteriaMark:Hide()
    line.playButton:Hide()

    line.label:ClearAllPoints()
    line.label:SetPoint("TOPLEFT", line, "TOPLEFT", marginLeft, 0)

    line.label:SetText(options.text)
    TrackerLayout.UpdateLineWidth(line, marginLeft)

    -- Adds 1 pixel between multiple objectives
    line:SetHeight(line.label:GetHeight() + 1)
    line:Show()
    line.label:Show()

    return line
end

---@class TimerLineOptions
---@field text string
---@field target table The quest stored on the line
---@field activeTimer boolean The text is updated every second without a new layout
---@field marginLeft number? Defaults to TrackerLayout.GetMargins().objective
---@field rightInset number? Room for quest item buttons on the right

---@param options TimerLineOptions
---@return TrackerLineFrame|nil
function LineBuilder.AddTimer(options)
    local line = TrackerLinePool.GetNextLine()
    if (not line) then
        return nil
    end

    local margins = TrackerLayout.GetMargins()
    local marginLeft = options.marginLeft or margins.objective

    line:SetMode("objective")
    line.questItemInset = options.rightInset or 0
    _SetTarget(line, "quest", options.target)
    line.expandZone:Hide()
    line.expandQuest:Hide()
    line.criteriaMark:Hide()
    line.playButton:Hide()

    line.label:ClearAllPoints()
    line.label:SetPoint("TOPLEFT", line, "TOPLEFT", marginLeft, 0)

    line.label.activeTimer = options.activeTimer
    line.label:SetText(options.text)

    local rightMargin = margins.right + line.questItemInset
    TrackerLayout.UpdateWidth(line.label:GetUnboundedStringWidth() + marginLeft + rightMargin)
    -- Timers start with "15 Minutes" and become "14 Minutes 59 Seconds" right after, without a new layout
    line.label:SetWidth(math.max(1, TrackerLayout.GetBaseFrameWidth() - marginLeft - rightMargin + 40))
    line:SetWidth(line.label:GetWidth() + marginLeft)
    TrackerLayout.TrackLineWidth(line.label:GetUnboundedStringWidth() + marginLeft + line.questItemInset)

    -- Adds 1 pixel between the timer and the first objective
    line:SetHeight(line.label:GetHeight() + 1)
    line:Show()
    line.label:Show()

    return line
end

--- Adds the "Padding Between Quests" setting of the tracker options below the last line of an entry.
---@param line TrackerLineFrame|nil The last line of the entry, nil when the line pool was exhausted
---@param endsQuestEntry boolean? Whether this is the last line of a quest entry
function LineBuilder.FinishEntry(line, endsQuestEntry)
    line = line or TrackerLinePool.GetLastLine()
    line.endsQuestEntry = endsQuestEntry

    -- Adds 2 pixels and the "Padding Between Quests" setting
    line:SetHeight(line.label:GetHeight() + (Questie.db.profile.trackerQuestPadding + 2))
end
