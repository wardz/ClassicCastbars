local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager
local addon = namespace.addon
local activeFrames = namespace.activeFrames

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

function addon:DisplayCastbar(castbar, unitID)
    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    local db
    if unitID == "nameplate-testmode" then
        db = self.db.nameplate
    else
        db = self.db[unitID:gsub("%d", "")] -- nameplate1 --> nameplate
    end

    local cast = castbar._data
    castbar:SetParent(parentFrame)
    castbar:SetSize(db.width, db.height)
    castbar.Timer:SetShown(db.showTimer)

    if unitID == "target" then
        self:SetTargetCastbarPosition(castbar, parentFrame)
        --castbar:SetScale(1)
    else -- nameplates
        local pos = db.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        --castbar:SetScale(0.7) -- TODO: fixme
    end

    if db.simpleStyle then
        castbar.Border:SetAlpha(0)
        castbar.Icon:SetSize(db.height, db.height)
        castbar.Icon:SetPoint("LEFT", castbar, -db.height, 0)
    else
        castbar.Border:SetAlpha(1)
        castbar.Icon:SetSize(db.iconSize, db.iconSize)
        castbar.Icon:SetPoint("LEFT", castbar, -db.iconSize - 7, 0)

        -- Update border to match castbar size
        local width, height = castbar:GetWidth() * 1.16, castbar:GetHeight() * 1.16
        castbar.Border:SetPoint("TOPLEFT", width, height)
        castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
    end

    -- Update text + icon if it has changed
    if castbar.Text:GetText() ~= cast.spellName then
        castbar.Icon:SetTexture(cast.icon)

        if db.showSpellRank and cast.spellRank then
            castbar.Text:SetText(cast.spellName .. " (" .. cast.spellRank .. ")")
        else
            castbar.Text:SetText(cast.spellName)
        end

        -- Move timer position depending on spellname length
        if db.showTimer and (cast.spellName:len() + (cast.spellRank and cast.spellRank:len() or 0)) >= 19 then
            castbar.Timer:SetPoint("RIGHT", castbar, 20, 0)
        else
            castbar.Timer:SetPoint("RIGHT", castbar, -6, 0)
        end
    end

    castbar:SetMinMaxValues(0, cast.maxValue)
    castbar:Show()
end
