local _, namespace = ...
local addon = ClassicCastbars
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager
local activeFrames = addon.activeFrames

local GetSchoolString = _G.GetSchoolString
local strformat = _G.string.format
local unpack = _G.unpack
local min = _G.math.min
local max = _G.math.max
local ceil = _G.math.ceil
local InCombatLockdown = _G.InCombatLockdown

local nonLSMBorders = {
    ["Interface\\CastingBar\\UI-CastingBar-Border-Small"] = true,
    ["Interface\\CastingBar\\UI-CastingBar-Border"] = true,
    [130873] = true,
}

local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

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

function addon:GetCastbarFrame(unitID)
    -- PoolManager:DebugInfo()
    if unitID == "player" then return end -- no point returning CastingBarFrame here, we only skin it, not replace it and its events

    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    activeFrames[unitID] = PoolManager:AcquireFrame()

    return activeFrames[unitID]
end

function addon:SetTargetCastbarPosition(castbar, parentFrame)
    if not isClassicEra and (parentFrame == _G.TargetFrame or parentFrame == _G.FocusFrame) then
        if ( parentFrame.haveToT ) then
            if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
                castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -21 )
            else
                castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
            end
        elseif ( parentFrame.haveElite ) then
            if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
                castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -5 )
            else
                castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
            end
        else
            if ( (not parentFrame.buffsOnTop) and parentFrame.auraRows > 0 ) then
                castbar:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
            else
                castbar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 7 )
            end
        end
    else -- for classic era or unknown parent frame
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

function addon:SetCastbarIconAndText(castbar, cast, db)
    local spellName = cast.spellName
    if not castbar.isTesting and castbar.Text:GetText() == spellName then return end

    if cast.icon == 136235 then -- unknown texture
        cast.icon = 136243
    end
    castbar.Text:ClearAllPoints()
    castbar.Text:SetPoint(db.textPoint)
    castbar.Text:SetJustifyH(db.textPoint)
    castbar.Icon:SetTexture(cast.icon)
    castbar.Text:SetText(spellName)

    -- Move timer position depending on spellname length
    if db.showTimer then
        local yOff = 0
        if db.showBorderShield and cast.isUninterruptible then
            yOff = yOff + 2
        end
        castbar.Timer:SetPoint("RIGHT", castbar, (spellName:len() >= 19) and 30 or -6, yOff)
    end
end

function addon:SetBorderShieldStyle(castbar, cast, db, unitID)
    if db.showBorderShield and cast and cast.isUninterruptible then
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
            castbar.Border:SetAlpha(1)
        else
            castbar.BorderFrameLSM:SetAlpha(1)
        end
        castbar.BorderShield:Hide()
        if castbar.IconShield then
            castbar.IconShield:Hide()
        end
        castbar.Icon:SetPoint("LEFT", castbar, db.iconPositionX - db.iconSize, db.iconPositionY)
    end
end

function addon:SetCastbarStyle(castbar, cast, db, unitID)
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

    if cast and cast.isChanneled then
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
    if cast and cast.isUninterruptible then
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end

    local isDefaultBorder = nonLSMBorders[db.castBorder]
    if isDefaultBorder then
        castbar.Border:SetAlpha(1)
        if castbar.BorderFrameLSM then
            -- Hide LSM border frame if it exists
            castbar.BorderFrameLSM:SetAlpha(0)
        end

        --[[if WOW_PROJECT_ID == 1 then -- is Dragonflight / retail
            castbar.Border:ClearAllPoints()
            castbar.Border:SetPoint("TOPLEFT", -1, 1)
            castbar.Border:SetPoint("BOTTOMRIGHT", 1, -1)
        else]]
            -- Update border to match castbar size
            local width, height = castbar:GetWidth() * db.borderPaddingWidth, castbar:GetHeight() * db.borderPaddingHeight
            castbar.Border:ClearAllPoints()
            castbar.Border:SetPoint("TOPLEFT", width, height)
            castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
        --end
    else
        -- Using border sat by LibSharedMedia
        self:SetLSMBorders(castbar, cast, db)
    end

    self:SetBorderShieldStyle(castbar, cast, db, unitID)
end

local textureFrameLevels = {
    ["Interface\\CHARACTERFRAME\\UI-Party-Border"] = 1,
    ["Interface\\Tooltips\\ChatBubble-Backdrop"] = 1,
}

function addon:SetLSMBorders(castbar, cast, db)
    -- Create new frame to contain our LSM backdrop
    if not castbar.BorderFrameLSM then
        castbar.BorderFrameLSM = CreateFrame("Frame", nil, castbar, _G.BackdropTemplateMixin and "BackdropTemplate")
        castbar.BorderFrameLSM:SetPoint("TOPLEFT", castbar, -2, 2)
        castbar.BorderFrameLSM:SetPoint("BOTTOMRIGHT", castbar, 2, -2)
    end

    -- Apply backdrop if it isn't already active
    if castbar.BorderFrameLSM.currentTexture ~= db.castBorder or castbar:GetHeight() ~= castbar.BorderFrameLSM.currentHeight then
        castbar.BorderFrameLSM:SetBackdrop({
            edgeFile = db.castBorder,
            tile = false, tileSize = 0,
            edgeSize = castbar:GetHeight(),
        })
        castbar.BorderFrameLSM.currentTexture = db.castBorder
        castbar.BorderFrameLSM.currentHeight = castbar:GetHeight()
    end

    castbar.Border:SetAlpha(0) -- hide default border
    castbar.BorderFrameLSM:SetAlpha(1)
    castbar.BorderFrameLSM:SetFrameLevel(textureFrameLevels[db.castBorder] or castbar:GetFrameLevel() + 1)
    castbar.BorderFrameLSM:SetBackdropBorderColor(unpack(db.borderColor))
end

function addon:SetCastbarFonts(castbar, cast, db)
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
    if db.showBorderShield and cast.isUninterruptible then
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

function addon:CreateFadeAnimationGroup(frame)
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

function addon:SetCastbarStatusColorsOnDisplay(castbar, cast, db)
    castbar.Background = castbar.Background or GetStatusBarBackgroundTexture(castbar)
    castbar.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    if cast.isChanneled then
        castbar:SetStatusBarColor(unpack(db.statusColorChannel))
    elseif cast.isUninterruptible then
        castbar:SetStatusBarColor(unpack(db.statusColorUninterruptible))
    else
        castbar:SetStatusBarColor(unpack(db.statusColor))
    end
end

function addon:DisplayCastbar(castbar, unitID)
    local cast = castbar._data
    if not cast then return end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    local db = self.db[self:GetUnitType(unitID)]

    castbar.animationGroup = castbar.animationGroup or self:CreateFadeAnimationGroup(castbar)
    if castbar.animationGroup:IsPlaying() then
        castbar.animationGroup:Stop()
    end

    -- Note: since frames are recycled and we also allow having different styles
    -- between castbars for all the unitframes, we need to always update the style here
    -- incase it was modified to something else on last recycle
    self:SetCastbarStyle(castbar, cast, db, unitID)
    self:SetCastbarIconAndText(castbar, cast, db)
    self:SetCastbarFonts(castbar, cast, db)
    self:SetCastbarStatusColorsOnDisplay(castbar, cast, db)

    if unitID == "target" and self.db.target.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    elseif not isClassicEra and unitID == "focus" and self.db.focus.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    else
        castbar:SetPoint(db.position[1], parentFrame, db.position[2], db.position[3])
    end

    if not castbar.isTesting then
        castbar:SetMinMaxValues(0, cast.maxValue)
        castbar:SetValue(0)
        castbar.Spark:SetPoint("CENTER", castbar, "LEFT", 0, 0)
    end

    castbar:SetParent(parentFrame)
    castbar.Flash:Hide()
    castbar:SetAlpha(1)
    castbar:Show()
end

function addon:HideCastbar(castbar, unitID, skipFadeOut)
    if skipFadeOut then
        if castbar.animationGroup then
            castbar.animationGroup:Stop()
        end
        castbar.BorderShield:Hide()
        castbar:SetAlpha(0)
        castbar:Hide()
        return
    end

    if castbar:GetAlpha() <= 0 then return end

    local cast = castbar._data
    if cast then
        if cast.isInterrupted or cast.isFailed then
            if cast.isInterrupted and cast.interruptedSchool and self.db[self:GetUnitType(unitID)].showInterruptSchool then
                castbar.Text:SetText(strformat(_G.LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL, GetSchoolString(cast.interruptedSchool) or ""))
            else
                castbar.Text:SetText(cast.isInterrupted and _G.INTERRUPTED or _G.FAILED)
            end
            castbar:SetStatusBarColor(unpack(self.db[self:GetUnitType(unitID)].statusColorFailed))
            castbar:SetMinMaxValues(0, 1)
            castbar:SetValue(1)
            castbar.Spark:SetAlpha(0)
        end

        if cast.isCastComplete then -- SPELL_CAST_SUCCESS
            if castbar.Border:GetAlpha() == 1 or cast.isUninterruptible then
                if castbar.BorderShield:IsShown() or nonLSMBorders[castbar.Border:GetTextureFilePath() or ""] or nonLSMBorders[castbar.Border:GetTexture() or ""] then
                    if cast.isUninterruptible then
                        castbar.Flash:SetVertexColor(0.7, 0.7, 0.7, 1)
                    elseif cast.isChanneled then
                        castbar.Flash:SetVertexColor(0, 1, 0, 1)
                    else
                        castbar.Flash:SetVertexColor(1, 1, 1, 1)
                    end
                    castbar.Flash:Show()
                end
            end

            castbar.Spark:SetAlpha(0)
            castbar:SetMinMaxValues(0, 1)
            if not cast.isChanneled then
                if cast.isUninterruptible then
                    castbar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
                else
                    castbar:SetStatusBarColor(unpack(self.db[self:GetUnitType(unitID)].statusColorSuccess))
                end
                castbar:SetValue(1)
            else
                castbar:SetValue(0)
            end
        end
    end

    if castbar.fade then
        if not castbar.animationGroup:IsPlaying() then
            castbar.fade:SetStartDelay(0.1) -- reset
            if cast then
                if cast.isInterrupted or cast.isFailed then
                    castbar.fade:SetStartDelay(0.6)
                end
            end

            if isClassicEra then
                castbar.fade:SetDuration(cast and cast.isInterrupted and 1 or 0.3)
            else
                castbar.fade:SetDuration(0.6)
            end
            castbar.animationGroup:Play()
        end
    end
end

--------------------------------------------------------------
-- Player & Focus Castbar Stuff
--------------------------------------------------------------

local function ColorPlayerCastbar()
    local db = addon.db.player
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
function addon:SkinPlayerCastbar()
    local db = self.db.player
    if not db.enabled then return end

    if not CastingBarFrame.showCastbar or not CastingBarFrame:IsEventRegistered("UNIT_SPELLCAST_START") then
        print("|cFFFF0000[ClassicCastbars] Incompatibility detected for player castbar. You most likely have another addon disabling the default Blizzard castbar.|r") -- luacheck: ignore
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
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame:SetPoint(db.position[1], UIParent, db.position[2], db.position[3])
    else
        if _G.PLAYER_FRAME_CASTBARS_SHOWN then
            CastingBarFrame.ignoreFramePositionManager = true
            CastingBarFrame:ClearAllPoints()
            PlayerFrame_AdjustAttachments()
        else
            CastingBarFrame.ignoreFramePositionManager = false
            CastingBarFrame:ClearAllPoints()
            CastingBarFrame:SetPoint("BOTTOM", UIParent, 0, 150)
        end
    end

    self:SetCastbarStyle(CastingBarFrame, nil, db, "player")
    self:SetCastbarFonts(CastingBarFrame, nil, db)
    hooksecurefunc("CastingBarFrame_OnLoad", ColorPlayerCastbar)
    C_Timer.After(GetTickTime(), ColorPlayerCastbar)
end

if isClassicEra then
    function addon:CreateOrUpdateSecureFocusButton(text)
        if not self.FocusButton then
            -- Create an invisible secure click trigger above the nonsecure castbar frame
            self.FocusButton = CreateFrame("Button", "FocusCastbar", UIParent, "SecureActionButtonTemplate")
            self.FocusButton:SetAttribute("type", "macro")
        end

        local db = ClassicCastbars.db.focus
        self.FocusButton:SetPoint(db.position[1], UIParent, db.position[2], db.position[3] + 30)
        self.FocusButton:SetSize(db.width + 5, db.height + 35)

        self.FocusButton:SetAttribute("macrotext", "/targetexact " .. text)
        self.FocusFrame.Text:SetText(text)
        self.FocusFrame:EnableMouse(true)
        self.FocusButton:EnableMouse(true)
    end

    local NewTimer = _G.C_Timer.NewTimer
    local focusTargetTimer -- time for changing focus
    local focusTargetResetTimer -- timer for clearing focus

    local function ClearFocusTarget()
        if not InCombatLockdown() then
            addon.FocusButton:SetAttribute("macrotext", "")
            addon.FocusFrame:EnableMouse(false)
            addon.FocusButton:EnableMouse(false)
        else
            focusTargetResetTimer = NewTimer(4, ClearFocusTarget)
        end
    end

    function addon:ClearFocus()
        if self.FocusFrame then
            self.FocusFrame.Text:SetText("")
        end

        if self.FocusButton then
            if not InCombatLockdown() then
                self.FocusButton:SetAttribute("macrotext", "")
                self.FocusFrame:EnableMouse(false)
                self.FocusButton:EnableMouse(false)
            else
                -- If we're in combat try to check every 4s if we left combat and can update secure frame
                focusTargetResetTimer = NewTimer(4, ClearFocusTarget)
            end
        end
    end

    function addon:SetFocusDisplay(text, unitID)
        if focusTargetTimer and not focusTargetTimer:IsCancelled() then
            focusTargetTimer:Cancel()
            focusTargetTimer = nil
        end
        if focusTargetResetTimer and not focusTargetResetTimer:IsCancelled() then
            focusTargetResetTimer:Cancel()
            focusTargetResetTimer = nil
        end

        if not text then
            return self:ClearFocus()
        end

        if not self.FocusFrame then
            -- Create a new unsecure frame to display focus text. We dont reuse the castbar frame as we want to
            -- display this text even when the castbar is hidden
            self.FocusFrame = CreateFrame("Frame", nil, UIParent)
            self.FocusFrame:SetSize(ClassicCastbars.db.focus.width + 5, ClassicCastbars.db.focus.height + 35)
            self.FocusFrame.Text = self.FocusFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
            self.FocusFrame.Text:SetPoint("CENTER", self.FocusFrame, 0, 20)
        end

        if UnitIsPlayer(unitID) then
            self.FocusFrame.Text:SetTextColor(RAID_CLASS_COLORS[select(2, UnitClass(unitID))]:GetRGBA())
        else
            self.FocusFrame.Text:SetTextColor(1, 0.819, 0, 1)
        end

        local isInCombat = InCombatLockdown()
        if not isInCombat then
            self:CreateOrUpdateSecureFocusButton(text)
        else
            -- If we're in combat try to check every 4s if we left combat and can update secure frame
            local function UpdateFocusTarget()
                if not InCombatLockdown() then
                    addon:CreateOrUpdateSecureFocusButton(text)
                else
                    focusTargetTimer = NewTimer(4, UpdateFocusTarget)
                end
            end

            focusTargetTimer = NewTimer(4, UpdateFocusTarget)
        end

        -- HACK: quickly create the focus castbar if it doesnt exist and hide it.
        -- This is just to make anchoring easier for self.FocusFrame on first usage
        if not activeFrames.focus then
            local pos = ClassicCastbars.db.focus.position
            local castbar = self:GetCastbarFrame("focus")
            castbar:ClearAllPoints()
            castbar:SetParent(UIParent)
            castbar:SetPoint(pos[1], UIParent, pos[2], pos[3])
        end

        self.FocusFrame.Text:SetText(isInCombat and text .. " (|cffff0000P|r)" or text)
        self.FocusFrame:SetAllPoints(activeFrames.focus)
    end
end
