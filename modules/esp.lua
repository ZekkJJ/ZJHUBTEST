--[[
    ZJ/HUB ESP Module - Simplified Version
    
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
local espEnabled = false

-- Initialize ESP module
function esp.init()
    esp.trackAllOres = false
    return esp
end

-- Toggle ESP functionality
function esp.toggle(enabled)
    espEnabled = enabled
    
    if enabled then
        -- Start ESP update loop if not already running
        if not updateConnection then
            updateConnection = RunService.Heartbeat:Connect(function()
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

-- Toggle tracking all ores
function esp.toggleTrackAllOres(enabled)
    esp.trackAllOres = enabled
    if espEnabled then
        esp.clearLabels() -- Refresh ESP when changing tracking mode
    end
end

-- Update ESP labels
function esp.update()
    if not espEnabled then return end
    
    -- Get player position
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local playerPos = character.HumanoidRootPart.Position
    
    -- Remove labels for items that no longer exist
    for i = #espLabels, 1, -1 do
        local labelInfo = espLabels[i]
        if not labelInfo.item or not labelInfo.item.Parent or not labelInfo.gui.Parent then
            if labelInfo.gui and labelInfo.gui.Parent then
                labelInfo.gui:Destroy()
            end
            table.remove(espLabels, i)
        end
    end
    
    -- Only proceed if Items folder exists
    if not workspace:FindFirstChild("Items") then return end
    
    -- Process items in the Items folder
    for _, item in pairs(workspace.Items:GetChildren()) do
        -- Skip items that aren't selected (unless tracking all)
        if not (esp.trackAllOres or ores.isSelected(item)) then continue end
        
        -- Skip items that already have ESP
        local hasLabel = false
        for _, labelInfo in ipairs(espLabels) do
            if labelInfo.item == item then
                hasLabel = true
                break
            end
        end
        if hasLabel then continue end
        
        -- Get item position
        local itemPosition
        if item:IsA("Model") and item.PrimaryPart then
            itemPosition = item.PrimaryPart.Position
        elseif item:IsA("BasePart") then
            itemPosition = item.Position
        else
            continue -- Skip items without a valid position
        end
        
        -- Calculate distance
        local distance = (itemPosition - playerPos).Magnitude
        
        -- Only show ESP for items within max distance
        if distance <= config.espSettings.maxDistance then
            -- Create ESP label
            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Name = "ESP_Label"
            billboardGui.AlwaysOnTop = true
            billboardGui.Size = UDim2.new(0, 100, 0, 30)
            billboardGui.StudsOffset = Vector3.new(0, 2, 0)
            
            -- Determine which part to attach the label to
            if item:IsA("Model") and item.PrimaryPart then
                billboardGui.Adornee = item.PrimaryPart
            else
                billboardGui.Adornee = item
            end
            
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
            local cleanName = ores.getCleanOreName(item.Name)
            local labelText = cleanName
            
            if config.espSettings.showDistance then
                labelText = labelText .. " [" .. math.floor(distance) .. "]"
            end
            
            textLabel.Text = labelText
            textLabel.Parent = billboardGui
            
            -- Add to game
            billboardGui.Parent = item
            
            -- Store label info for cleanup
            table.insert(espLabels, {
                gui = billboardGui,
                item = item
            })
        end
    end
end

-- Clear all ESP labels
function esp.clearLabels()
    for _, labelInfo in ipairs(espLabels) do
        if labelInfo.gui and labelInfo.gui.Parent then
            labelInfo.gui:Destroy()
        end
    end
    
    espLabels = {}
end

return esp.init()
