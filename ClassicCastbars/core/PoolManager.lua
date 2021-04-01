local _, namespace = ...
local PoolManager = {}
namespace.PoolManager = PoolManager

local function ResetterFunc(pool, frame)
    frame:Hide()
    frame:SetParent(nil)
    frame:ClearAllPoints()

    if frame._data then
        frame._data = nil
    end
end

local framePool = CreateFramePool("Statusbar", UIParent, "SmallCastingBarFrameTemplate", ResetterFunc)
local framesCreated = 0
local framesActive = 0

function PoolManager:AcquireFrame()
    if framesCreated >= 256 then return end -- should never happen

    local frame, isNew = framePool:Acquire()
    framesActive = framesActive + 1

    if isNew then
        framesCreated = framesCreated + 1
        self:InitializeNewFrame(frame)
    end

    return frame, isNew, framesCreated
end

function PoolManager:ReleaseFrame(frame)
    if frame then
        framePool:Release(frame)
        framesActive = framesActive - 1
    end
end

function PoolManager:InitializeNewFrame(frame)
    frame:Hide() -- New frames are always shown, hide it while we're updating it

    -- Some of the points set by SmallCastingBarFrameTemplate doesn't
    -- work well when user modify castbar size, so set our own points instead
    frame.Border:ClearAllPoints()
    frame.Icon:ClearAllPoints()
    frame.Text:ClearAllPoints()
    frame.Icon:SetPoint("LEFT", frame, -15, 0)

    -- Clear any scripts inherited from frame template
    frame:UnregisterAllEvents()
    frame:SetScript("OnLoad", nil)
    frame:SetScript("OnEvent", nil)
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnShow", nil)

    frame.Timer = frame:CreateFontString(nil, "OVERLAY")
    frame.Timer:SetTextColor(1, 1, 1)
    frame.Timer:SetFontObject("SystemFont_Shadow_Small")
    frame.Timer:SetPoint("RIGHT", frame, -6, 0)
end

function PoolManager:GetFramePool()
    return framePool
end

--[[function PoolManager:DebugInfo()
    print(format("Created %d frames in total.", framesCreated))
    print(format("Currently active frames: %d.", framesActive))
end]]
