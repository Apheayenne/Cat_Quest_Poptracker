
function locationChecked(location)
    local loc = Tracker:FindObjectForCode("@" .. location)
    if loc and loc.AvailableChestCount == 0 then
        return true
    end
    return false
end

function toggleItem()
    local item = Tracker:FindObjectForCode("invisible_item")
    if item then
        item.Active = not item.Active
    end
end

ScriptHost:AddOnLocationSectionChangedHandler("locationCheck", toggleItem)
