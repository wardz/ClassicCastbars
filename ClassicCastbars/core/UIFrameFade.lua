local _, namespace = ...
local tinsert = _G.table.insert
local tremove = _G.table.remove

--[[
    Copy paste of UIFrameFade from FrameXML/UIParent.lua.
    Blizzard's version causes UI taint so this is a temp work around. (see issue #29)
]]

local FADEFRAMES = {};

-- Frame fading and flashing --

local frameFadeManager = CreateFrame("FRAME");

-- Function that actually performs the alpha change
--[[
Fading frame attribute listing
============================================================
frame.timeToFade  [Num]		Time it takes to fade the frame in or out
frame.mode  ["IN", "OUT"]	Fade mode
frame.finishedFunc [func()]	Function that is called when fading is finished
frame.finishedArg1 [ANYTHING]	Argument to the finishedFunc
frame.finishedArg2 [ANYTHING]	Argument to the finishedFunc
frame.finishedArg3 [ANYTHING]	Argument to the finishedFunc
frame.finishedArg4 [ANYTHING]	Argument to the finishedFunc
frame.fadeHoldTime [Num]	Time to hold the faded state
 ]]

 local function UIFrameFade_OnUpdate(self, elapsed)
    local index = 1;
    local frame, fadeInfo;
    while FADEFRAMES[index] do
        frame = FADEFRAMES[index];
        fadeInfo = FADEFRAMES[index].fadeInfo;
        -- Reset the timer if there isn't one, this is just an internal counter
        if ( not fadeInfo.fadeTimer ) then
            fadeInfo.fadeTimer = 0;
        end
        fadeInfo.fadeTimer = fadeInfo.fadeTimer + elapsed;

        -- If the fadeTimer is less then the desired fade time then set the alpha otherwise hold the fade state, call the finished function, or just finish the fade
        if ( fadeInfo.fadeTimer < fadeInfo.timeToFade ) then
            if ( fadeInfo.mode == "IN" ) then
                frame:SetAlpha((fadeInfo.fadeTimer / fadeInfo.timeToFade) * (fadeInfo.endAlpha - fadeInfo.startAlpha) + fadeInfo.startAlpha);
            elseif ( fadeInfo.mode == "OUT" ) then
                frame:SetAlpha(((fadeInfo.timeToFade - fadeInfo.fadeTimer) / fadeInfo.timeToFade) * (fadeInfo.startAlpha - fadeInfo.endAlpha)  + fadeInfo.endAlpha);
            end
        else
            frame:SetAlpha(fadeInfo.endAlpha);
            -- If there is a fadeHoldTime then wait until its passed to continue on
            if ( fadeInfo.fadeHoldTime and fadeInfo.fadeHoldTime > 0  ) then
                fadeInfo.fadeHoldTime = fadeInfo.fadeHoldTime - elapsed;
            else
                -- Complete the fade and call the finished function if there is one
                namespace:UIFrameFadeRemoveFrame(frame);
                if ( fadeInfo.finishedFunc ) then
                    fadeInfo.finishedFunc(fadeInfo.finishedArg1, fadeInfo.finishedArg2, fadeInfo.finishedArg3, fadeInfo.finishedArg4);
                    fadeInfo.finishedFunc = nil;
                end
            end
        end

        index = index + 1;
    end

    if ( #FADEFRAMES == 0 ) then
        self:SetScript("OnUpdate", nil);
    end
end

-- Generic fade function
function namespace:UIFrameFade(frame, fadeInfo)
    if (not frame) then
        return;
    end
    if ( not fadeInfo.mode ) then
        fadeInfo.mode = "IN";
    end
    --local alpha;
    if ( fadeInfo.mode == "IN" ) then
        if ( not fadeInfo.startAlpha ) then
            fadeInfo.startAlpha = 0;
        end
        if ( not fadeInfo.endAlpha ) then
            fadeInfo.endAlpha = 1.0;
        end
        --alpha = 0;
    elseif ( fadeInfo.mode == "OUT" ) then
        if ( not fadeInfo.startAlpha ) then
            fadeInfo.startAlpha = 1.0;
        end
        if ( not fadeInfo.endAlpha ) then
            fadeInfo.endAlpha = 0;
        end
        --alpha = 1.0;
    end
    frame:SetAlpha(fadeInfo.startAlpha);

    frame.fadeInfo = fadeInfo;
    frame:Show();

    local index = 1;
    while FADEFRAMES[index] do
        -- If frame is already set to fade then return
        if ( FADEFRAMES[index] == frame ) then
            return;
        end
        index = index + 1;
    end
    tinsert(FADEFRAMES, frame);
    frameFadeManager:SetScript("OnUpdate", UIFrameFade_OnUpdate);
end

-- Convenience function to do a simple fade out
function namespace:UIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
    local fadeInfo = {};
    fadeInfo.mode = "OUT";
    fadeInfo.timeToFade = timeToFade;
    fadeInfo.startAlpha = startAlpha;
    fadeInfo.endAlpha = endAlpha;
    namespace:UIFrameFade(frame, fadeInfo);
end

function namespace:UIFrameFadeRemoveFrame(frame)
    local index = 1;
    while FADEFRAMES[index] do
        if ( frame == FADEFRAMES[index] ) then
            tremove(FADEFRAMES, index);
        else
            index = index + 1;
        end
    end
end
