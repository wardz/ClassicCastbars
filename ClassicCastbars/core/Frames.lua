local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local ClassicCastbars = _G.ClassicCastbars

local nonLSMBorders = {
    ["Interface\\CastingBar\\UI-CastingBar-Border-Small"] = true,
    ["Interface\\CastingBar\\UI-CastingBar-Border"] = true,
    [130873] = true,
    [130874] = true,
}

function ClassicCastbars:SetTargetCastbarPosition(castbar, parentFrame)
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
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
    local spellName = castbar.castText or castbar.spellName or ""

    if castbar.icon == 136235 then -- unknown texture
        castbar.icon = 136243
    end
    castbar.Icon:SetTexture(castbar.icon)
    castbar.Text:ClearAllPoints()
    castbar.Text:SetPoint(db.textPoint)
    castbar.Text:SetJustifyH(db.textPoint)
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
        castbar.Icon:ClearAllPoints()
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
        castbar.Icon:ClearAllPoints()
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
    if db.showBorderShield and castbar.isUninterruptible then
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end
end

function ClassicCastbars:SetCastbarStyle(castbar, db, unitID)
    castbar:SetSize(db.width, db.height)
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

    castbar.Timer:SetShown(db.showTimer)
    if not db.showTimer then
        castbar.timerTextFormat = nil
    else
        castbar.timerTextFormat = db.showTotalTimer and "%.1f/%.1f" or "%.1f"
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

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" then
        castbar.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
    else
        castbar.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small")
    end

    castbar.Flash:ClearAllPoints()
    if db.showBorderShield and castbar.isUninterruptible then
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        castbar.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        castbar.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end

    local isDefaultBorder = nonLSMBorders[db.castBorder]
    if isDefaultBorder then
        castbar.Border:SetTexture(db.castBorder)
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

function ClassicCastbars:SetCastbarStatusColorsOnDisplay(castbar, db, unitID)
    castbar.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    if castbar.isChanneled then
        castbar:SetStatusBarColor(unpack(db.statusColorChannel))
    elseif castbar.isUninterruptible and unitID ~= "player" then
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
        castbar.Spark:SetAlpha(0)
        castbar:SetMinMaxValues(0, 1)

        if castbar.Border:GetAlpha() == 1 or castbar.isUninterruptible then
            if castbar.BorderShield:IsShown() or nonLSMBorders[castbar.Border:GetTexture() or ""] then
                -- TODO: flashColorSameAsStart?
                if castbar.isUninterruptible and unitID ~= "player" then
                    castbar.Flash:SetVertexColor(0.7, 0.7, 0.7, 1)
                elseif castbar.isChanneled then
                    castbar.Flash:SetVertexColor(0, 1, 0, 1)
                else
                    castbar.Flash:SetVertexColor(1, 1, 1, 1)
                end
                castbar.Flash:Show()
            end
        end

        if not castbar.isChanneled then
            if castbar.isUninterruptible and unitID ~= "player" then
                local r, g, b = unpack(self.db[self:GetUnitType(unitID)].statusColorUninterruptible)
                castbar:SetStatusBarColor(r, g, b)
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

    -- Check if cast expired
    if not castbar.isTesting then
        if (castbar.isChanneled and castbar.value <= 0) or (not castbar.isChanneled and castbar.value >= castbar.maxValue) then
            castbar.isActiveCast = false
            return
        end
    end

    local db = self.db[self:GetUnitType(unitID)]
    if not db then return end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    if castbar.animationGroup:IsPlaying() then
        castbar.animationGroup:Stop()
    end

    -- Note: since frames are recycled and we also allow having different styles
    -- between castbars for all the unitframes, we need to always update the style here
    -- incase it was modified to something else on last recycle
    self:SetCastbarStyle(castbar, db, unitID)
    self:SetCastbarIconAndText(castbar, db)
    self:SetCastbarFonts(castbar, db)
    self:SetCastbarStatusColorsOnDisplay(castbar, db, unitID)

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

    if castbar.timerTextFormat then
        if castbar.isChanneled then
            castbar.Timer:SetFormattedText(castbar.timerTextFormat, castbar.value, castbar.maxValue)
        else
            castbar.Timer:SetFormattedText(castbar.timerTextFormat, castbar.maxValue - castbar.value, castbar.maxValue)
        end
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
        castbar.isActiveCast = false
        castbar.animationGroup:Stop()
        castbar:Hide()
    else
        self:SetFinishCastStyle(castbar, unitID)

        if not castbar.animationGroup:IsPlaying() then
            castbar.fade:SetStartDelay(0.1)
            if castbar.isActiveCast then
                if castbar.isInterrupted or castbar.isFailed then
                    castbar.fade:SetStartDelay(unitID == "player" and 1 or 0.6)
                end
            end

            castbar.isActiveCast = false
            castbar.fade:SetDuration(castbar.isActiveCast and castbar.isInterrupted and 1 or 0.4)
            castbar.animationGroup:Play()
        end
    end
end
