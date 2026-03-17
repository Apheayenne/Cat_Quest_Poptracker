ENABLE_DEBUG_LOG = true
-- Maps
Tracker:AddMaps("maps/map.json")

-- Layouts
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/item_grid.json")
Tracker:AddLayouts("layouts/settings_layout.json")

-- Locations
Tracker:AddLocations("locations/locations.json")

-- Items
Tracker:AddItems("items/items.json")
Tracker:AddItems("items/item_setting.json")

-- Scripts
ScriptHost:LoadScript("scripts/autotracking.lua")
ScriptHost:LoadScript("scripts/logic.lua")

