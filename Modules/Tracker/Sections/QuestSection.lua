---@class QuestSection
local QuestSection = QuestieLoader:CreateModule("QuestSection")

---@type TrackerLayout
local TrackerLayout = QuestieLoader:ImportModule("TrackerLayout")
---@type LineBuilder
local LineBuilder = QuestieLoader:ImportModule("LineBuilder")
---@type TrackerData
local TrackerData = QuestieLoader:ImportModule("TrackerData")
---@type TrackerUtils
local TrackerUtils = QuestieLoader:ImportModule("TrackerUtils")
---@type TrackerQuestTimers
local TrackerQuestTimers = QuestieLoader:ImportModule("TrackerQuestTimers")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

local PINNED_GROUP_KEY = "Questie:PinnedQuests"

local DUNGEON_CATEGORY = 2
-- Forever's Group Finder can omit these activities from its current listing.
local UNLISTED_DUNGEON_ACTIVITIES = {802, 1607, 1693}
-- Quest log headers can use the parent instance name instead of a Group Finder wing name,
-- or use the area name where Group Finder uses a shorter name.
local DUNGEON_HEADER_AREAS = {717, 796, 1477, 1581, 1583, 2017, 2557, 16919}
local dungeonHeaders

local function _GetDungeonHeaders()
    if dungeonHeaders then
        return dungeonHeaders
    end

    local groupFinder = _G.C_LFGList
    local headers = {}
    for _, areaId in ipairs(DUNGEON_HEADER_AREAS) do
        local name = C_Map.GetAreaInfo(areaId)
        if name then
            headers[name] = true
        end
    end

    local function _AddActivity(activityId)
        local info = groupFinder.GetActivityInfoTable(activityId)
        if info then
            if info.fullName and info.fullName ~= "" then
                headers[info.fullName] = true
            end
            if info.shortName and info.shortName ~= "" then
                headers[info.shortName] = true
            end
        end
    end

    local activities = groupFinder.GetAvailableActivities(DUNGEON_CATEGORY)
    for _, activityId in ipairs(activities or {}) do
        _AddActivity(activityId)
    end
    for _, activityId in ipairs(UNLISTED_DUNGEON_ACTIVITIES) do
        _AddActivity(activityId)
    end
    if activities and #activities > 0 then
        dungeonHeaders = headers
    end
    return headers
end

---@param questId QuestId
---@param quest TrackerQuest
---@param complete number
---@return boolean
local function _IsQuestShown(questId, quest, complete)
    local timedQuest = quest.trackTimedQuest
    return ((complete ~= 1 and (not quest.isComplete)) or Questie.db.profile.trackerShowCompleteQuests or timedQuest)
        and ((Questie.db.profile.autoTrackQuests and (not Questie.db.char.AutoUntrackedQuests[questId]))
        or (not Questie.db.profile.autoTrackQuests and Questie.db.char.TrackedQuests[questId])) and true or false
end

---@param sortedQuestIds QuestId[]
---@param questDetails table<QuestId, {quest: TrackerQuest, zoneName: string}>
---@param pinned boolean? Whether to draw quests in the separate pinned group
function QuestSection.Draw(sortedQuestIds, questDetails, pinned)
    local margins = TrackerLayout.GetMargins()
    local profile = Questie.db.profile
    local objectiveColor = profile.trackerColorObjectives
    local markedHeaders = Questie.IsForever and profile.trackerShowDungeonMarker and not pinned
        and TrackerUtils.UsesQuestZoneGrouping() and _GetDungeonHeaders()

    local line
    local currentGroup
    local groupCollapsed = false

    for _, questId in ipairs(sortedQuestIds) do
        if (not questId) then
            break
        end

        ---@type TrackerQuest
        local quest = questDetails[questId].quest
        local complete = quest:IsComplete()
        local groupKey = pinned and PINNED_GROUP_KEY or questDetails[questId].zoneName

        TrackerQuestTimers:UpdateAndGetRemainingTime(quest, nil, true)
        local timedQuest = quest.trackTimedQuest

        if _IsQuestShown(questId, quest, complete) then
            if currentGroup ~= groupKey then
                local title = pinned and l10n("Pinned Quests") or groupKey
                if markedHeaders and markedHeaders[groupKey] then
                    title = profile.trackerDungeonMarkerPosition == "after" and (title .. " [D]") or ("[D] " .. title)
                end
                line, groupCollapsed = LineBuilder.AddHeader({key = groupKey, text = title, questZone = not pinned})
                if not line then
                    break
                end
                currentGroup = groupKey
            end

            if not groupCollapsed then
                -- Set Completion Text
                local completionText = TrackerUtils:GetCompletionText(quest)

                -- Clear Blizzard Completion Text
                if (Questie.db.profile.hideBlizzardCompletionText or objectiveColor == "minimal") and (not timedQuest or complete ~= 0) or complete == -1 then
                    completionText = nil
                end

                -- This removes any blank lines from Completion Text
                if completionText ~= nil then
                    if strfind(completionText, "\r\n") then
                        completionText = completionText:gsub("\r\n", "")
                    else
                        completionText = completionText:gsub("(.\r?\n?)\r?\n?", "%1")
                    end

                    -- Completion Text should always be green
                    completionText = "|cFF28FF28" .. completionText
                end

                -- Set minimizable quest flag
                local isMinimizable = (complete == 1 or complete == -1) or (#quest.Objectives == 0 and quest.isComplete == true)

                -- Handles the collapseCompletedQuests option from the Questie Config --> Tracker options.
                if Questie.db.profile.collapseCompletedQuests and isMinimizable and (not timedQuest) then
                    if (not Questie.db.char.collapsedQuests[quest.Id]) then
                        Questie.db.char.collapsedQuests[quest.Id] = true
                    end
                end

                -- Set Quest Title - This handles the "Auto Minimize Completed Quests" option but we don't auto-minimize timed quests.
                local coloredQuestName

                if timedQuest then
                    local showTimedState = isMinimizable and (Questie.db.profile.collapseCompletedQuests or Questie.db.char.collapsedQuests[quest.Id] ~= nil)
                    coloredQuestName = TrackerData.GetColoredQuestName(quest, Questie.db.profile.trackerShowQuestLevel, showTimedState)
                else
                    coloredQuestName = TrackerData.GetColoredQuestName(quest, Questie.db.profile.trackerShowQuestLevel,
                        ((isMinimizable and Questie.db.profile.collapseCompletedQuests) or Questie.db.char.collapsedQuests[quest.Id] ~= nil))
                end

                line = LineBuilder.AddTitle({
                    text = coloredQuestName,
                    colored = true,
                    clickMode = "quest",
                    target = quest,
                    collapseId = quest.Id,
                    zoneKey = groupKey,
                })
                if (not line) then
                    break
                end

                line.questFocus:SetQuest(quest, complete == 1 or (complete ~= -1 and quest.isComplete == true))

                -- Adds the AI_VoiceOver Play Buttons
                line.playButton:SetPlayButton(questId)

                local isCompletionText = ((complete == 1 and completionText ~= nil and #quest.Objectives == 0)
                    or (quest.isComplete == true and completionText ~= nil)) and objectiveColor ~= "minimal"
                local shouldContinue, rightInset = TrackerUtils.AddQuestItemButtons(quest, complete, line, isMinimizable, not isCompletionText)
                line.questItemInset = rightInset
                TrackerLayout.TrackLineWidth(line.label:GetUnboundedStringWidth() + margins.quest + rightInset)

                if not shouldContinue then
                    break -- We exceeded the button pool
                end

                -- Add Quest Timers (if applicable) - always shown for timed quests, even when collapsed
                if timedQuest then
                    local timerText = nil
                    local activeTimer = false

                    local timeRemainingString, timeRemaining = TrackerQuestTimers:GetRemainingTimeByQuestId(quest.Id)
                    if timeRemaining then
                        if timeRemaining <= 0 then
                            timerText = Questie:Colorize(l10n("Time's up!"), "lightBlue")
                        else
                            timerText = Questie:Colorize(timeRemainingString, "lightBlue")
                            activeTimer = true
                        end
                    end

                    if timerText then
                        line = LineBuilder.AddTimer({
                            text = timerText,
                            target = quest,
                            activeTimer = activeTimer,
                            rightInset = rightInset,
                        })
                        if (not line) then
                            break
                        end

                        if activeTimer then
                            TrackerQuestTimers:UpdateAndGetRemainingTime(quest, line, false)
                        end
                    end
                end

                -- Add quest Objectives (if applicable)
                if (not Questie.db.char.collapsedQuests[quest.Id]) then
                    -- Add incomplete Quest Objectives
                    if complete == 0 and quest.isComplete ~= true then
                        for _, objective in ipairs(quest.Objectives) do
                            if (not Questie.db.profile.hideCompletedQuestObjectives) or (not objective.Completed) then
                                line = LineBuilder.AddObjective({
                                    text = TrackerData.GetObjectiveText(objective),
                                    clickMode = "quest",
                                    target = quest,
                                    objective = objective,
                                    rightInset = rightInset,
                                })
                                if (not line) then
                                    break
                                end
                            end
                        end

                        -- Add complete/failed Quest Objectives and tag them as either complete or failed so as to always have at least one objective.
                        -- Some quests have "Blizzard Completion Text" that is displayed to show where to go next or where to turn in the quest.
                    elseif (complete == 1 or complete == -1 or quest.isComplete == true) and (not (timedQuest and isMinimizable and Questie.db.profile.collapseCompletedQuests)) then
                        local objectiveText
                        if isCompletionText then
                            -- Blizzard Completion text for single objectives
                            objectiveText = completionText
                        elseif complete == 1 or (#quest.Objectives == 0 and quest.isComplete == true and completionText == nil and complete ~= -1) then
                            objectiveText = Questie:Colorize(l10n("Quest Complete!"), "28FF28")
                        elseif complete == -1 then
                            objectiveText = Questie:Colorize(l10n("Quest Failed!"), "red")
                        end

                        line = LineBuilder.AddObjective({
                            text = objectiveText or "",
                            clickMode = "quest",
                            target = quest,
                            rightInset = rightInset,
                        })
                        if (not line) then
                            break
                        end
                    end
                end

                LineBuilder.FinishEntry(line, true)
            end
        end
    end
end
