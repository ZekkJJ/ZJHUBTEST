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

-- Function to extract clean ore name from item name
function ores.getCleanOreName(itemName)
    -- Find the base ore name without ID numbers
    for tier, oreList in pairs(ores.tiers) do
        for _, oreName in ipairs(oreList) do
            if string.find(itemName, oreName) then
                return oreName
            end
        end
    end
    
    -- If no match found, try to extract name before underscore
    local baseName = string.match(itemName, "^([^_]+)")
    if baseName then
        return baseName
    end
    
    -- Fallback to original name
    return itemName
end

-- Function to determine the tier of an ore based on its name
function ores.getOreTier(itemName)
    for tier, oreList in pairs(ores.tiers) do
        for _, oreName in ipairs(oreList) do
            if string.find(itemName, oreName) then
                return tier
            end
        end
    end
    
    return "Unknown"
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
    
    -- Extract the ore type from the item name pattern (like Silver_Ore_1020_252_156)
    local itemOreName = string.match(item.Name, "^([%a]+_[%a]+)") -- Match pattern like "Silver_Ore"
    if itemOreName then
        -- Replace underscore with space for comparison
        itemOreName = itemOreName:gsub("_", " ")
        
        -- Check if this ore type is selected
        if ores.selected[itemOreName] then
            return true
        end
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

-- Variables for bring functionality
local bringingItems = false

-- Check if items are currently being brought
function ores.isBringing()
    return bringingItems
end

-- Set bringing state
function ores.setBringing(state)
    bringingItems = state
end

-- Bring selected ores to the player
function ores.bringSelectedOres()
    local utils = require("utils")
    local config = require("config")
    
    if not workspace or not workspace:FindFirstChild("Items") or bringingItems then return end
    
    -- Check if any ores are selected
    local anySelected = false
    for _, selected in pairs(ores.selected) do
        if selected then
            anySelected = true
            break
        end
    end
    
    if not anySelected then
        return false, "No ores selected"
    end
    
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false, "Character not found" end
    
    local rootPosition = character.HumanoidRootPart.Position
    
    -- Get all items from the Items folder
    local items = workspace.Items:GetChildren()
    local selectedItems = {}
    
    -- Filter for selected ores
    for _, item in ipairs(items) do
        if ores.isSelected(item) then
            table.insert(selectedItems, item)
        end
    end
    
    local itemCount = #selectedItems
    
    if itemCount == 0 then
        return false, "No selected ores found"
    end
    
    bringingItems = true
    
    -- Process items with a slight delay between each to prevent lag
    local processedItems = 0
    local function processNextItem()
        processedItems = processedItems + 1
        
        if processedItems > itemCount then
            -- All items processed
            bringingItems = false
            return true, "Successfully brought " .. itemCount .. " ores"
        end
        
        local item = selectedItems[processedItems]
        if not item or not item.Parent then
            -- Skip invalid items
            task.spawn(processNextItem)
            return
        end
        
        -- Calculate target position (offset from player)
        local angle = (processedItems / itemCount) * (2 * math.pi)
        local offsetX = math.cos(angle) * config.bringSettings.bringDistance
        local offsetZ = math.sin(angle) * config.bringSettings.bringDistance
        local targetPosition = rootPosition + Vector3.new(offsetX, 0, offsetZ)
        
        -- Get item position and create tween
        local itemPosition
        if item:IsA("Model") and item.PrimaryPart then
            itemPosition = item.PrimaryPart.Position
        elseif item:IsA("BasePart") then
            itemPosition = item.Position
        else
            -- Skip non-physical items
            task.spawn(processNextItem)
            return
        end
        
        -- Calculate tween duration based on distance and speed (with max speed limit)
        local distance = (itemPosition - targetPosition).Magnitude
        local limitedSpeed = math.min(config.bringSettings.bringSpeed, 4) -- Limit max speed to 4
        local duration = distance / (50 * limitedSpeed) -- Adjust for speed
        
        -- Determine which part to tween
        local tweenPart
        if item:IsA("Model") and item.PrimaryPart then
            tweenPart = item.PrimaryPart
        elseif item:IsA("BasePart") then
            tweenPart = item
        else
            -- Skip non-physical items
            task.spawn(processNextItem)
            return
        end
        
        -- Create and play tween
        local tween = utils.createTween(
            tweenPart,
            {
                time = duration,
                easing = Enum.EasingStyle.Quad,
                direction = Enum.EasingDirection.Out
            },
            {
                CFrame = CFrame.new(targetPosition)
            }
        )
        tween:Play()
        
        -- Process next item after tween completes
        tween.Completed:Connect(function()
            task.spawn(processNextItem)
        end)
    end
    
    -- Start processing items
    task.spawn(processNextItem)
    return true, "Bringing " .. itemCount .. " ores"
end

-- Bring all ores at once
function ores.bringAllItems()
    return ores.bringSelectedOres()
end

return ores.init()
