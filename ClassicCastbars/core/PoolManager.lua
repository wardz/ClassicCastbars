local _, namespace = ...

local PoolManager = {}
namespace.PoolManager = PoolManager

local function ResetterFunc(pool, frame)
    frame:Hide()
    frame:SetParent(nil)
    frame:ClearAllPoints()
    frame.isTesting = false
    frame.isActiveCast = false
    frame.unitID = nil
    frame.parent = nil

    if frame.tooltip then
        frame:EnableMouse(false)
        frame.tooltip:Hide()
    end

    if frame.animationGroup and frame.animationGroup:IsPlaying() then
        frame.animationGroup:Stop()
    end
end

local function OnFadeOutFinish(self)
    local castingBar = self:GetParent()
    castingBar:Hide()
end

-- TODO: with Retails changes to SmallCastingBarFrameTemplate we should look into creating our own template soon
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
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        frame.TextBorder:SetAlpha(0)
        frame.BorderShield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
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

    frame.animationGroup = frame:CreateAnimationGroup()
    frame.animationGroup:SetToFinalAlpha(true)
    frame.animationGroup:SetScript("OnFinished", OnFadeOutFinish)

    frame.fade = frame.animationGroup:CreateAnimation("Alpha")
    frame.fade:SetOrder(1)
    frame.fade:SetFromAlpha(1)
    frame.fade:SetToAlpha(0)
    frame.fade:SetSmoothing("OUT")

    if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        for _, v in pairs({ frame:GetRegions() }) do
            --if v.GetTexture and (strfind("UI-StatusBar", v:GetTexture() or "") or v:GetTexture() == 137012) then
            -- WARN: this is currently a hacky fix after the above method broke
            if v.GetDrawLayer and v:GetDrawLayer() == "BACKGROUND" then
                frame.Background = v
                break
            end
        end
    end
end

function PoolManager:GetFramePool()
    return framePool
end

--[[function PoolManager:DebugInfo()
    print(format("Created %d frames in total.", framesCreated))
    print(format("Currently active frames: %d.", framesActive))
end]]
