-- Creative Commons Licensed in November 2018 by Cher Scarlett AKA Cherp or @codehitchhiker

_G["currentPlayer"] = {}

local function getArenaRatingQuality(rating)
    if rating < 1600 then
        return GetItemQualityColor(0)
    elseif rating < 1800 then
        return GetItemQualityColor(1)
    elseif rating < 2100 then
        return GetItemQualityColor(2)
    elseif rating < 2400 then
        return GetItemQualityColor(3)
    elseif rating < 2700 then
        return GetItemQualityColor(4)
    elseif rating >= 2700 then
        return GetItemQualityColor(5)
    end
end

local function isPVP(activityName)
    if activityName == "2v2" or activityName == "3v3" or activityName == "Rated Battlegrounds" then
        return true
    end
end

local function getPreviousAchievementId(achievementId)
    local ids = {
        [2093] = 2090,
        [2092] = 2093, 
        [2091] = 2092, 
        [443] = 433, 
        [433] = 445, 
        [445] = 434,
        [434] = 446,  
        [446] = 473,  
        [473] = 444, 
        [444] = 435, 
        [435] = 447, 
        [447] = 436,
        [436] = 448,
        [448] = 437,
        [437] = 469,
        [469] = 438,
        [438] = 449,
        [449] = 472,
        [472] = 451,
        [451] = 439,
        [439] = 452,
        [452] = 440,
        [440] = 450,
        [450] = 441,
        [441] = 471,
        [471] = 468, 
        [468] = 470,
        [470] = 454,
        [454] = 442
    }
    return ids[achievementId]
end

local function getAchievementMinimumRating(achievementId)
    local ratings = {
        [2090] = 1600,
        [2093] = 1800,
        [2092] = 2100,
        [2091] = 2400,
        [443] = 2400,
        [445] = 2300, 
        [446] = 2200, 
        [444] = 2100, 
        [447] = 2000,
        [448] = 1900,
        [469] = 1800,
        [449] = 1700,
        [451] = 1600,
        [452] = 1500,
        [450] = 1400,
        [471] = 1300,
        [468] = 1200,
        [454] = 1100,
        [433] = 2400,
        [434] = 2300, 
        [473] = 2200, 
        [435] = 2100, 
        [436] = 2000,
        [437] = 1900,
        [438] = 1800,
        [472] = 1700,
        [439] = 1600,
        [440] = 1500,
        [441] = 1400,
        [470] = 1200,
        [442] = 1100
    }
    return ratings[achievementId]
end

-- Tooltip

local function getHighestAchievement(achievementId)
    local completed, month, day, year = GetAchievementComparisonInfo(achievementId)
    if not completed then
        local prev = getPreviousAchievementId(achievementId)
        if prev then
            return getHighestAchievement(prev)
        end
    else
        local _, name, _, _, _, _, _, _, _, _, _, _, _, _ = GetAchievementInfo(achievementId)
        local ratingRequired = getAchievementMinimumRating(achievementId)
        local dateCompleted = month.. "/" ..year
        return { name = name, ratingRequired = ratingRequired, dateCompleted = dateCompleted }
    end 
end

local frame = frame or CreateFrame('frame')
frame:RegisterEvent('INSPECT_HONOR_UPDATE')
frame:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
frame:RegisterEvent('INSPECT_ACHIEVEMENT_READY')

local function getRating(bracketId)
    local rating, seasonPlayed, seasonWon, _, _ = GetInspectArenaData(bracketId)
    local ratingObject = {}
    if seasonPlayed > 0 then 
        ratingObject.wr = " - " ..math.floor(seasonWon/seasonPlayed*100).. "%"
    else
        ratingObject.wr = ""
    end
    ratingObject.rating = rating
    return ratingObject
end

local function getHighestRating(achievementId)
    local highestRating = GetComparisonStatistic(achievementId)
    if (highestRating == "--") then
        return 0
    else
        return tonumber(highestRating)
    end
end

local function getHighestArenaAchievement(achievementId, highestRating)
    local highestRank = getHighestAchievement(achievementId)
    if highestRank and (highestRating < highestRank.ratingRequired) then
        local prev = getPreviousAchievementId(achievementId)
        if prev then
            return getHighestArenaAchievement(prev, highestRating)
        end
    else
        return highestRank
    end
end

local function appendRatingToTooltip()
    if (HasInspectHonorData()) then
        local rating2v2 = getRating(1)
        local rating3v3 = getRating(2)
        local ratingRbg = getRating(4)
        local highest3s = getHighestRating(595)
        local highest2s = getHighestRating(370)
        local highestArenaRank2s = getHighestArenaAchievement(2092, highest2s)
        local highestArenaRank3s = getHighestArenaAchievement(2091, highest3s)
        local highestArenaRank = getHighestAchievement(2091)
        local highestRbgRank = getHighestAchievement(443)
        
        if rating2v2.rating > 0 or rating3v3.rating > 0 or ratingRbg.rating > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("PVP Ratings")
            if rating2v2.rating > 0 or (highestArenaRank2s and (highestArenaRank.ratingRequired > highest3s)) then
                local rating = rating2v2
                local _, _, _, hex = getArenaRatingQuality(rating.rating)
                rating.titleString = "2v2"
                if (highestArenaRank2s and (highestArenaRank.ratingRequired > highest3s)) then
                    rating.titleString = "2v2 - [" ..highestArenaRank2s.name.. "]"
                end
                GameTooltip:AddDoubleLine(format("|c%s%s|r ", hex, rating.titleString), rating.rating.. "" ..rating.wr, 1, 1, 1, 1, 1, 1)
            end
            if rating3v3.rating > 0 or (highestArenaRank3s and (highestArenaRank.ratingRequired <= highest3s)) then
                local rating = rating3v3
                local _, _, _, hex = getArenaRatingQuality(rating.rating)
                rating.titleString = "3v3"
                if (highestArenaRank3s and  (highestArenaRank.ratingRequired <= highest3s)) then
                    rating.titleString = "3v3 - [" ..highestArenaRank3s.name.. "]"
                end
                GameTooltip:AddDoubleLine(format("|c%s%s|r ", hex, rating.titleString), rating.rating.. "" ..rating.wr, 1, 1, 1, 1, 1, 1)
            end
            if ratingRbg.rating > 0 or highestRbgRank then
                local rating = ratingRbg
                local _, _, _, hex = getArenaRatingQuality(rating.rating)
                rating.titleString = "RBG"
                if highestRbgRank then
                    rating.titleString = "RBG - [" ..highestRbgRank.name.. "]"
                end
                GameTooltip:AddDoubleLine(format("|c%s%s|r ", hex, rating.titleString), rating.rating.. "" ..rating.wr, 1, 1, 1, 1, 1, 1)
            end
            GameTooltip:Show()
            _G["currentPlayer"].hasData = true
        end
    end
end

frame:SetScript("OnEvent",function(self, event)
    if not _G["currentPlayer"].hasData then
        appendRatingToTooltip()
    end
end)

GameTooltip:HookScript('OnTooltipSetUnit', function(self)
    if not GameTooltip:IsShown() then return end
    local name, unitid = self:GetUnit()
    if _G["currentPlayer"].name ~= name then
        _G["currentPlayer"].hasData = false
        _G["currentPlayer"].name = name
        ClearAchievementComparisonUnit()
    end
    if (UnitIsPlayer(unitid) and not UnitIsUnit("player", unitid)) then
        NotifyInspect(unitid)
        SetAchievementComparisonUnit(unitid)
        RequestInspectHonorData()
        if (HasInspectHonorData()) then appendRatingToTooltip() end
    end
end)

-- LFG

hooksecurefunc("LFGListSearchEntry_Update", function(self)
    local resultID, activityId, _, _, _, _, _, _, _, _, _, isDelisted, leaderName = C_LFGList.GetSearchResultInfo(self.resultID)
    if not isDelisted then
        local _, shortName, categoryID, _, _, _, _, _, _, _, _ = C_LFGList.GetActivityInfo(activityId)
        local isPVP = isPVP(shortName)
        if isPVP then
            local currentRealm = GetRealmName()
            local cr = 0
            self.ActivityName:SetTextColor(getArenaRatingQuality(cr))
        end
    end
end)
