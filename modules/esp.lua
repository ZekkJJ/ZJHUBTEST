--[[
    ZJ/HUB ESP Module
    
    This module handles the ESP functionality for ores.
]]--

local esp = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Get other modules
local utils = require("utils")
local ores = require("ores")
local config = require("config")

-- Local variables
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local espLabels = {}
local updateConnection = nil

-- Variables
local espEnabled = false
local updateInterval = 0.5

-- Initialize ESP
function esp.init()
    espEnabled = false
    esp.trackAllOres = false
    
    -- Set initial values from config
    espEnabled = config.espSettings.enabled
    updateInterval = config.espSettings.updateInterval
    
    -- Start the ESP update loop
    spawn(function()
        while wait(updateInterval) do
            if espEnabled then
                esp.update()
            end
        end
    end)
    
    return esp
end

-- Toggle ESP
function esp.toggle(enabled)
    espEnabled = enabled
    
    if enabled then
        -- Start ESP update loop
        if not updateConnection then
            updateConnection = RunService.RenderStepped:Connect(function()
                esp.update()
            end)
        end
    else
        -- Clean up ESP labels
        esp.clearLabels()
        
        -- Disconnect update loop
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
    end
end

-- Toggle track all ores
function esp.toggleTrackAllOres(enabled)
    esp.trackAllOres = enabled
end

-- Toggle simulation mode
function esp.toggleSimulatePresence(enabled)
    simulatePresence = enabled
    
    -- Clean up simulation parts if disabled
    if not enabled then
        esp.cleanupSimulationParts()
    else
        esp.createSimulationParts()
    end
end

-- Set simulation radius
function esp.setSimulationRadius(radius)
    simulationRadius = radius
    
    -- Recreate simulation parts if enabled
    if simulatePresence then
        esp.cleanupSimulationParts()
        esp.createSimulationParts()
    end
end

-- Create simulation parts around the player
function esp.createSimulationParts()
    -- Clean up existing parts first
    esp.cleanupSimulationParts()
    
    -- Get player position
    local playerPos = utils.getPlayerPosition()
    if not playerPos then return end
    
    -- Create simulation parts in a grid pattern around the player
    local gridSize = 4 -- Number of parts in each direction
    local stepSize = simulationRadius / gridSize
    
    for x = -gridSize, gridSize do
        for z = -gridSize, gridSize do
            -- Skip center position (player's actual position)
            if x == 0 and z == 0 then continue end
            
            -- Calculate position offset
            local offsetX = x * stepSize
            local offsetZ = z * stepSize
            local position = playerPos + Vector3.new(offsetX, 0, offsetZ)
            
            -- Create invisible part
            local part = Instance.new("Part")
            part.Name = "SimulationPart"
            part.Size = Vector3.new(1, 1, 1)
            part.Position = position
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1 -- Invisible
            part.Parent = workspace
            
            -- Add to tracking table
            table.insert(simulationParts, part)
        end
    end
end

-- Clean up simulation parts
function esp.cleanupSimulationParts()
    for _, part in ipairs(simulationParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    
    -- Clear the table
    simulationParts = {}
end

-- Update simulation parts positions based on player movement
function esp.updateSimulationParts()
    if not simulatePresence or #simulationParts == 0 then return end
    
    -- Get player position
    local playerPos = utils.getPlayerPosition()
    if not playerPos then return end
    
    -- Recreate parts if too few exist (might have been destroyed)
    if #simulationParts < 10 then
        esp.createSimulationParts()
        return
    end
    
    -- Update positions of existing parts
    local gridSize = 4
    local stepSize = simulationRadius / gridSize
    local index = 1
    
    for x = -gridSize, gridSize do
        for z = -gridSize, gridSize do
            -- Skip center position (player's actual position)
            if x == 0 and z == 0 then continue end
            
            -- Calculate position offset
            local offsetX = x * stepSize
            local offsetZ = z * stepSize
            local position = playerPos + Vector3.new(offsetX, 0, offsetZ)
            
            -- Update part position if it exists
            if simulationParts[index] and simulationParts[index].Parent then
                simulationParts[index].Position = position
                index = index + 1
            end
        end
    end
end

-- Update ESP
function esp.update()
    if not espEnabled then return end
    
    -- Get character's current position
    local playerPos = utils.getPlayerPosition()
    if not playerPos then return end
    
    -- Clear existing labels
    esp.clearLabels()
    
    -- Update simulation parts if enabled
    if simulatePresence then
        esp.updateSimulationParts()
    end
    
    -- Get all items from the Items folder
    local items = {}
    
    -- Only look in the Items folder if it exists
    if workspace and workspace:FindFirstChild("Items") then
        for _, item in pairs(workspace.Items:GetChildren()) do
            -- Check if we should show all ores or only selected ones
            if item and (esp.trackAllOres or ores.isSelected(item)) then
                table.insert(items, item)
            end
        end
    else
        -- Fallback to searching all workspace descendants if Items folder doesn't exist
        for _, item in pairs(workspace:GetDescendants()) do
            if item:IsA("BasePart") and (esp.trackAllOres or ores.isSelected(item)) then
                table.insert(items, item)
            end
        end
    end
    
    -- Update existing ESP labels and create new ones
    for _, item in pairs(items) do
        -- Get item position
        local itemPosition
        if item:IsA("Model") and item.PrimaryPart then
            itemPosition = item.PrimaryPart.Position
        elseif item:IsA("BasePart") then
            itemPosition = item.Position
        else
            continue
        end
        
        -- Calculate distance
        local distance = utils.getDistance(playerPos, itemPosition)
        
        -- Only show ESP for items within max distance
        if distance <= config.espSettings.maxDistance then
            -- Create ESP if it doesn't exist
            if not espLabels[item] then
                esp.createLabel(item, distance)
            else
                -- Update existing label
                local label = espLabels[item]
                if label and label.TextLabel then
                    -- Get clean ore name
                    local cleanName = ores.getCleanOreName(item.Name)
                    
                    -- Determine ore tier for color and display
                    local oreTier = ores.getOreTier(item.Name)
                    
                    -- Update label text
                    local labelText = cleanName
                    if config.espSettings.showDistance then
                        labelText = labelText .. " [" .. utils.formatDistance(distance) .. "]"
                    end
                    
                    if config.espSettings.showRarity and oreTier ~= "Unknown" then
                        labelText = labelText .. " (" .. oreTier .. ")"
                    end
                    
                    label.TextLabel.Text = labelText
                    
                    -- Update color based on distance
                    local colorValue = math.clamp(1 - (distance / config.espSettings.maxDistance), 0, 1)
                    label.TextLabel.TextColor3 = Color3.new(1, colorValue, colorValue)
                end
            end
        end
    end
end

-- Create ESP label for an item
function esp.createLabel(item, distance)
    -- Create ESP label
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_" .. item.Name
    billboardGui.Adornee = item
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = item
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.TextColor3 = config.espSettings.textColor
    textLabel.TextStrokeColor3 = config.espSettings.outlineColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = config.espSettings.textSize
    textLabel.Font = Enum.Font.SourceSansBold
    
    -- Set label text
    local labelText = item.Name:gsub("_", " ")
    if config.espSettings.showDistance then
        labelText = labelText .. " [" .. utils.formatDistance(distance) .. "]" 
    end
    textLabel.Text = labelText
    
    -- Set color based on distance
    local colorValue = math.clamp(1 - (distance / config.espSettings.maxDistance), 0, 1)
    textLabel.TextColor3 = Color3.new(1, colorValue, colorValue)
    
    textLabel.Parent = billboardGui
    
    -- Store label for cleanup
    table.insert(espLabels, billboardGui)
end

-- Clear all ESP labels
function esp.clearLabels()
    for _, label in ipairs(espLabels) do
        pcall(function()
            label:Destroy()
        end)
    end
    
    espLabels = {}
end

return esp.init()
