local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager

local addon = namespace.addon
local activeFrames = addon.activeFrames
local gsub = _G.string.gsub
local strfind = _G.string.find
local unpack = _G.unpack
local min = _G.math.min
local max = _G.math.max
local ceil = _G.math.ceil
local UnitExists = _G.UnitExists

function addon:GetCastbarFrame(unitID)
    -- PoolManager:DebugInfo()
    if unitID == "player" then return CastingBarFrame end

    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    activeFrames[unitID] = PoolManager:AcquireFrame()

    return activeFrames[unitID]
end

function addon:SetTargetCastbarPosition(castbar, parentFrame)
    local auraRows = parentFrame.auraRows or 0

    if parentFrame.haveToT or parentFrame.haveElite or UnitExists("targettarget") then -- TODO: test if works with custom unitframe
        if parentFrame.buffsOnTop or auraRows <= 1 then
            castbar:SetPoint("CENTER", parentFrame, -18, -75)
        else
            castbar:SetPoint("CENTER", parentFrame, -18, max(min(-75, -37.5 * auraRows), -150))
        end
    else
        if not parentFrame.buffsOnTop and auraRows > 0 then
            castbar:SetPoint("CENTER", parentFrame, -18, max(min(-75, -37.5 * auraRows), -150))
        else
            castbar:SetPoint("CENTER", parentFrame, -18, -50)
        end
    end
end

function addon:SetCastbarIconAndText(castbar, cast, db)
    local spellName = cast.spellName

    if castbar.Text:GetText() ~= spellName then
        if cast.icon == 136235 then
            cast.icon = 136243
        end
        castbar.Icon:SetTexture(cast.icon)
        castbar.Text:SetText(spellName)

        -- Move timer position depending on spellname length
        if db.showTimer then
            castbar.Timer:SetPoint("RIGHT", castbar, (spellName:len() >= 19) and 30 or -6, 0)
        end
    end
end

function addon:SetCastbarStyle(castbar, cast, db)
    castbar:SetSize(db.width, db.height)
    castbar.Timer:SetShown(db.showTimer)
    castbar:SetStatusBarTexture(db.castStatusBar)
    castbar:SetFrameLevel(db.frameLevel)

    if db.showCastInfoOnly then
        castbar.Timer:SetText("")
        castbar:SetValue(0)
        castbar.Spark:SetAlpha(0)
    else
        castbar.Spark:SetAlpha(1)
    end

    if db.hideIconBorder then
        castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        castbar.Icon:SetTexCoord(0, 1, 0, 1)
    end

    castbar.Spark:SetHeight(db.height * 2.1)
    castbar.Icon:SetShown(db.showIcon)
    castbar.Icon:SetSize(db.iconSize, db.iconSize)
    castbar.Icon:SetPoint("LEFT", castbar, db.iconPositionX - db.iconSize, db.iconPositionY)
    castbar.Border:SetVertexColor(unpack(db.borderColor))

    castbar.Flash:ClearAllPoints()
    castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height-1)
    castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height-1)

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small" or db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" then -- default border
        castbar.Border:SetAlpha(1)
        if castbar.BorderFrame then
            -- Hide LSM border frame if it exists
            castbar.BorderFrame:SetAlpha(0)
        end

        -- Update border to match castbar size
        local width, height = ceil(castbar:GetWidth() * 1.16), ceil(castbar:GetHeight() * 1.16)
        castbar.Border:ClearAllPoints()
        castbar.Border:SetPoint("TOPLEFT", width, height+1)
        castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
    else
        -- Using border sat by LibSharedMedia
        self:SetLSMBorders(castbar, cast, db)
    end
end

local textureFrameLevels = {
    ["Interface\\CHARACTERFRAME\\UI-Party-Border"] = 1,
    ["Interface\\Tooltips\\ChatBubble-Backdrop"] = 1,
}

function addon:SetLSMBorders(castbar, cast, db)
    -- Create new frame to contain our LSM backdrop
    if not castbar.BorderFrame then
        castbar.BorderFrame = CreateFrame("Frame", nil, castbar)
        castbar.BorderFrame:SetPoint("TOPLEFT", castbar, -2, 2)
        castbar.BorderFrame:SetPoint("BOTTOMRIGHT", castbar, 2, -2)
    end

    -- Apply backdrop if it isn't already active
    if castbar.BorderFrame.currentTexture ~= db.castBorder or castbar:GetHeight() ~= castbar.BorderFrame.currentHeight then
        castbar.BorderFrame:SetBackdrop({
            edgeFile = db.castBorder,
            tile = false, tileSize = 0,
            edgeSize = castbar:GetHeight(),
        })
        castbar.BorderFrame.currentTexture = db.castBorder
        castbar.BorderFrame.currentHeight = castbar:GetHeight()
    end

    castbar.Border:SetAlpha(0) -- hide default border
    castbar.BorderFrame:SetAlpha(1)
    castbar.BorderFrame:SetFrameLevel(textureFrameLevels[db.castBorder] or castbar:GetFrameLevel() + 1)
    castbar.BorderFrame:SetBackdropBorderColor(unpack(db.borderColor))
end

function addon:SetCastbarFonts(castbar, cast, db)
    local fontName, fontHeight = castbar.Text:GetFont()
    if fontName ~= db.castFont or db.castFontSize ~= fontHeight then
        castbar.Text:SetFont(db.castFont, db.castFontSize)
        castbar.Timer:SetFont(db.castFont, db.castFontSize)
    end

    local c = db.textColor
    castbar.Text:SetTextColor(c[1], c[2], c[3], c[4])
    castbar.Timer:SetTextColor(c[1], c[2], c[3], c[4])
    castbar.Text:SetPoint("CENTER", db.textPositionX, db.textPositionY)
end

local function GetStatusBarBackgroundTexture(statusbar)
    if statusbar.Background then return statusbar.Background end

    for _, v in pairs({ statusbar:GetRegions() }) do
        if v.GetTexture and v:GetTexture() and strfind(v:GetTexture(), "Color-") then
            return v
        end
    end
end

function addon:DisplayCastbar(castbar, unitID)
    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    local db = self.db[gsub(unitID, "%d", "")] -- nameplate1 -> nameplate
    if unitID == "nameplate-testmode" then
        db = self.db.nameplate
    elseif unitID == "party-testmode" then
        db = self.db.party
    end

    if not castbar.animationGroup then
        castbar.animationGroup = castbar:CreateAnimationGroup()
        castbar.animationGroup:SetToFinalAlpha(true)
        castbar.fade = castbar.animationGroup:CreateAnimation("Alpha")
        castbar.fade:SetOrder(1)
        castbar.fade:SetFromAlpha(1)
        castbar.fade:SetToAlpha(0)
        castbar.fade:SetSmoothing("OUT")
    end
    castbar.animationGroup:Stop()

    if not castbar.Background then
        castbar.Background = GetStatusBarBackgroundTexture(castbar)
    end
    castbar.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    local cast = castbar._data
    cast.showCastInfoOnly = db.showCastInfoOnly
    if cast.isChanneled then
        castbar:SetStatusBarColor(unpack(db.statusColorChannel))
    else
        castbar:SetStatusBarColor(unpack(db.statusColor))
    end

    -- Note: since frames are recycled and we also allow having different styles
    -- between castbars for all the unitframes, we need to always update the style here
    -- incase it was modified to something else on last recycle
    self:SetCastbarStyle(castbar, cast, db)
    self:SetCastbarFonts(castbar, cast, db)
    self:SetCastbarIconAndText(castbar, cast, db)

    if unitID == "target" and self.db.target.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    else
        castbar:SetPoint(db.position[1], parentFrame, db.position[2], db.position[3])
    end

    if not castbar.isTesting then
        castbar:SetMinMaxValues(0, cast.maxValue)
        castbar:SetValue(0)
        castbar.Spark:SetPoint("CENTER", castbar, "LEFT", 0, 0)
    end

    castbar.Flash:Hide()
    castbar:SetParent(parentFrame)
    castbar.Text:SetWidth(db.width - 10) -- ensures text gets truncated
    castbar:SetAlpha(1)
    castbar:Show()
end

function addon:HideCastbar(castbar, noFadeOut)
    if noFadeOut then
        castbar:SetAlpha(0)
        castbar:Hide()
        return
    end

    local cast = castbar._data
    if cast and cast.isInterrupted then
        castbar.Text:SetText(_G.INTERRUPTED)
        castbar:SetStatusBarColor(castbar.failedCastColor:GetRGB())
        castbar:SetMinMaxValues(0, 1)
        castbar:SetValue(1)
        castbar.Spark:SetAlpha(0)
    end

    if cast and cast.isCastComplete then
        if castbar.Border:GetAlpha() == 1 then -- not using LSM borders
            local tex = castbar.Border:GetTexture()
            if tex == "Interface\\CastingBar\\UI-CastingBar-Border" or tex == "Interface\\CastingBar\\UI-CastingBar-Border-Small" then
                castbar.Flash:Show()
            end
        end

        castbar.Spark:SetAlpha(0)
        castbar:SetMinMaxValues(0, 1)
        if not cast.isChanneled then
            castbar:SetStatusBarColor(0, 1, 0)
            castbar:SetValue(1)
        else
            castbar:SetValue(0)
        end
    end

    if castbar:GetAlpha() > 0 and castbar.fade then
        castbar.fade:SetDuration(cast and cast.isInterrupted and 1.5 or 0.3)
        castbar.animationGroup:Play()
    end
end

function addon:SkinPlayerCastbar()
    local db = self.db.player
    if not db.enabled then return end

    if not CastingBarFrame.Timer then
        CastingBarFrame.Timer = CastingBarFrame:CreateFontString(nil, "OVERLAY")
        CastingBarFrame.Timer:SetTextColor(1, 1, 1)
        CastingBarFrame.Timer:SetFontObject("SystemFont_Shadow_Small")
        CastingBarFrame.Timer:SetPoint("RIGHT", CastingBarFrame, -6, 0)
        CastingBarFrame:HookScript("OnUpdate", function(frame)
            if db.enabled and db.showTimer then
                if not frame.channeling then
                    frame.Timer:SetFormattedText("%.1f", frame.casting and (frame.maxValue - frame.value) or 0)
                else
                    frame.Timer:SetFormattedText("%.1f", frame.fadeOut and 0 or frame.value)
                end
            end
        end)
    end
    CastingBarFrame.Timer:SetShown(db.showTimer)

    if not CastingBarFrame.CC_isHooked then
        CastingBarFrame:HookScript("OnShow", function(frame)
            if frame.Icon:GetTexture() == 136235 then
                frame.Icon:SetTexture(136243)
            end
        end)

        hooksecurefunc("PlayerFrame_DetachCastBar", function()
            addon:SkinPlayerCastbar()
        end)

        hooksecurefunc("PlayerFrame_AttachCastBar", function()
            addon:SkinPlayerCastbar()
        end)
        CastingBarFrame.CC_isHooked = true
    end

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" or db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small" then
        CastingBarFrame.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
        CastingBarFrame.Flash:SetSize(db.width + 61, db.height + 51)
        CastingBarFrame.Flash:SetPoint("TOP", 0, 26)
    else
        CastingBarFrame.Flash:SetTexture(nil) -- hide it by deleting texture, SetAlpha() or Hide() wont work without messing with blizz code
    end

    CastingBarFrame_SetStartCastColor(CastingBarFrame, unpack(db.statusColor))
	CastingBarFrame_SetStartChannelColor(CastingBarFrame, unpack(db.statusColorChannel))
	--CastingBarFrame_SetFinishedCastColor(CastingBarFrame, unpack(db.statusColor))
	--CastingBarFrame_SetNonInterruptibleCastColor(CastingBarFrame, 0.7, 0.7, 0.7)
    --CastingBarFrame_SetFailedCastColor(CastingBarFrame, 1.0, 0.0, 0.0)
    if CastingBarFrame.isTesting then
        CastingBarFrame:SetStatusBarColor(CastingBarFrame.startCastColor:GetRGB())
    end

    CastingBarFrame.Text:ClearAllPoints()
    CastingBarFrame.Text:SetPoint("CENTER")
    CastingBarFrame.Icon:ClearAllPoints()
    CastingBarFrame.Icon:SetShown(db.showIcon)

    if not CastingBarFrame.Background then
        CastingBarFrame.Background = GetStatusBarBackgroundTexture(CastingBarFrame)
    end
    CastingBarFrame.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    if not db.autoPosition then
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame.ignoreFramePositionManager = true

        local pos = db.position
        CastingBarFrame:SetPoint(pos[1], UIParent, pos[2], pos[3])
    else
        if not _G.PLAYER_FRAME_CASTBARS_SHOWN then
            CastingBarFrame.ignoreFramePositionManager = false
            CastingBarFrame:ClearAllPoints()
            CastingBarFrame:SetPoint("BOTTOM", UIParent, 0, 150)
        end
    end

    self:SetCastbarStyle(CastingBarFrame, nil, db)
    self:SetCastbarFonts(CastingBarFrame, nil, db)
end
