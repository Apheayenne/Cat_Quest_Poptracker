-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = true
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
		print("Enable AP Debug Logging:     ", AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP)
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
    DebugAP("") -- Blank line for readability
    DebugAP(string.format("called onClear, slot_data:\n<%s>", Dump_table(slot_data)))
    SLOT_DATA = slot_data
    
    DebugAP(string.format("==========================================================="))
    DebugAP(string.format("                    Clearing Locations                     "))
    DebugAP(string.format("==========================================================="))
    clearLocations()

    DebugAP(string.format("==========================================================="))
    DebugAP(string.format("                      Clearing Items                       "))
    DebugAP(string.format("==========================================================="))
    clearItems()

    Tracker:FindObjectForCode("skills").CurrentStage = SLOT_DATA["skill_upgrade"]
    Tracker:FindObjectForCode("goals").CurrentStage = SLOT_DATA["goal"]
    Tracker:FindObjectForCode("monuments").CurrentStage = SLOT_DATA["include_monuments"]
    Tracker:FindObjectForCode("temples").CurrentStage = SLOT_DATA["include_temples"]

    DebugAP(string.format("==========================================================="))
    DebugAP(string.format("                     Clearing Complete                     "))
    DebugAP(string.format("==========================================================="))
end

function clearLocations()
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
end

function clearItems()
    for _, v in pairs(ITEM_MAPPINGS) do
        if not v[1] and not v[2]then
            goto continue
        end

        if v[2] == "progressive" or v[2] == "progressiveToggle" then
            DebugAP(string.format("onClear: skipping clearing item '<%s>' of type '<%s>'", v[1], v[2]))
            goto continue
        end

        DebugAP(string.format("onClear: clearing item '<%s>' of type '<%s>'", v[1], v[2]))
        local obj = Tracker:FindObjectForCode(v[1])
        
        if not obj and AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            DebugAP(string.format("onClear: could not find object for code <%s>", v[1]))
            goto continue
        end

        if v[2] == "toggle" then
            obj.Active = false
        elseif v[2] == "spell" then
            obj.CurrentStage = 0
            obj.Active = false
        elseif v[2] == "progressive" or v[2] == "progressiveToggle" then
            -- Do Nothing
            --obj.CurrentStage = 0
            --obj.Active = false
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            DebugAP(string.format("onClear: unknown item type <%s> for code <%s>", v[2], v[1]))
        end            
        ::continue::
    end
end

function OnItem(index, item_id, item_name, player_number)
    DebugAP(string.format("OnItem called with index <%s>, item_id <%s>, item_name <%s>, player_number <%s>", index, item_id, item_name, player_number))

    if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
        DebugAP(string.format("AUTOTRACKER_ENABLE_ITEM_TRACKING = <%s>", AUTOTRACKER_ENABLE_ITEM_TRACKING))
		DebugAP("===========================================================") -- Blank line for readability
        return
	end
    
    --if index <= CUR_INDEX then
    --    DebugAP(string.format("Returning Index already processed: index <%s> <= CUR_INDEX <%s>", index, CUR_INDEX))
	--	DebugAP("===========================================================") -- Blank line for readability
    --    return
	--end
	
    CUR_INDEX = index;
	local v = ITEM_MAPPINGS[item_id]

    if not v then
        DebugAP(string.format("onItem: could not find item mapping for id <%s>", item_id))
        DebugAP("===========================================================") -- Blank line for readability
        return
    end
    
    DebugAP(string.format("onItem: code: <%s>, type <%s>", v[1], v[2]))

    if not v[1] then
		DebugAP("===========================================================") -- Blank line for readability
        return
	end
    
    -- Progressive Skills: Each skill is added to the Itempool 10 times
    -- Upgrades: Each skill is added to the itempool 1 time, allowing the use of the skill. 
        --Additionally 9 upgrades for each skill are added to the itempool, that will be applied once the skill is aquired.
    -- Magic Levels: Each skill is added to the itempool 1 time, allowing the use of the skill.
        --Additionally 9 magic levels are added to the itempool that will upgrade all aquired spells.

    DebugAP(string.format("onItem: handling <%s>", v[1]))
    if v[2] == "toggle" then
        -- Normal toggle item, just activate it
        updateItem(Tracker:FindObjectForCode(v[1]), "toggle")
    elseif v[2] == "consumable" then
        -- Spells have multiple stages, so we increment the stage and activate it if it isn't already
        if v[1] == "Progressive Flamepurr" or v[1] == "Progressive Flamepurr Upgrade" then
            updateItem(Tracker:FindObjectForCode("flamepurrUpdate"), "consumable")
        elseif v[1] == "Progressive Freezepaw" or v[1] == "Progressive Freezepaw Upgrade" then
            updateItem(Tracker:FindObjectForCode("freezepawUpdate"), "consumable")
        elseif v[1] == "Progressive Lightnyan" or v[1] == "Progressive Lightnyan Upgrade" then
            updateItem(Tracker:FindObjectForCode("lightnyanUpdate"), "consumable")
        elseif v[1] == "Progressive Healing Paw" or v[1] == "Progressive Healing Paw Upgrade" then
            updateItem(Tracker:FindObjectForCode("healingpawUpdate"), "consumable")
        elseif v[1] == "Progressive Purrserk" or v[1] == "Progressive Purrserk Upgrade" then
            updateItem(Tracker:FindObjectForCode("purrserkUpdate"), "consumable")
        elseif v[1] == "Progressive Astropaw" or v[1] == "Progressive Astropaw Upgrade" then
            updateItem(Tracker:FindObjectForCode("astropawUpdate"), "consumable")
        elseif v[1] == "Progressive Cattrap" or v[1] == "Progressive Cattrap Upgrade" then
            updateItem(Tracker:FindObjectForCode("cattrapUpdate"), "consumable")
        elseif v[1] == "Progressive Lightnyan" or v[1] == "Progressive Lightnyan Upgrade" then
            updateItem(Tracker:FindObjectForCode("lightnyanUpdate"), "consumable")
        elseif v[1] == "Progressive Magic Level" then
            updateItem(Tracker:FindObjectForCode("flamepurrUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("healingpawUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("lightnyanUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("cattrapUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("purrserkUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("astropawUpgrade"), "consumable")
            updateItem(Tracker:FindObjectForCode("freezepawUpgrade"), "consumable")
        else 
            DebugAP(string.format("onItem: unknown consumable item <%s>", v[1]))
        end
    else
        DebugAP(string.format("onItem: unknown item type <%s> for code <%s>", v[2], v[1]))
    end

    DebugAP("===========================================================") -- Blank line for readability
end

function updateItem(object, type)
    if type == "toggle" then
        object.Active = true
    elseif type == "progressive" then
        object.CurrentStage = object.CurrentStage + 1
        --object.Active = true
    elseif type == "progressiveToggle" then
        object.CurrentStage = object.CurrentStage + 1
    elseif type == "consumable" then
        object.AcquiredCount = object.AcquiredCount + object.Increment
    else
        DebugAP(string.format("updateItem: unknown item type <%s> for code <%s>", type, object.Code))
    end
end

function OnLocation(index, location_id, location_name)
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		DebugAP("===========================================================") -- Blank line for readability
        return
	end
    
    DebugAP(string.format("OnLocation called with index <%s>, location_id <%s>, location_name <%s>", index, location_id, location_name))

    local v = LOCATION_MAPPINGS[index]

    DebugAP(string.format("onLocation: value <%s>", v[1]))

    if not v then
        DebugAP(string.format("onLocation: could not find location mapping for id <%s>", location_id))
        DebugAP("===========================================================") -- Blank line for readability
        return
    end

    if not v[1] then
        DebugAP(string.format("onLocation: no code for location id <%s>", location_id))
        DebugAP("===========================================================") -- Blank line for readability
        return
    end

    local obj = Tracker:FindObjectForCode(v[1])
    DebugAP(string.format("onLocation: found object <%s> for code <%s>", tostring(obj), v[1]))
    if obj then
        if v[1]:sub(1, 1) == "@" then
            DebugAP(string.format("onLocation: activated object for code <%s>", v[1]))
			obj.AvailableChestCount = obj.AvailableChestCount - 1
            DebugAP(string.format("Total Chest Count <%s> available <%s>", obj.ChestCount, obj.AvailableChestCount))
		else
			obj.Active = true
		end
    else
        DebugAP(string.format("onLocation: could not find object for code <%s>", v[1]))
    end

    DebugAP("===========================================================") -- Blank line for readability
end

DebugLog()

Archipelago:AddClearHandler("clear handler", OnClear)
Archipelago:AddLocationHandler("location handler", OnLocation)
Archipelago:AddItemHandler("item handler", OnItem)

