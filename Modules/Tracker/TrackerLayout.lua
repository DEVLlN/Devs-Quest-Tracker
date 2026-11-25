-- Shared layout state and helpers for drawing the tracker sections.
-- Imports no other tracker module. QuestieTracker hands in its frames and resize functions on Initialize.
---@class TrackerLayout
local TrackerLayout = QuestieLoader:CreateModule("TrackerLayout")

TrackerLayout.MARGIN_LEFT = 14
TrackerLayout.MARGIN_RIGHT = 30
TrackerLayout.ITEM_BUTTON_GAP = 4
-- Quest items can use part of the right padding that the text normally leaves empty.
TrackerLayout.ITEM_BUTTON_RIGHT_EXTENSION = 12

---@class TrackerMargins
---@field left number
---@field right number
---@field quest number Left margin of quest/achievement/recipe titles
---@field objective number Left margin of objective lines
---@field buttonSize number Base size used by the expand quest button
---@field focusButtonSize number Size of the round quest focus button
---@field itemButtonSize number
---@field expandQuestRight number Right edge of the expand quest (+/-) buttons
---@field playButtonSize number The play button icon has a transparent border, so the button is bigger than the others
---@field playButtonRight number Right edge of the VoiceOver and Spoken play buttons
---@field focusButtonRight number Right edge of the quest focus buttons

-- Gap between the button slots in front of the quest titles and between the last slot and the title
local SLOT_GAP = 2

local baseFrame
local updateWidth, updateHeight
local isFocusSlotShown = function() return false end
local isPlaySlotShown = function() return false end
-- Width of the widest line drawn since the last reset
local lineWidth = 0
-- Widest tracker width requested since the last reset, nil before the first request
local requestedWidth

---@param trackerBaseFrame Frame
---@param updateWidthCallback fun(width: number) Resizes the tracker to the given content width
---@param updateHeightCallback fun() Resizes the tracker to its content height
---@param isFocusSlotShownCallback fun(): boolean Whether the quest focus buttons get a slot in front of the quest titles
---@param isPlaySlotShownCallback fun(): boolean Whether the VoiceOver and Spoken play buttons get a slot in front of the quest titles
function TrackerLayout.Initialize(trackerBaseFrame, updateWidthCallback, updateHeightCallback, isFocusSlotShownCallback, isPlaySlotShownCallback)
    baseFrame = trackerBaseFrame
    updateWidth = updateWidthCallback
    updateHeight = updateHeightCallback
    isFocusSlotShown = isFocusSlotShownCallback
    isPlaySlotShown = isPlaySlotShownCallback
end

---The left slots hold focus, playback, and expand buttons. Quest items sit on the right.
---@return TrackerMargins
function TrackerLayout.GetMargins()
    local fontSizeQuest = Questie.db.profile.trackerFontSizeQuest
    local buttonSize = fontSizeQuest + 3
    local focusButtonSize = buttonSize * Questie.db.profile.trackerQuestFocusButtonScale / 100
    local itemButtonSize = fontSizeQuest + 12
    local playButtonSize = buttonSize + 2
    local playSlot = isPlaySlotShown() and (playButtonSize + SLOT_GAP) or 0
    local focusSlot = isFocusSlotShown() and (focusButtonSize + SLOT_GAP) or 0

    local playButtonRight = focusSlot + playSlot - SLOT_GAP
    local expandQuestRight = focusSlot + playSlot + buttonSize
    local quest = expandQuestRight + SLOT_GAP
    return {
        left = TrackerLayout.MARGIN_LEFT,
        right = TrackerLayout.MARGIN_RIGHT,
        quest = quest,
        objective = quest + fontSizeQuest,
        buttonSize = buttonSize,
        focusButtonSize = focusButtonSize,
        itemButtonSize = itemButtonSize,
        expandQuestRight = expandQuestRight,
        playButtonSize = playButtonSize,
        playButtonRight = playButtonRight,
        focusButtonRight = playButtonRight - playSlot,
    }
end

---@return number
function TrackerLayout.GetBaseFrameWidth()
    return baseFrame:GetWidth()
end

-- Lets the next UpdateWidth resize the tracker to any width again, e.g. when it formats the lines of a drawn
-- tracker after its maximum width changed
function TrackerLayout.ResetRequestedWidth()
    requestedWidth = nil
end

function TrackerLayout.ResetLineWidth()
    lineWidth = 0
    TrackerLayout.ResetRequestedWidth()
end

---@return number
function TrackerLayout.GetLineWidth()
    return lineWidth
end

---@param width number
function TrackerLayout.TrackLineWidth(width)
    lineWidth = math.max(lineWidth, width)
end

---@param width number
function TrackerLayout.UpdateWidth(width)
    -- Lines only need the tracker to grow while a layout is drawn; UpdateFormatting sets its final width afterwards.
    -- Resizing it for every narrower line made the game lay out the whole tracker again for each line.
    if requestedWidth and width <= requestedWidth then
        return
    end
    requestedWidth = width
    updateWidth(width)
end

function TrackerLayout.UpdateHeight()
    updateHeight()
end

--- Sizes an objective line and the tracker to its text, wrapping the text when it exceeds the max tracker width.
---@param line TrackerLineFrame
---@param marginLeft number
function TrackerLayout.UpdateLineWidth(line, marginLeft)
    local trackerMaxWidth = GetScreenWidth() * Questie.db.profile.trackerWidthRatio
    local rightInset = line.questItemInset or 0
    local margin = marginLeft + TrackerLayout.MARGIN_RIGHT + rightInset
    local contentMaxWidth = trackerMaxWidth - margin

    local unboundedWidth = line.label:GetUnboundedStringWidth()
    if (unboundedWidth + margin) < contentMaxWidth then
        -- If the text width is less than the max tracker width, we update the base frame width to fit the text
        TrackerLayout.UpdateWidth(unboundedWidth + margin)
    else
        -- If the text width exceeds the max tracker width, we set the base frame width to the max and allow text to wrap
        TrackerLayout.UpdateWidth(trackerMaxWidth)
    end

    line.label:SetWidth(math.max(1, baseFrame:GetWidth() - margin))
    line:SetWidth(line.label:GetWidth() + marginLeft)

    -- If the line width is less than the minimum Tracker width then don't wrap text
    if unboundedWidth + marginLeft < contentMaxWidth then
        TrackerLayout.TrackLineWidth(unboundedWidth + marginLeft + rightInset)
    else
        -- We use the fontSize as reliable way to determine the line height. GetStringHeight can be inconsistent.
        -- We add an extra pixel per line to account for WoW's internal line spacing on top of the raw font size.
        local _, fontSize = line.label:GetFont()
        local lineHeight = ((fontSize + 1) * line.label:GetNumLines()) + 1 -- add an extra pixel to make sure it really wraps
        line.label:SetHeight(lineHeight)
        line:SetHeight(line.label:GetHeight() + (Questie.db.profile.trackerQuestPadding + 2))

        TrackerLayout.TrackLineWidth(line.label:GetWrappedWidth() + marginLeft + rightInset)
    end
end
