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
    -- Auto position is turned off, set pos from cfg
    if not self.db.target.dynamicTargetPosition then
        local pos = self.db.target.position
        return castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
    end

    -- Set position based on aura amount & targetframe type
    -- TODO: set better offsets
    if parentFrame.haveToT then -- target of target
        if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -15)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 20, -60)
        end
    elseif parentFrame.haveElite then
        if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -15)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -60)
        end
    else
        if ((not parentFrame.buffsOnTop) and parentFrame.auraRows > 0) then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -60)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -3)
        end
    end
end

function addon:DisplayCastbar(castbar, unitID)
    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    local width, height = castbar:GetWidth(), castbar:GetHeight()
    local cast = castbar._data
    castbar:SetParent(parentFrame)

    if unitID == "target" then
        self:SetTargetCastbarPosition(castbar, parentFrame) -- TODO: we should prob call this on target aura changed
        castbar:SetSize(self.db.target.width, self.db.target.height)
        castbar:SetScale(1)
    else -- nameplates
        local pos = self.db.nameplate.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        castbar:SetSize(self.db.nameplate.width, self.db.nameplate.height)
        castbar:SetScale(0.7) -- TODO: just set diff width/height for nameplates
    end

    -- Update border to match castbar size
    castbar.Border:ClearAllPoints() -- TODO: needed? maybe add in pool
    castbar.Border:SetPoint("TOPLEFT", width * 1.16, height * 1.16)
    castbar.Border:SetPoint("BOTTOMRIGHT", -(width * 1.16), -height * 1.16)

    -- Update text + icon if it has changed
    if castbar.Text:GetText() ~= cast.spellName then
        castbar.Text:SetText(cast.spellName)
        castbar.Icon:SetTexture(cast.icon)
    end

    castbar:SetMinMaxValues(0, cast.maxValue)
    castbar:Show()
end

--[[
        local castbar = self:GetCastbarFrame("target")
        castbar:SetPoint(self.db.target.position[1], TargetFrame, self.db.target.position[2], self.db.target.position[3])
        castbar:SetSize(130, 10)
        castbar.Border:ClearAllPoints()
        local w, h = castbar:GetWidth(), castbar:GetHeight()
        castbar.Border:SetPoint("TOPLEFT", w * 1.16, h * 1.16) -- * 1.16 is our offset
        castbar.Border:SetPoint("BOTTOMRIGHT", -(w * 1.16), -h * 1.16)
        castbar:Show()
]]
