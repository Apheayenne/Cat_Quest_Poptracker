
function locationChecked(location)
    local loc = Tracker:FindObjectForCode("@" .. location)
    if loc.AvailableChestCount == 0 then
        return true
    end
    return false
end

function toggleItem()
    local item = Tracker:FindObjectForCode("invisible_item")
    item.Active = not item.Active
end

ScriptHost:AddOnLocationSectionChangedHandler("locationCheck", toggleItem)
