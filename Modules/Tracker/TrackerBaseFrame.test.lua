dofile("setupTests.lua")

---@type QuestieTracker
local QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
QuestieTracker.Enable = spy.new(function() end)
QuestieTracker.Disable = spy.new(function() end)

dofile("Modules/Tracker/TrackerBaseFrame.lua")
local TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")

describe("TrackerBaseFrame", function()
    describe("OnProfileChange", function()
        before_each(function()
            QuestieTracker.Enable:clear()
            QuestieTracker.Disable:clear()
        end)

        it("should not error when the tracker was never created and stays disabled", function()
            Questie.db.profile.trackerEnabled = false
            Questie.db.profile.TrackerLocation = {"TOPLEFT", nil, "TOPLEFT", 0, 0}

            assert.has_no.errors(function()
                TrackerBaseFrame:OnProfileChange()
            end)
            assert.spy(QuestieTracker.Enable).was_not.called()
            assert.spy(QuestieTracker.Disable).was_not.called()
        end)

        it("should enable the tracker when it was never created and is now enabled", function()
            Questie.db.profile.trackerEnabled = true

            TrackerBaseFrame:OnProfileChange()

            assert.spy(QuestieTracker.Enable).was.called()
        end)
    end)

    it("refreshes the Forever companion when an attached quest tracker changes size or visibility", function()
        local originalFrame, originalForever = _G.CreateFrame, Questie.IsForever
        local originalHost, originalCompanion = _G.ForeverTrackerHost, _G.ForeverTrackerCompanion
        local originalLocation, originalColor = Questie.db.profile.TrackerLocation, Questie.db.profile.trackerBackdropColor
        local function noop() end
        local hooks = {}
        local frame
        frame = setmetatable({
            CreateTexture = function() return frame end,
            HookScript = function(_, event, callback) hooks[event] = callback end,
        }, {__index = function() return noop end})
        _G.CreateFrame = function() return frame end
        Questie.IsForever = true
        Questie.db.profile.TrackerLocation = {"TOPLEFT"}
        Questie.db.profile.trackerBackdropColor = {r = 0, g = 0, b = 0, a = 0}
        local attached = true
        _G.ForeverTrackerHost = {IsAttachedToQuestTracker = function() return attached end}
        local refresh = spy.new(noop)
        _G.ForeverTrackerCompanion = {MarkDirty = refresh}

        TrackerBaseFrame.Initialize()
        hooks.OnShow()
        hooks.OnSizeChanged()
        hooks.OnHide()
        attached = false
        hooks.OnSizeChanged()

        _G.CreateFrame, Questie.IsForever = originalFrame, originalForever
        _G.ForeverTrackerHost, _G.ForeverTrackerCompanion = originalHost, originalCompanion
        Questie.db.profile.TrackerLocation, Questie.db.profile.trackerBackdropColor = originalLocation, originalColor
        assert.spy(refresh).was.called(3)
    end)
end)
