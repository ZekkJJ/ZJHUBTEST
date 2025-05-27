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

-- Initialize ESP
function esp.init()
    esp.enabled = false
    esp.trackAllOres = false
    return esp
end

-- Toggle ESP
function esp.toggle(enabled)
    esp.enabled = enabled
    
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

-- Update ESP
function esp.update()
    if not esp.enabled then return end
    
    -- Get character's current position
    local playerPos = utils.getPlayerPosition()
    if not playerPos then return end
    
    -- Clear existing labels
    esp.clearLabels()
    
    -- Find all ores in the workspace
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and (esp.trackAllOres or ores.isSelected(item)) then
            -- Calculate distance from player to ore
            local distance = utils.getDistance(playerPos, item.Position)
            
            -- Only show ESP for items within max distance
            if distance <= config.espSettings.maxDistance then
                esp.createLabel(item, distance)
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
