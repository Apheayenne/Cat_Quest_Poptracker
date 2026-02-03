-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = true or ENABLE_DEBUG_LOG
AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP = true
AUTOTRACKER_ENABLE_ITEM_TRACKING = true
AUTOTRACKER_ENABLE_LOCATION_TRACKING = true
-------------------------------------------------------

ScriptHost:LoadScript("scripts/item_mappings.lua")
ScriptHost:LoadScript("scripts/location_mappings.lua")

CUR_INDEX = -1
SLOT_DATA = nil

function DebugLog()
	print("")
	print("Active Auto-Tracker Configuration")
	print("---------------------------------------------------------------------")
	print("Enable Item Tracking:		", AUTOTRACKER_ENABLE_ITEM_TRACKING)
	print("Enable Location Tracking:	", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("Enable Debug Logging:		", AUTOTRACKER_ENABLE_DEBUG_LOGGING)
		print("Enable AP Debug Logging:		", AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP)
	end
	print("---------------------------------------------------------------------")
	print("")
end

function DebugAP(msg)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(msg)
	end
end

function Dump_table(o, depth)
	if depth == nil then
		depth = 0
	end
	if type(o) == 'table' then
		local tabs = ('\t'):rep(depth)
		local tabs2 = ('\t'):rep(depth + 1)
		local s = '{\n'
		for k, v in pairs(o) do
			if type(k) ~= 'number' then
				k = '"' .. k .. '"'
			end
			s = s .. tabs2 .. '[' .. k .. '] = ' .. Dump_table(v, depth + 1) .. ',\n'
		end
		return s .. tabs .. '}'
	else
		return tostring(o)
	end
end

function OnClear(slot_data)
    DebugAP(string.format("called onClear, slot_data:\n<%s>", Dump_table(slot_data)))
    print(Dump_table(SLOT_DATA))
    SLOT_DATA = slot_data
    CUR_INDEX = -1
    
    for _, v in pairs(LOCATION_MAPPINGS) do
        if v[1] then
            DebugAP(string.format("onClear: clearing location '<%s>'", v[1]))
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if (v[1]:sub(1,1) == "@") then
                    obj.AvailableChestCount = obj.ChestCount
                end
            else 
                DebugAP(string.format("onClear: could not find object for code '<%s>'", v[1]))
            end
        end
    end

    for _, v in pairs(ITEM_MAPPINGS) do
        if v[1] and v[2]then
            DebugAP(string.format("onClear: clearing item '<%s>' of type '<%s>'", v[1], v[2]))
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                    print(string.format("onClear: unknown item type <%s> for code <%s>", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print(string.format("onClear: could not find object for code <%s>", v[1]))
            end
        end
    end
end

function OnItem(index, item_id, item_name, player_number)
    if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
    
    if index <= CUR_INDEX then
		return
	end
	
    DebugAP(string.format("OnItem called with index <%s>, item_id <%s>, item_name <%s>, player_number <%s>", index, item_id, item_name, player_number))

    CUR_INDEX = index;
	local v = ITEM_MAPPINGS[item_id]

    if not v then
        DebugAP(string.format("onItem: could not find item mapping for id <%s>", item_id))
        return
    end
    DebugAP(string.format("onItem: code: <%s>, type <%s>", v[1], v[2]))

    if not v[1] then
		return
	end

    local obj = Tracker:FindObjectForCode(v[1])
    if v[2] == "toggle" then
        obj.Active = true
    elseif v[2] == "progressive" then
        obj.CurrentStage = obj.CurrentStage + 1
        obj.Active = true
    elseif v[2] == "consumable" then
        obj.AcquiredCount = obj.AcquiredCount + 1
    else
        DebugAP(string.format("onItem: unknown item type <%s> for code <%s>", v[2], v[1]))
    end
end

function OnLocation(index, location_id, location_name)
    DebugAP("")
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
    
    DebugAP(string.format("OnLocation called with index <%s>, location_id <%s>, location_name <%s>", index, location_id, location_name))

    CUR_INDEX = index;
    local v = LOCATION_MAPPINGS[index]

    DebugAP(string.format("onLocation: value <%s>", v[1]))

    if not v then
        DebugAP(string.format("onLocation: could not find location mapping for id <%s>", location_id))
        return
    end

    if not v[1] then
        DebugAP(string.format("onLocation: no code for location id <%s>", location_id))
        return
    end

    local obj = Tracker:FindObjectForCode(v[1])
    --DebugAP(string.format("onLocation: found object <%s> for code <%s>", tostring(obj), v[1]))
    if obj then
        if v[1]:sub(1, 1) == "@" then
            --DebugAP(string.format("onLocation: activated object for code <%s>", v[1]))
			obj.AvailableChestCount = obj.AvailableChestCount - 1
            --DebugAP(string.format("Total Chest Count <%s> available <%s>", obj.ChestCount, obj.AvailableChestCount))
		else
			obj.Active = true
		end
    else
        --DebugAP(string.format("onLocation: could not find object for code <%s>", v[1]))
    end
end

Archipelago:AddClearHandler("clear handler", OnClear)
Archipelago:AddItemHandler("item handler", OnItem)
Archipelago:AddLocationHandler("location handler", OnLocation)