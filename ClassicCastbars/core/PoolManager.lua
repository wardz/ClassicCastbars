local _, namespace = ...

local PoolManager = {}
namespace.PoolManager = PoolManager

local function ResetterFunc(pool, frame)
    if frame.isTesting then
        frame:StopMovingOrSizing()
        frame:EnableMouse(false)
        if frame.tooltip then
            frame.tooltip:Hide()
        end
    end

    if frame.animationGroup and frame.animationGroup:IsPlaying() then
        frame.animationGroup:Stop()
    end

    frame:Hide()
    frame:SetParent(nil)
    frame:ClearAllPoints()
    frame.isTesting = false
    frame.isActiveCast = false
    frame.parent = nil
    frame.unitID = nil
end

-- Note: don't add any major code reworks here, this codebase will soon be replaced with the player-castbar-v2 branch

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
    -- Some of the points set by SmallCastingBarFrameTemplate doesn't
    -- work well when user modify castbar size (not scale), so set our own points instead
    frame.Border:ClearAllPoints()
    frame.Icon:ClearAllPoints()
    frame.Text:ClearAllPoints()
    frame.Icon:SetPoint("LEFT", frame, -15, 0)

    -- Dragonflight / retail
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        frame.TextBorder:SetAlpha(0)
        frame.BorderShield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
        frame.Border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small")
        frame.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small")
        frame.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        frame.Spark:SetBlendMode("ADD")
        frame.Spark:SetSize(32, 32)
    end

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
