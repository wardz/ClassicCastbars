local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager

local addon = namespace.addon
local activeFrames = addon.activeFrames
local gsub = _G.string.gsub
local unpack = _G.unpack
local min = _G.math.min
local max = _G.math.max
local UnitExists = _G.UnitExists
local UIFrameFadeOut = _G.UIFrameFadeOut
local UIFrameFadeRemoveFrame = _G.UIFrameFadeRemoveFrame

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

    if parentFrame.haveToT or parentFrame.haveElite or UnitExists("targettarget") then
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

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small" or db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" then -- default border
        castbar.Border:SetAlpha(1)
        if castbar.BorderFrame then
            -- Hide LSM border frame if it exists
            castbar.BorderFrame:SetAlpha(0)
        end

        -- Update border to match castbar size
        local width, height = castbar:GetWidth() * 1.16, castbar:GetHeight() * 1.16
        castbar.Border:SetPoint("TOPLEFT", width, height)
        castbar.Border:SetPoint("BOTTOMRIGHT", -width, -height)
    else
        -- Using border sat by LibSharedMedia
        self:SetLSMBorders(castbar, cast, db)
    end
end

-- LSM uses backdrop for borders instead of normal textures
function addon:SetLSMBorders(castbar, cast, db)
    -- Create new frame to contain our backdrop
    -- (castbar.Border is a texture object and not a frame so we can't reuse that)
    if not castbar.BorderFrame then
        castbar.BorderFrame = CreateFrame("Frame", nil, castbar)
        castbar.BorderFrame:SetPoint("TOPLEFT", castbar, -2, 2)
        castbar.BorderFrame:SetPoint("BOTTOMRIGHT", castbar, 2, -2)
    end

    castbar.Border:SetAlpha(0) -- hide default border
    castbar.BorderFrame:SetAlpha(1)

    -- TODO: should be a better way to handle this.
    -- Certain borders with transparent textures requires frame level 1 to show correctly.
    -- Meanwhile non-transparent textures requires the frame level to be higher than the castbar frame level
    if db.castBorder == "Interface\\CHARACTERFRAME\\UI-Party-Border" or db.castBorder == "Interface\\Tooltips\\ChatBubble-Backdrop" then
        castbar.BorderFrame:SetFrameLevel(1)
    else
        castbar.BorderFrame:SetFrameLevel(castbar:GetFrameLevel() + 1)
    end

    -- Apply backdrop if it isn't already active
    if castbar.BorderFrame.currentTexture ~= db.castBorder then
        castbar.BorderFrame:SetBackdrop({
            edgeFile = db.castBorder,
            tile = false, tileSize = 0,
            edgeSize = castbar:GetHeight(),
        })
        castbar.BorderFrame.currentTexture = db.castBorder
    end
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

function addon:DisplayCastbar(castbar, unitID)
    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    local db = self.db[gsub(unitID, "%d", "")] -- nameplate1 -> nameplate
    if unitID == "nameplate-testmode" then
        db = self.db.nameplate
    elseif unitID == "party-testmode" then
        db = self.db.party
    end

    if castbar.fadeInfo then
        -- need to remove frame if it's currently fading so alpha doesn't get changed after re-displaying castbar
        UIFrameFadeRemoveFrame(castbar)
        castbar.fadeInfo.finishedFunc = nil
    end

    local cast = castbar._data
    cast.showCastInfoOnly = db.showCastInfoOnly
    castbar:SetParent(parentFrame)
    castbar.Text:SetWidth(db.width - 10) -- ensure text gets truncated

    if not castbar.Background then
        for k, v in pairs({ castbar:GetRegions() }) do
            if v.GetTexture and v:GetTexture() and strfind(v:GetTexture(), "Color-") then
                castbar.Background = v
                break
            end
        end
    end
    castbar.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    if cast.isChanneled then
        castbar:SetStatusBarColor(unpack(db.statusColorChannel))
    else
        castbar:SetStatusBarColor(unpack(db.statusColor))
    end

    if unitID == "target" and self.db.target.autoPosition then
        self:SetTargetCastbarPosition(castbar, parentFrame)
    else
        castbar:SetPoint(db.position[1], parentFrame, db.position[2], db.position[3])
    end

    -- Note: since frames are recycled and we also allow having different styles
    -- between castbars for target frame & nameplates, we need to always update the style here
    -- incase it was modified to something else on last recycle
    self:SetCastbarStyle(castbar, cast, db)
    self:SetCastbarFonts(castbar, cast, db)
    self:SetCastbarIconAndText(castbar, cast, db)

    if not castbar.isTesting then
        castbar:SetMinMaxValues(0, cast.maxValue)
        castbar:SetValue(0)
        castbar.Spark:SetPoint("CENTER", castbar, "LEFT", 0, 0)
    end

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
    end

    --[[if cast and cast.isCastComplete and not cast.isChanneled then
        castbar:SetStatusBarColor(0, 1, 0)
    end]]

    UIFrameFadeOut(castbar, cast and cast.isInterrupted and 1.5 or 0.2, 1, 0)
end

local CastingBarFrameManagedPosTable
-- TODO: reset to default skin on mode disabled without having to reloadui
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

    if db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" or db.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small" then
        CastingBarFrame.Flash:SetSize(db.width + 61, db.height + 51)
        CastingBarFrame.Flash:SetPoint("TOP", 0, 26)
    else
        CastingBarFrame.Flash:SetSize(0.01, 0.01) -- hide it using size, SetAlpha() or Hide() wont work without messing with blizz code
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
        for k, v in pairs({ CastingBarFrame:GetRegions() }) do
            if v.GetTexture and v:GetTexture() and strfind(v:GetTexture(), "Color-") then
                CastingBarFrame.Background = v
                break
            end
        end
    end
    CastingBarFrame.Background:SetColorTexture(unpack(db.statusBackgroundColor))

    CastingBarFrame:ClearAllPoints()
    if not db.autoPosition then
        local pos = db.position
        CastingBarFrame:SetAttribute("ignoreFramePositionManager", true)
        CastingBarFrameManagedPosTable = CopyTable(UIPARENT_MANAGED_FRAME_POSITIONS.CastingBarFrame)
        UIPARENT_MANAGED_FRAME_POSITIONS.CastingBarFrame = nil
        CastingBarFrame:SetPoint(pos[1], UIParent, pos[2], pos[3])
    else
        CastingBarFrame:SetAttribute("ignoreFramePositionManager", false)
        UIPARENT_MANAGED_FRAME_POSITIONS.CastingBarFrame = CastingBarFrameManagedPosTable
        CastingBarFrame:SetPoint("BOTTOM", UIParent, 0, 150)
    end

    self:SetCastbarStyle(CastingBarFrame, nil, db)
    self:SetCastbarFonts(CastingBarFrame, nil, db)
end
