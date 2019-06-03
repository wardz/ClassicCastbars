local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager

local addon = namespace.addon
local activeFrames = addon.activeFrames

function addon:GetCastbarFrame(unitID)
    -- PoolManager:DebugInfo()

    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    -- store reference, refs are deleted on frame recycled.
    -- This allows us to not have to Release & Acquire a frame everytime a
    -- castbar is shown/hidden for the *same* unit
    activeFrames[unitID] = PoolManager:AcquireFrame()

    return activeFrames[unitID]
end

function addon:SetTargetCastbarPosition(castbar, parentFrame)
    if not self.db.target.autoPosition then
        -- Auto position is turned off, set pos from user cfg instead
        local pos = self.db.target.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        return
    end

    -- Set position based on aura amount & targetframe type
    local auraRows = parentFrame.auraRows or 0
    if parentFrame.haveToT or parentFrame.haveElite then
        if parentFrame.buffsOnTop or auraRows <= 1 then
            castbar:SetPoint("CENTER", parentFrame, -18, -75)
        else
            castbar:SetPoint("CENTER", parentFrame, -18, -100)
        end
    else
        if not parentFrame.buffsOnTop and auraRows > 0 then
            castbar:SetPoint("CENTER", parentFrame, -18, -100)
        else
            castbar:SetPoint("CENTER", parentFrame, -18, -50)
        end
    end
end

function addon:SetCastbarIconAndText(castbar, cast, db)
    local spellName = cast.spellName
    if db.showSpellRank and cast.spellRank then
        spellName = spellName .. " (" .. cast.spellRank .. ")"
    end

    -- Update text + icon if it has changed
    if castbar.Text:GetText() ~= spellName then
        castbar.Icon:SetTexture(cast.icon)
        castbar.Text:SetText(spellName)

        -- Move timer position depending on spellname length
        if db.showTimer then
            castbar.Timer:SetPoint("RIGHT", castbar, (spellName:len() >= 19) and 20 or -6, 0)
        end
    end
end

function addon:SetCastbarStyle(castbar, cast, db)
    castbar:SetSize(db.width, db.height)
    castbar.Timer:SetShown(db.showTimer)
    castbar:SetStatusBarTexture(db.castStatusBar)

    if db.simpleStyle then
        castbar.Border:SetAlpha(0)
        castbar.Icon:SetSize(db.height, db.height)
        castbar.Icon:SetPoint("LEFT", castbar, -db.height, 0)
        castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        return
    end

    castbar.Icon:SetSize(db.iconSize, db.iconSize)
    castbar.Icon:SetPoint("LEFT", castbar, -db.iconSize - 7, 0)
    castbar.Icon:SetTexCoord(0, 1, 0, 1)

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small" then
        castbar.Border:SetAlpha(1)
        if castbar.BorderFrame then
            castbar.BorderFrame:SetAlpha(0)
        end

        -- Update border to match castbar size
        local width, height = castbar:GetWidth() * 1.16, castbar:GetHeight() * 1.16
        castbar.Border:SetPoint("TOPLEFT", width, height)
        castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
    else
        -- LSM uses backdrop for borders instead of normal textures.
        castbar.Border:SetAlpha(0)
        if not castbar.BorderFrame then
            castbar.BorderFrame = CreateFrame("Frame", nil, castbar)
            castbar.BorderFrame:SetPoint("TOPLEFT", castbar, -2, 2)
            castbar.BorderFrame:SetPoint("BOTTOMRIGHT", castbar, 2, -2)
        end

        -- TODO: should be a better way to handle this
        if db.castBorder == "Interface\\CHARACTERFRAME\\UI-Party-Border" or db.castBorder == "Interface\\Tooltips\\ChatBubble-Backdrop" then
            castbar.BorderFrame:SetFrameLevel(1)
        else
            castbar.BorderFrame:SetFrameLevel(castbar:GetFrameLevel() + 1)
        end

        castbar.BorderFrame:SetAlpha(1)
        if castbar.BorderFrame.currentTexture ~= db.castBorder then
            castbar.BorderFrame:SetBackdrop({
                edgeFile = db.castBorder,
                tile = false, tileSize = 0,
                edgeSize = castbar:GetHeight(),
            })
            castbar.BorderFrame.currentTexture = db.castBorder
        end
    end
end

function addon:SetCastbarFonts(castbar, cast, db)
    local fontName, fontHeight = castbar.Text:GetFont()

    if fontName ~= db.castFont or db.castFontSize ~= fontHeight then
        castbar.Text:SetFont(db.castFont, db.castFontSize)
        castbar.Timer:SetFont(db.castFont, db.castFontSize)
    end
end

function addon:DisplayCastbar(castbar, unitID)
    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    local db = self.db[unitID:gsub("%d", "")] -- nameplate1 -> nameplate
    if unitID == "nameplate-testmode" then
        db = self.db.nameplate
    end

    local cast = castbar._data
    castbar:SetMinMaxValues(0, cast.maxValue)
    castbar:SetParent(parentFrame)

    if unitID == "target" then
        self:SetTargetCastbarPosition(castbar, parentFrame)
        castbar:SetScale(1)
    else
        local pos = db.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        castbar:SetScale(0.7)
    end

    self:SetCastbarFonts(castbar, cast, db)
    self:SetCastbarStyle(castbar, cast, db)
    self:SetCastbarIconAndText(castbar, cast, db)
    castbar:Show()
end
