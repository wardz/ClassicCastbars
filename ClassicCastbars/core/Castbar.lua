local _, namespace = ...
local AnchorManager = namespace.AnchorManager

local CastbarMixin = {}
_G.ClassicCastbarsFrameMixin = CastbarMixin -- global for xml mixin

local nonLSMBorders = {
    ["Interface\\CastingBar\\UI-CastingBar-Border-Small"] = true,
    ["Interface\\CastingBar\\UI-CastingBar-Border"] = true,
    [130873] = true,
    [130874] = true,
}

local textureFrameLevels = {
    ["Interface\\CHARACTERFRAME\\UI-Party-Border"] = 1,
    ["Interface\\Tooltips\\ChatBubble-Backdrop"] = 1,
}

namespace.FramePoolResetterFunc = function(pool, castbar)
    if castbar.FadeOutAnim:IsPlaying() then
        castbar.FadeOutAnim:Stop()
    end

    castbar:Hide()
    castbar:SetParent(nil)
    castbar:ClearAllPoints()
    castbar.isTesting = false
    castbar.isActiveCast = false
    castbar.unitID = nil
    castbar.parent = nil

    if castbar.tooltip then
        castbar:EnableMouse(false)
        castbar.tooltip:Hide()
    end
end

function CastbarMixin:SetTargetOrFocusCastbarPosition(parentFrame)
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

        self:SetPoint("TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, pointY - 4)
    else
        if parentFrame == _G.TargetFrame or parentFrame == _G.FocusFrame then
            -- copy paste from wotlk wow ui source
            if parentFrame.haveToT then
                if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
                    self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -21)
                else
                    self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                end
            elseif parentFrame.haveElite then
                if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
                    self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -5)
                else
                    self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                end
            else
                if ((not parentFrame.buffsOnTop) and parentFrame.auraRows > 0) then
                    self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15)
                else
                    self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 7)
                end
            end
        else -- unknown parent frame
            local auraRows = parentFrame.auraRows or 0

            if parentFrame.buffsOnTop or auraRows <= 1 then
                self:SetPoint("CENTER", parentFrame, -18, -75)
            else
                if self.BorderShield:IsShown() then
                    self:SetPoint("CENTER", parentFrame, -18, max(min(-75, -45 * auraRows), -200))
                else
                    self:SetPoint("CENTER", parentFrame, -18, max(min(-75, -41 * auraRows), -200))
                end
            end
        end
    end
end

function CastbarMixin:SetCastbarIcon(db)
    self.Icon:SetTexture(self.iconTexturePath)
    self.Icon:SetSize(db.iconSize, db.iconSize)
    self.Icon:SetShown(db.showIcon)
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("LEFT", (db.iconPositionX - db.iconSize), db.iconPositionY)

    --[[local unitType = ClassicCastbars:GetUnitType(unitID)
    if unitType == "nameplate" then
        self.Icon:SetPoint("LEFT", (db.iconPositionX - db.iconSize), db.iconPositionY + 2)
    elseif unitType == "party" then
        self.Icon:SetPoint("LEFT", (db.iconPositionX - db.iconSize) + 2, db.iconPositionY + 2)
    else
        self.Icon:SetPoint("LEFT", (db.iconPositionX - db.iconSize) + 2, db.iconPositionY + 2)
    end]]

    if db.hideIconBorder then
        self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        self.Icon:SetTexCoord(0, 1, 0, 1)
    end
end

function CastbarMixin:SetCastbarText(db)
    self.Text:SetFont(db.castFont, db.castFontSize, db.textOutline)
    self.Text:SetJustifyH(db.textPoint)
    self.Text:SetWidth(db.width - 10) -- ensures text gets truncated
    self.Text:SetShadowColor(0, 0, 0, db.textOutline == "" and 1 or 0)
    self.Text:SetTextColor(unpack(db.textColor))
    self.Text:ClearAllPoints()
    self.Text:SetText(self.castText)

    local yOff = db.textPositionY
    if db.showBorderShield and self.isUninterruptible then
        yOff = yOff + 2
    end
    self.Text:SetPoint(db.textPoint, db.textPositionX, yOff)
end

function CastbarMixin:SetCastbarTimer(db)
    self.Timer:SetShown(db.showTimer)

    if db.showTimer then
        local yOff = (db.showBorderShield and self.isUninterruptible) and 2 or 0
        self.timerTextFormat = db.showTotalTimer and "%.1f/%.1f" or "%.1f"
        self.Timer:SetFont(db.castFont, db.castFontSize, db.textOutline)
        self.Timer:SetTextColor(unpack(db.textColor))
        self.Timer:SetShadowColor(0, 0, 0, db.textOutline == "" and 1 or 0)
        self.Timer:ClearAllPoints()
        self.Timer:SetPoint("RIGHT", (self.castText:len() >= 19) and 30 or -6, yOff)

        if self.isChanneled then -- update immediately here for testmode
            self.Timer:SetFormattedText(self.timerTextFormat, self.value, self.maxValue)
        else
            self.Timer:SetFormattedText(self.timerTextFormat, self.maxValue - self.value, self.maxValue)
        end
    end
end

function CastbarMixin:SetCastbarBorder(db)
    local showingShield = db.showBorderShield and self.isUninterruptible
    local isDefaultBorder = nonLSMBorders[db.castBorder]
    self.Border:SetShown(not showingShield and isDefaultBorder)
    self.BorderFrameLSM:SetShown(not showingShield and not isDefaultBorder)

    if isDefaultBorder then
        local width, height = self:GetWidth() * db.borderPaddingWidth, self:GetHeight() * db.borderPaddingHeight
        self.Border:ClearAllPoints()
        self.Border:SetPoint("TOPLEFT", width, height)
        self.Border:SetPoint("BOTTOMRIGHT", -width, -height)

        self.Border:SetTexture(db.castBorder)
        self.Border:SetVertexColor(unpack(db.borderColor))
        self.Border:SetAlpha(db.borderColor[4])
    else -- LibSharedMedia
        self.BorderFrameLSM:SetBackdrop({
            edgeFile = db.castBorder,
            tile = true, tileSize = db.edgeSizeLSM,
            edgeSize = db.edgeSizeLSM,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.BorderFrameLSM:SetAlpha(db.borderColor[4])
        self.BorderFrameLSM:SetFrameLevel(textureFrameLevels[db.castBorder] or self:GetFrameLevel() + 1)
        self.BorderFrameLSM:SetBackdropBorderColor(unpack(db.borderColor))
    end
end

function CastbarMixin:SetCastbarShield(db)
    local showingShield = db.showBorderShield and self.isUninterruptible
    self.IconShield:SetShown(showingShield and db.showIcon)
    self.BorderShield:SetShown(showingShield)

    -- TODO: should be an easier way to do this
    if showingShield then
        local width, height = self:GetWidth() * db.borderPaddingWidth + 0.3, self:GetHeight() * db.borderPaddingHeight + 0.3
        self.BorderShield:SetTexCoord(0.16, 0, 0.118, 1, 1, 0, 1, 1) -- cut left side of texture away
        self.BorderShield:ClearAllPoints()
        self.BorderShield:SetPoint("TOPLEFT", width-5, height+1) -- texture offsets, just doing "1" and "-1" doesnt work here
        self.BorderShield:SetPoint("BOTTOMRIGHT", -width+(width*0.15), -height + 4)

        self.IconShield:ClearAllPoints()
        self.IconShield:SetPoint("LEFT", self.Icon, -0.44 * db.iconSize, 0)
        self.IconShield:SetSize(db.iconSize * 3, db.iconSize * 3)
    end
end

function CastbarMixin:RefreshBorderShield(unitID)
    local db = ClassicCastbars.db[ClassicCastbars:GetUnitType(unitID)]
    if not db then return end

    -- Update displays related to border shield
    self:SetCastbarShield(db)
    self:SetCastbarText(db)
    self:SetCastbarStatusColors(db, unitID)
    self:SetCastbarFlash(db)
end

function CastbarMixin:SetCastbarFlash(db, unitID)
    local showingShield = db.showBorderShield and self.isUninterruptible
    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" then
        self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
    else
        self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small")
    end

    -- TODO: most be an easier way to do this
    self.Flash:ClearAllPoints()
    if db.showBorderShield and self.isUninterruptible then
        self.Flash:SetPoint("TOPLEFT", ceil(-db.width / 5.45) + 5, db.height+6)
        self.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 5.45) - 5, -db.height-1)
    else
        self.Flash:SetPoint("TOPLEFT", ceil(-db.width / 6.25), db.height)
        self.Flash:SetPoint("BOTTOMRIGHT", ceil(db.width / 6.25), -db.height)
    end

    -- TODO: flashColorSameAsStart?
    if self.isUninterruptible and unitID ~= "player" then
        self.Flash:SetVertexColor(0.7, 0.7, 0.7, 1)
    elseif self.isChanneled then
        self.Flash:SetVertexColor(0, 1, 0, 1)
    else
        self.Flash:SetVertexColor(1, 1, 1, 1)
    end

    if not self.isCastComplete then
        self.Flash:Hide()
    else
        self.Flash:SetShown(nonLSMBorders[db.castBorder] or showingShield)
    end
end

function CastbarMixin:SetCastbarSpark(db)
    local sparkPosition = (self.value / self.maxValue) * (self.currWidth or self:GetWidth())
    self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, 0)
    self.Spark:SetHeight(db.height * 2.1)
    self.Spark:SetShown(db.showSpark and not self.isChanneled)
end

function CastbarMixin:SetCastbarStatusColors(db, unitID)
    if self.isCastComplete then
        if not self.isChanneled and not self.isUninterruptible then
            self:SetStatusBarColor(unpack(db.statusColorSuccess, 1, 3)) -- Skipping alpha channel as it messes with fade out animations
        end
    elseif self.isInterrupted or self.isFailed then
        self:SetStatusBarColor(unpack(db.statusColorFailed, 1, 3))
    elseif self.isChanneled then
        self:SetStatusBarColor(unpack(db.statusColorChannel, 1, 3))
    elseif self.isUninterruptible and unitID ~= "player" then
        self:SetStatusBarColor(unpack(db.statusColorUninterruptible, 1, 3))
    else
        self:SetStatusBarColor(unpack(db.statusColor, 1, 3))
    end
end

-- Note: since frames are recycled and we also allow having different styles
-- between castbars for all the unitframes, we need to always update the style here
-- incase it was modified to something else on last recycle.
function CastbarMixin:ApplyCastbarStyle(parentFrame, db, unitID)
    self.Background:SetColorTexture(unpack(db.statusBackgroundColor))
    self:SetSize(db.width, db.height)
    self:SetStatusBarTexture(db.castStatusBar)
    self:SetFrameStrata(db.frameStrata)
    self:SetFrameLevel(db.frameLevel)
    self:SetIgnoreParentAlpha(db.ignoreParentAlpha)
    self:EnableMouse(self.isTesting)
    self:SetMinMaxValues(0, self.maxValue)
    self:SetValue(self.value)
    self:SetAlpha(1)
    self:ClearAllPoints()
    self:SetParent(parentFrame)
    self:SetCastbarStatusColors(db, unitID)
    self:SetCastbarIcon(db)
    self:SetCastbarText(db)
    self:SetCastbarTimer(db)
    self:SetCastbarBorder(db)
    self:SetCastbarShield(db)
    self:SetCastbarFlash(db)
    self:SetCastbarSpark(db)
    -- TODO: castbar ticks, evoker playercastbar

    if db.autoPosition and (unitID == "target" or unitID == "focus") then
        self:SetTargetOrFocusCastbarPosition(parentFrame)
    else
        -- TODO: autoPosition player?
        self:SetPoint(db.position[1], parentFrame, db.position[2], db.position[3])
    end
end

function CastbarMixin:UpdateCastbarStyleFinish(db, unitID)
    self:SetCastbarStatusColors(db, unitID)
    self:SetCastbarFlash(db, unitID)
    self:SetMinMaxValues(0, 1)
    self:SetValue(self.isChanneled and 0 or 1)
    self.Text:SetText(self.isInterrupted and _G.INTERRUPTED or self.isFailed and _G.FAILED or self.castText)
    self.Spark:Hide()
end

function CastbarMixin:DisplayCastbar(unitID)
    if not self.isActiveCast or self.value == nil then return end
    if not self.isTesting and self.isChanneled and self.value <= 0 then return end
    if not self.isTesting and not self.isChanneled and self.value >= self.maxValue then return end

    local db = ClassicCastbars.db[ClassicCastbars:GetUnitType(unitID)]
    if not db then return end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    if self.isTesting then
        self.maxValue = 10
        self.value = 5
    end

    if self.FadeOutAnim:IsPlaying() then
        self.FadeOutAnim:Stop()
    end

    -- TODO: self.unitID = unitID?
    self:ApplyCastbarStyle(parentFrame, db, unitID)
    self:Show()
end

function CastbarMixin:HideCastbarNoFade()
    if self.isTesting then return end

    self.isActiveCast = false
    self.FadeOutAnim:Stop()
    self:Hide()
end

function CastbarMixin:HideCastbar(unitID)
    if self.isTesting then return end
    if self.FadeOutAnim:IsPlaying() then return end

    local db = ClassicCastbars.db[ClassicCastbars:GetUnitType(unitID)]
    if not db then return self:HideCastbarNoFade() end -- sanity check

    -- if self.activeCast then
    self:UpdateCastbarStyleFinish(db, unitID)
    --end

    self.FadeOutAnim.Alpha:SetStartDelay(0.1)
    if self.isActiveCast then
        if self.isInterrupted or self.isFailed then
            self.FadeOutAnim.Alpha:SetStartDelay(unitID == "player" and 1 or 0.6)
        end
    end

    self.isActiveCast = false
    self.FadeOutAnim.Alpha:SetDuration(self.isActiveCast and self.isInterrupted and 1 or 0.4)
    self.FadeOutAnim:Play()
end
