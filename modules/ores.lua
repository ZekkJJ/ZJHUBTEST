--[[
    ZJ/HUB Ores Module
    
    This module handles ore selection and management.
]]--

local ores = {}

-- Ore tiers
ores.tiers = {
    ["Common"] = {
        "Silver Ore",
        "Coal Ore",
        "Zinc Ore",
        "Copper Ore",
        "Nickel Ore"
    },
    ["Uncommon"] = {
        "Sapphire Ore",
        "Gold Ore",
        "Quartz Ore",
        "Tin Ore",
        "Iron Ore"
    },
    ["Rare"] = {
        "Cobalt Ore",
        "Amethyst Ore",
        "Ruby Ore",
        "Dinosaur Bone",
        "Turquoise Ore",
        "Platinum Ore"
    },
    ["Epic"] = {
        "Treasure Chest",
        "King's Ring",
        "Ancient Skull",
        "Fossil Fin",
        "Fossil Hand",
        "Giant Cobalt",
        "Giant Platinum",
        "Uranium",
        "Giant Diamond"
    },
    ["Legendary"] = {
        "Lava Rock",
        "Giant Treasure Chest",
        "Ancient Coin",
        "Alien Artifact",
        "Bat Wing",
        "Giant Fossil Fin",
        "Rainbow Crystal",
        "Glowing Mushroom",
        "Moai Head",
        "Passage Key",
        "Ancient Arrow",
        "Ancient Relic"
    },
    ["Mythical"] = {
        "Pirate Ship",
        "Corrupted UFO",
        "Nuke",
        "King's Sword"
    }
}

-- Selected ores and tiers
ores.selected = {}
ores.selectedTiers = {}

-- Initialize ore selection
function ores.init()
    -- Initialize selected ores
    for tier, oreList in pairs(ores.tiers) do
        for _, oreName in ipairs(oreList) do
            ores.selected[oreName] = false
        end
    end
    
    -- Initialize selected tiers
    for tier, _ in pairs(ores.tiers) do
        ores.selectedTiers[tier] = false
    end
    
    return ores
end

-- Get all ore names as a flat list
function ores.getAllOreNames()
    local allOres = {}
    for _, oreList in pairs(ores.tiers) do
        for _, oreName in ipairs(oreList) do
            table.insert(allOres, oreName)
        end
    end
    return allOres
end

-- Get dropdown options for UI
function ores.getDropdownOptions()
    local options = {}
    for tier, _ in pairs(ores.tiers) do
        table.insert(options, tier)
    end
    return options
end

-- Select all ores in a tier
function ores.selectTier(tier, value)
    if not ores.tiers[tier] then return end
    
    ores.selectedTiers[tier] = value
    
    for _, oreName in ipairs(ores.tiers[tier]) do
        ores.selected[oreName] = value
    end
end

-- Select a specific ore
function ores.selectOre(oreName, value)
    if ores.selected[oreName] ~= nil then
        ores.selected[oreName] = value
    end
end

-- Check if an item is a selected ore
function ores.isSelected(item)
    if not item or not item.Name then return false end
    
    -- If no ores are selected, show all ores
    local anySelected = false
    for _, selected in pairs(ores.selected) do
        if selected then
            anySelected = true
            break
        end
    end
    
    if not anySelected then
        return true -- Show all ores if none are specifically selected
    end
    
    -- Check if the item matches any selected ore name exactly
    for oreName, selected in pairs(ores.selected) do
        if selected then
            -- Try exact match
            if item.Name == oreName then
                return true
            end
            
            -- Try with underscores instead of spaces
            local oreNameWithUnderscores = oreName:gsub(" ", "_")
            if item.Name == oreNameWithUnderscores then
                return true
            end
        end
    end
    
    -- Check if the item name contains any of the selected ores (fallback)
    for oreName, selected in pairs(ores.selected) do
        if selected then
            -- Try with spaces
            if string.find(item.Name, oreName) then
                return true
            end
            
            -- Try with underscores instead of spaces
            local oreNameWithUnderscores = oreName:gsub(" ", "_")
            if string.find(item.Name, oreNameWithUnderscores) then
                return true
            end
        end
    end
    
    return false
end

-- Bring selected ores to the player
function ores.bringSelectedOres()
    local utils = require("utils")
    local config = require("config")
    
    local playerPos = utils.getPlayerPosition()
    if not playerPos then return end
    
    -- Find all ores in the workspace
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and ores.isSelected(item) then
            local distance = utils.getDistance(playerPos, item.Position)
            
            -- Only bring ores within the max distance
            if distance <= config.bringSettings.bringDistance then
                -- Create a tween to bring the ore to the player
                local tween = utils.createTween(
                    item,
                    {time = 0.5},
                    {Position = playerPos}
                )
                tween:Play()
            end
        end
    end
end

return ores.init()
