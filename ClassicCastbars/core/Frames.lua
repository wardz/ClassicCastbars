local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local ClassicCastbars = _G.ClassicCastbars

local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local unpack = _G.unpack
local min = _G.math.min
local max = _G.math.max
local ceil = _G.math.ceil

local CastingBarFrame = isRetail and _G.PlayerCastingBarFrame or _G.CastingBarFrame

local nonLSMBorders = {
    ["Interface\\CastingBar\\UI-CastingBar-Border-Small"] = true,
    ["Interface\\CastingBar\\UI-CastingBar-Border"] = true,
    [130873] = true,
    [130874] = true,
}

local function GetStatusBarBackgroundTexture(statusbar)
    if statusbar.Background then return statusbar.Background end

    -- Get the actual statusbar background, not statusbar texture from statusbar:GetStatusBarTexture()
    for _, v in pairs({ statusbar:GetRegions() }) do
        --if v.GetTexture and (strfind("UI-StatusBar", v:GetTexture() or "") or v:GetTexture() == 137012) then
        -- WARN: this is currently a hacky fix untill we create our own frame templates in PoolManager.lua
        if v.GetDrawLayer and v:GetDrawLayer() == "BACKGROUND" then
            return v
        end
    end
end

function ClassicCastbars:SetTargetCastbarPosition(castbar, parentFrame)
    if isRetail then
        if parentFrame.auraRows == nil then
            parentFrame.auraRows = 0
        end

        -- Copy paste from retail wow ui source
        local useSpellbarAnchor = (not parentFrame.buffsOnTop) and ((parentFrame.haveToT and parentFrame.auraRows > 2) or ((not parentFrame.haveToT) and parentFrame.auraRows > 0))

        local relativeKey = useSpellbarAnchor and parentFrame.spellbarAnchor or parentFrame
        local pointX = useSpellbarAnchor and 18 or (parentFrame.smallSize and 38 or 43)
        local pointY = useSpellbarAnchor and -10 or (parentFrame.smallSize and 3 or 5)

        if ((not useSpellbarAnchor) and parentFrame.haveToT) then
            pointY = parentFrame.smallSize and -48 or -46
        end

        castbar:SetPoint("TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, pointY - 4)
    else
        if parentFrame == _G.TargetFrame or parentFrame == _G.FocusFrame then
            -- copy paste from wotlk wow ui source
            if parentFrame.haveToT then
                if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
                    castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -21)
                else
                    castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                end
            elseif parentFrame.haveElite then
                if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
                    castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -5)
                else
                    castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                end
            else
                if ((not parentFrame.buffsOnTop) and parentFrame.auraRows > 0) then
                    castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                else
                    castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 7)
                end
            end
        else -- unknown parent frame
            local auraRows = parentFrame.auraRows or 0

            if parentFrame.buffsOnTop or auraRows <= 1 then
                castbar:SetPoint("CENTER", parentFrame, -18, -75)
            else
                if castbar.BorderShield:IsShown() then
                    castbar:SetPoint("CENTER", parentFrame, -18, max(min(-75, -45 * auraRows), -200))
                else
                    castbar:SetPoint("CENTER", parentFrame, -18, max(min(-75, -41 * auraRows), -200))
                end
            end
        end
    end
end

function ClassicCastbars:SetCastbarIconAndText(castbar, db)
    local spellName = castbar.spellName or ""

    if castbar.icon == 136235 then -- unknown texture
        castbar.icon = 136243
    end
    castbar.Text:ClearAllPoints()
    castbar.Text:SetPoint(db.textPoint)
    castbar.Text:SetJustifyH(db.textPoint)
    castbar.Icon:SetTexture(castbar.icon)
    castbar.Text:SetText(spellName)

    -- Move timer position depending on spellname length
    if db.showTimer then
        local yOff = 0
        if db.showBorderShield and castbar.isUninterruptible then
            yOff = yOff + 2
        end
        castbar.Timer:SetPoint("RIGHT", castbar, (spellName:len() >= 19) and 30 or -6, yOff)
    end
end

function ClassicCastbars:SetBorderShieldStyle(castbar, db, unitID)
    if db.showBorderShield and castbar.isUninterruptible then
        castbar.Border:SetAlpha(0)
        if castbar.BorderFrameLSM then
            castbar.BorderFrameLSM:SetAlpha(0)
        end

        -- Update border shield to match current castbar size
        local width, height = castbar:GetWidth() * db.borderPaddingWidth + 0.3, castbar:GetHeight() * db.borderPaddingHeight + 0.3
        castbar.BorderShield:ClearAllPoints()
        castbar.BorderShield:SetPoint("TOPLEFT", width-5, height+1) -- texture offsets, just doing "1" and "-1" doesnt work here
        castbar.BorderShield:SetPoint("BOTTOMRIGHT", -width+(width*0.15), -height + 4)

        if not castbar.IconShield then
            castbar.BorderShield:SetTexCoord(0.16, 0, 0.118, 1, 1, 0, 1, 1) -- cut left side of texture away

            castbar.IconShield = castbar:CreateTexture(nil, "OVERLAY")
            castbar.IconShield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Arena-Shield")
        end

        castbar.IconShield:SetPoint("LEFT", castbar.Icon, "LEFT", -0.44 * db.iconSize, 0)
        castbar.IconShield:SetSize(db.iconSize * 3, db.iconSize * 3)

        local unitType = self:GetUnitType(unitID)
        if unitType == "nameplate" then
            castbar.Icon:SetPoint("LEFT", castbar, (db.iconPositionX - db.iconSize), db.iconPositionY + 2)
        elseif unitType == "party" then
            castbar.Icon:SetPoint("LEFT", castbar, (db.iconPositionX - db.iconSize) + 2, db.iconPositionY + 2)
        else
            castbar.Icon:SetPoint("LEFT", castbar, (db.iconPositionX - db.iconSize) + 2, db.iconPositionY + 2)
        end

        castbar.BorderShield:Show()
        castbar.IconShield:SetShown(db.showIcon)
    else
        if nonLSMBorders[db.castBorder] then
            castbar.Border:SetAlpha(db.borderColor[4])
        else
            if castbar.BorderFrameLSM then
                castbar.BorderFrameLSM:SetAlpha(db.borderColor[4])
            end
        end
        castbar.BorderShield:Hide()
        if castbar.IconShield then
            castbar.IconShield:Hide()
        end
        castbar.Icon:SetPoint("LEFT", castbar, db.iconPositionX - db.iconSize, db.iconPositionY)
    end
end

function ClassicCastbars:RefreshBorderShield(castbar, unitID)
    local db = self.db[self:GetUnitType(unitID)]
    if not db then return end

    -- Update displays related to border shield
    self:SetCastbarIconAndText(castbar, db)
    self:SetCastbarStatusColorsOnDisplay(castbar, db)
    self:SetCastbarFonts(castbar, db)
    self:SetBorderShieldStyle(castbar, db, unitID)

    castbar.Flash:ClearAllPoints()
    if castbar.isUninterruptible then
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end
end

function ClassicCastbars:SetCastbarStyle(castbar, db, unitID)
    castbar:SetSize(db.width, db.height)
    castbar.Timer:SetShown(db.showTimer)
    castbar:SetStatusBarTexture(db.castStatusBar)
    castbar:SetFrameStrata(db.frameStrata)
    castbar:SetFrameLevel(db.frameLevel)
    castbar.Text:SetWidth(db.width - 10) -- ensures text gets truncated
    castbar.currWidth = db.width -- avoids having to use a function call later on in OnUpdate
    castbar:SetIgnoreParentAlpha(db.ignoreParentAlpha)

    castbar.Border:SetDrawLayer("ARTWORK", 1)
    castbar.BorderShield:SetDrawLayer("ARTWORK", 2)
    castbar.Text:SetDrawLayer("ARTWORK", 3)
    castbar.Icon:SetDrawLayer("OVERLAY", 1)
    castbar.Spark:SetDrawLayer("OVERLAY", 2)
    castbar.Flash:SetDrawLayer("OVERLAY", 3)

    if castbar.isChanneled then
        castbar.Spark:SetAlpha(0)
    else
        castbar.Spark:SetAlpha(db.showSpark and 1 or 0)
    end

    if db.hideIconBorder then
        castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        castbar.Icon:SetTexCoord(0, 1, 0, 1)
    end

    castbar.Spark:SetHeight(db.height * 2.1)
    castbar.Icon:SetShown(db.showIcon)
    castbar.Icon:SetSize(db.iconSize, db.iconSize)
    castbar.Border:SetVertexColor(unpack(db.borderColor))

    castbar.Flash:ClearAllPoints()
    if castbar.isUninterruptible then
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end

    local isDefaultBorder = nonLSMBorders[db.castBorder]
    if isDefaultBorder then
        castbar.Border:SetAlpha(db.borderColor[4])
        if castbar.BorderFrameLSM then
            -- Hide LSM border frame if it exists
            castbar.BorderFrameLSM:SetAlpha(0)
        end

        -- Update border to match castbar size
        local width, height = castbar:GetWidth() * db.borderPaddingWidth, castbar:GetHeight() * db.borderPaddingHeight
        castbar.Border:ClearAllPoints()
        castbar.Border:SetPoint("TOPLEFT", width, height)
        castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
    else
        -- Using border sat by LibSharedMedia
        self:SetLSMBorders(castbar, db)
    end

    self:SetBorderShieldStyle(castbar, db, unitID)
end

local textureFrameLevels = {
    ["Interface\\CHARACTERFRAME\\UI-Party-Border"] = 1,
    ["Interface\\Tooltips\\ChatBubble-Backdrop"] = 1,
}

function ClassicCastbars:SetLSMBorders(castbar, db)
    -- Create new frame to contain our LSM backdrop
    if not castbar.BorderFrameLSM then
        castbar.BorderFrameLSM = CreateFrame("Frame", nil, castbar, _G.BackdropTemplateMixin and "BackdropTemplate")
        castbar.BorderFrameLSM:SetPoint("TOPLEFT", castbar, -2, 2)
        castbar.BorderFrameLSM:SetPoint("BOTTOMRIGHT", castbar, 2, -2)
    end

    -- Apply backdrop if it isn't already active
    if castbar.BorderFrameLSM.currentTexture ~= db.castBorder or castbar.BorderFrameLSM.currentSize ~= db.edgeSizeLSM then
        castbar.BorderFrameLSM:SetBackdrop({
            edgeFile = db.castBorder,
            tile = true, tileSize = db.edgeSizeLSM,
            edgeSize = db.edgeSizeLSM,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        castbar.BorderFrameLSM.currentTexture = db.castBorder
        castbar.BorderFrameLSM.currentSize = db.edgeSizeLSM
    end

    castbar.Border:SetAlpha(0) -- hide default border
    castbar.BorderFrameLSM:SetAlpha(db.borderColor[4])
    castbar.BorderFrameLSM:SetFrameLevel(textureFrameLevels[db.castBorder] or castbar:GetFrameLevel() + 1)
    castbar.BorderFrameLSM:SetBackdropBorderColor(unpack(db.borderColor))
end

function ClassicCastbars:SetCastbarFonts(castbar, db)
    local fontName, fontHeight, fontFlags = castbar.Text:GetFont()
    if fontName ~= db.castFont or db.castFontSize ~= fontHeight or db.textOutline ~= fontFlags then
        castbar.Text:SetFont(db.castFont, db.castFontSize, db.textOutline)
        castbar.Timer:SetFont(db.castFont, db.castFontSize, db.textOutline)

        castbar.Text:SetShadowColor(0, 0, 0, db.textOutline == "" and 1 or 0)
        castbar.Timer:SetShadowColor(0, 0, 0, db.textOutline == "" and 1 or 0)
    end

    local c = db.textColor
    castbar.Text:SetTextColor(c[1], c[2], c[3], c[4])
    castbar.Timer:SetTextColor(c[1], c[2], c[3], c[4])

    local yOff = db.textPositionY
    if db.showBorderShield and castbar.isUninterruptible then
        yOff = yOff + 2
    end
    castbar.Text:SetJustifyH(db.textPoint)
    castbar.Text:ClearAllPoints()
    castbar.Text:SetPoint(db.textPoint, db.textPositionX, yOff)
end

local function OnFadeOutFinish(self)
    local castingBar = self:GetParent()
    castingBar:Hide()
end

function ClassicCastbars:CreateFadeAnimationGroup(frame)
    if frame.animationGroup then return frame.animationGroup end
    frame.animationGroup = frame:CreateAnimationGroup()
    frame.animationGroup:SetToFinalAlpha(true)
    frame.animationGroup:SetScript("OnFinished", OnFadeOutFinish)

    frame.fade = frame.animationGroup:CreateAnimation("Alpha")
    frame.fade:SetOrder(1)
    frame.fade:SetFromAlpha(1)
    frame.fade:SetToAlpha(0)
    frame.fade:SetSmoothing("OUT")

    return frame.animationGroup
end

function ClassicCastbars:SetCastbarStatusColorsOnDisplay(castbar, db)
    castbar.Background = castbar.Background or GetStatusBarBackgroundTexture(castbar)
    castbar.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    if castbar.isChanneled then
        castbar:SetStatusBarColor(unpack(db.statusColorChannel))
    elseif castbar.isUninterruptible then
        castbar:SetStatusBarColor(unpack(db.statusColorUninterruptible))
    else
        castbar:SetStatusBarColor(unpack(db.statusColor))
    end
end

function ClassicCastbars:SetFinishCastStyle(castbar, unitID)
    if not castbar.isActiveCast or castbar.value == nil then return end

    -- Failed cast
    if castbar.isInterrupted or castbar.isFailed then
        castbar.Text:SetText(castbar.isInterrupted and _G.INTERRUPTED or _G.FAILED)

        local r, g, b = unpack(self.db[self:GetUnitType(unitID)].statusColorFailed)
        castbar:SetStatusBarColor(r, g, b) -- Skipping alpha channel as it messes with fade out animations
        castbar:SetMinMaxValues(0, 1)
        castbar:SetValue(1)
        castbar.Spark:SetAlpha(0)
    end

    -- Successfull cast
    if castbar.isCastComplete then
        if castbar.Border:GetAlpha() == 1 or castbar.isUninterruptible then
            if castbar.BorderShield:IsShown() or nonLSMBorders[castbar.Border:GetTextureFilePath() or ""] or nonLSMBorders[castbar.Border:GetTexture() or ""] then
                if castbar.isUninterruptible then
                    castbar.Flash:SetVertexColor(0.7, 0.7, 0.7, 1)
                elseif castbar.isChanneled then
                    castbar.Flash:SetVertexColor(0, 1, 0, 1)
                else
                    castbar.Flash:SetVertexColor(1, 1, 1, 1)
                end
                castbar.Flash:Show()
            end
        end

        castbar.Spark:SetAlpha(0)
        castbar:SetMinMaxValues(0, 1)

        if not castbar.isChanneled then
            if castbar.isUninterruptible then
                castbar:SetStatusBarColor(0.7, 0.7, 0.7)
            else
                local r, g, b = unpack(self.db[self:GetUnitType(unitID)].statusColorSuccess)
                castbar:SetStatusBarColor(r, g, b)
            end
            castbar:SetValue(1)
        else
            castbar:SetValue(0)
        end
    end
end

function ClassicCastbars:DisplayCastbar(castbar, unitID)
    if not castbar.isActiveCast or castbar.value == nil then return end

    if not castbar.isTesting then
        if (castbar.isChanneled and castbar.value <= 0) or (not castbar.isChanneled and castbar.value >= castbar.maxValue) then -- cast expired
            castbar.isActiveCast = false
            return
        end
    end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    local db = self.db[self:GetUnitType(unitID)]
    if not db then return end

    castbar.animationGroup = castbar.animationGroup or self:CreateFadeAnimationGroup(castbar)
    if castbar.animationGroup:IsPlaying() then
        castbar.animationGroup:Stop()
    end

    -- Note: since frames are recycled and we also allow having different styles
    -- between castbars for all the unitframes, we need to always update the style here
    -- incase it was modified to something else on last recycle
    self:SetCastbarStyle(castbar, db, unitID)
    self:SetCastbarIconAndText(castbar, db)
    self:SetCastbarFonts(castbar, db)
    self:SetCastbarStatusColorsOnDisplay(castbar, db)

    castbar:ClearAllPoints()
    if unitID == "target" and self.db.target.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    elseif unitID == "focus" and self.db.focus.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    else
        castbar:SetPoint(db.position[1], parentFrame, db.position[2], db.position[3])
    end

    if castbar.isTesting then
        castbar.maxValue = 10
        castbar.value = 5
    end

    local sparkPosition = (castbar.value / castbar.maxValue) * (castbar.currWidth or castbar:GetWidth())
    castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
    castbar:SetMinMaxValues(0, castbar.maxValue)
    castbar:SetValue(castbar.value)
    castbar:SetParent(parentFrame)
    castbar.Flash:Hide()
    castbar:SetAlpha(1)
    castbar:Show()
end

function ClassicCastbars:HideCastbar(castbar, unitID, skipFadeOut)
    if castbar.isTesting then return end

    if skipFadeOut then
        if castbar.animationGroup then
            castbar.animationGroup:Stop()
        end
        castbar:Hide()
        castbar.isActiveCast = false
        return
    end

    self:SetFinishCastStyle(castbar, unitID)

    if castbar.fade then
        if not castbar.animationGroup:IsPlaying() then
            castbar.fade:SetStartDelay(0.1) -- reset
            if castbar.isActiveCast then
                if castbar.isInterrupted or castbar.isFailed then
                    castbar.fade:SetStartDelay(0.6)
                end
            end

            if isClassicEra then
                castbar.fade:SetDuration(castbar.isActiveCast and castbar.isInterrupted and 1 or 0.4)
            else
                castbar.fade:SetDuration(0.4)
            end
            castbar.isActiveCast = false
            castbar.animationGroup:Play()
        end
    end
end

--------------------------------------------------------------
-- Player & Focus Castbar Stuff
--------------------------------------------------------------

local function ColorPlayerCastbar()
    local db = ClassicCastbars.db.player
    if not db.enabled then return end

    if CastingBarFrame_SetNonInterruptibleCastColor then
        CastingBarFrame_SetNonInterruptibleCastColor(CastingBarFrame, unpack(db.statusColorUninterruptible))
    else
        CastingBarFrame.iconWhenNoninterruptible = false
    end

    CastingBarFrame_SetStartCastColor(CastingBarFrame, unpack(db.statusColor))
    CastingBarFrame_SetStartChannelColor(CastingBarFrame, unpack(db.statusColorChannel))
    CastingBarFrame_SetFailedCastColor(CastingBarFrame, unpack(db.statusColorFailed))
    --if CastingBarFrame.isTesting then
    CastingBarFrame:SetStatusBarColor(unpack(db.statusColor))
    --end

    CastingBarFrame_SetFinishedCastColor(CastingBarFrame, unpack(db.statusColorSuccess))
    CastingBarFrame_SetUseStartColorForFinished(CastingBarFrame, false)
    CastingBarFrame_SetUseStartColorForFlash(CastingBarFrame, false)

    CastingBarFrame.Background = CastingBarFrame.Background or GetStatusBarBackgroundTexture(CastingBarFrame)
    CastingBarFrame.Background:SetColorTexture(unpack(db.statusBackgroundColor))
end

-- TODO: recreate castbar instead of skinning
-- This spaghetti code just got worse and worse after retails 10.0+ changes :/
function ClassicCastbars:SkinPlayerCastbar()
    if not self.db then return end

    local db = self.db.player
    if not db.enabled then return end

    if not CastingBarFrame.showCastbar or not CastingBarFrame:IsEventRegistered("UNIT_SPELLCAST_START") then
        print("|cFFFF0000[ClassicCastbars] Incompatibility detected for PLAYER castbar. You most likely have another addon disabling the default Blizzard castbar.|r") -- luacheck: ignore
    end

    if not CastingBarFrame.Timer then
        CastingBarFrame.Timer = CastingBarFrame:CreateFontString(nil, "OVERLAY")
        CastingBarFrame.Timer:SetTextColor(1, 1, 1)
        CastingBarFrame.Timer:SetFontObject("SystemFont_Shadow_Small")
        CastingBarFrame:HookScript("OnUpdate", function(frame)
            if db.enabled and db.showTimer then
                if frame.fadeOut or (not frame.casting and not frame.channeling) then
                    -- just show no text at zero, the numbers looks kinda weird when Flash animation is playing
                    return frame.Timer:SetText("")
                end

                if not frame.channeling then
                    if db.showTotalTimer then
                        frame.Timer:SetFormattedText("%.1f/%.1f", frame.maxValue - frame.value, frame.maxValue)
                    else
                        frame.Timer:SetFormattedText("%.1f", frame.maxValue - frame.value)
                    end
                else
                    if db.showTotalTimer then
                        frame.Timer:SetFormattedText("%.1f/%.1f", frame.value, frame.maxValue)
                    else
                        frame.Timer:SetFormattedText("%.1f", frame.value)
                    end
                end
            end
        end)

        hooksecurefunc(CastingBarFrame.Text, "SetText", function(_, text)
            if text and text.len then
                CastingBarFrame.Timer:SetPoint("RIGHT", CastingBarFrame, (text:len() >= 19) and 30 or -6, 0)
            end
        end)
    end
    CastingBarFrame.Timer:SetShown(db.showTimer)

    if not CastingBarFrame.CC_isHooked and not isRetail then
        CastingBarFrame:HookScript("OnShow", function(frame)
            if frame.Icon:GetTexture() == 136235 then
                frame.Icon:SetTexture(136243)
            end
        end)

        hooksecurefunc("PlayerFrame_DetachCastBar", function()
            ClassicCastbars:SkinPlayerCastbar()
        end)

        hooksecurefunc("PlayerFrame_AttachCastBar", function()
            ClassicCastbars:SkinPlayerCastbar()
        end)

        hooksecurefunc("PlayerFrame_AdjustAttachments", function()
            if _G.PLAYER_FRAME_CASTBARS_SHOWN and not db.autoPosition then
                CastingBarFrame:ClearAllPoints()
                CastingBarFrame:SetPoint(db.position[1], UIParent, db.position[2], db.position[3])
            end
        end)
        CastingBarFrame.CC_isHooked = true
    end

    if nonLSMBorders[db.castBorder] then
        CastingBarFrame.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
        CastingBarFrame.Flash:SetSize(db.width + 61, db.height + 51)
        CastingBarFrame.Flash:SetPoint("TOP", 0, 26)
    else
        CastingBarFrame.Flash:SetTexture(nil) -- Hide it by removing texture. SetAlpha() or Hide() wont work without messing with blizz code
    end

    CastingBarFrame.Text:ClearAllPoints()
    CastingBarFrame.Text:SetPoint(db.textPoint)
    CastingBarFrame.Text:SetJustifyH(db.textPoint)
    CastingBarFrame.Icon:ClearAllPoints()
    CastingBarFrame.Icon:SetShown(db.showIcon)

    if not db.autoPosition then
        CastingBarFrame.ignoreFramePositionManager = true
        if UIParentBottomManagedFrameContainer then
            UIParentBottomManagedFrameContainer:RemoveManagedFrame(PlayerCastingBarFrame)
        end
        CastingBarFrame:SetParent(UIParent) -- required for retail
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame:SetPoint(db.position[1], UIParent, db.position[2], db.position[3])
    else
        if _G.PLAYER_FRAME_CASTBARS_SHOWN then
            CastingBarFrame.ignoreFramePositionManager = true
            CastingBarFrame:ClearAllPoints()
            if PlayerFrame_AdjustAttachments then
                PlayerFrame_AdjustAttachments()
            end
        else
            if not isRetail then
                CastingBarFrame.ignoreFramePositionManager = false
            else
                CastingBarFrame.ignoreFramePositionManager = true
                UIParentBottomManagedFrameContainer:RemoveManagedFrame(PlayerCastingBarFrame)
                CastingBarFrame:SetParent(UIParent)
            end
            CastingBarFrame:ClearAllPoints()
            CastingBarFrame:SetPoint("BOTTOM", UIParent, 0, 150)
        end
    end

    self:SetCastbarStyle(CastingBarFrame, db, "player")
    self:SetCastbarFonts(CastingBarFrame, db)

    if not isRetail then
        hooksecurefunc("CastingBarFrame_OnLoad", ColorPlayerCastbar)
        C_Timer.After(GetTickTime(), ColorPlayerCastbar)
    else
        if PlayerCastingBarFrame.isTesting then
            PlayerCastingBarFrame:GetTypeInfo()
            PlayerCastingBarFrame:SetMinMaxValues(1, 2)
            PlayerCastingBarFrame:SetValue(1)
        end
    end
end

if isRetail then
    -- Modified code from Classic Frames, some parts might be redundant for us.
    -- This is mostly just quick *hacks* to get the player castbar customizations working for retail after patch 10.0.0.
    hooksecurefunc(PlayerCastingBarFrame, 'UpdateShownState', function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        if self.barType ~= "empowered" then
            self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            self.Spark:SetSize(32, 32)
            self.Spark:ClearAllPoints()
            self.Spark:SetPoint("CENTER", 0, 2)
            self.Spark:SetBlendMode("ADD")
            if self.channeling then
                self.Spark:Hide()
            end
            ClassicCastbars:SkinPlayerCastbar()
        end
    end)

    hooksecurefunc(PlayerCastingBarFrame, "FinishSpell", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        self:SetStatusBarColor(unpack(db.statusColorSuccess))
    end)

    hooksecurefunc(PlayerCastingBarFrame, "SetAndUpdateShowCastbar", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end)

    hooksecurefunc(PlayerCastingBarFrame, "PlayInterruptAnims", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        self.Spark:Hide()
    end)

    hooksecurefunc(PlayerCastingBarFrame, "GetTypeInfo", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        if ( self.barType == "interrupted") then
            self:SetValue(100)
            self:SetStatusBarColor(unpack(db.statusColorFailed))
        elseif (self.barType == "channel") then
            self:SetStatusBarColor(unpack(db.statusColorChannel))
        elseif (self.barType == "uninterruptable") then
            self:SetStatusBarColor(unpack(db.statusColorUninterruptible))
        else
            self:SetStatusBarColor(unpack(db.statusColor))
        end
        self.Background:SetColorTexture(unpack(db.statusBackgroundColor))
    end)

    hooksecurefunc(PlayerCastingBarFrame, "PlayFinishAnim", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        if self.barType ~= "empowered" then
            self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self:SetStatusBarColor(unpack(db.statusColorSuccess))
        end
    end)

    hooksecurefunc(PlayerCastingBarFrame.Flash, "SetAtlas", function(self)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        local statusbar = self:GetParent()
        if (statusbar.barType == "empowered") then
            self:SetVertexColor(0, 0, 0, 0)
        else
            self:SetVertexColor(self:GetParent():GetStatusBarColor())
        end
        if (PlayerCastingBarFrame.attachedToPlayerFrame) then
            self:SetSize(0,49)
            self:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small")
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", -23, 20)
            self:SetPoint("TOPRIGHT", 23, 20)
            self:SetBlendMode("ADD")
        else
            self:ClearAllPoints();
            self:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash");
            self:SetWidth(256);
            self:SetHeight(64);
            self:SetPoint("TOP", 0, 28);
            self:SetBlendMode("ADD")
        end
        ClassicCastbars:SkinPlayerCastbar()
    end)

    hooksecurefunc(PlayerCastingBarFrame, "SetLook", function(self, look)
        local db = ClassicCastbars.db and ClassicCastbars.db.player
        if not db or not db.enabled then return end

        if (look == "CLASSIC") then
            self:SetWidth(195);
            self:SetHeight(13);
            self.playCastFX = false
            self.Background:SetColorTexture(0, 0, 0, 0.5)
            self.Border:ClearAllPoints();
            self.Border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border");
            self.Border:SetWidth(256);
            self.Border:SetHeight(64);
            self.Border:SetPoint("TOP", 0, 28);
            self.TextBorder:Hide()
            self.Text:ClearAllPoints()
            self.Text:SetPoint("TOP", 0, 5)
            self.Text:SetWidth(185)
            self.Text:SetHeight(16)
            self.Text:SetFontObject("GameFontHighlight")
            self.Spark.offsetY = 2;
            ClassicCastbars:SkinPlayerCastbar()
        end
    end)
end
