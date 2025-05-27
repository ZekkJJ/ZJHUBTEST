--[[
    ZJ/HUB UI Module
    
    This module handles the user interface for the script.
]]--

local ui = {}

-- Services
local Players = game:GetService("Players")

-- Initialize UI
function ui.init(modules)
    local version = modules.version
    local ores = modules.ores
    local esp = modules.esp
    local config = modules.config
    
    -- Load Rayfield UI Library
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    -- Create Window with ZJ/HUB branding
    local Window = Rayfield:CreateWindow({
        Name = "ZJ/HUB v" .. version,
        LoadingTitle = "ZJ/HUB",
        LoadingSubtitle = "by NitezTJS",
        ConfigurationSaving = {
            Enabled = config.uiSettings.configSaving,
            FolderName = nil,
            FileName = config.uiSettings.configFileName
        },
        KeySystem = config.uiSettings.keySystem
    })
    
    -- Create tabs with better organization
    local InfoTab = Window:CreateTab("Info")
    local OresTab = Window:CreateTab("Ores")
    local BringTab = Window:CreateTab("Bring") 
    local ESPTab = Window:CreateTab("ESP")
    local ToolsTab = Window:CreateTab("Tools")
    local SettingsTab = Window:CreateTab("Settings")
    
    -- Info Tab
    InfoTab:CreateSection("Welcome to ZJ/HUB")
    
    InfoTab:CreateParagraph({
        Title = "About ZJ/HUB",
        Content = "ZJ/HUB is a powerful script for enhancing your gameplay experience. It provides ESP for ores, ore teleportation, and various utility tools."
    })
    
    InfoTab:CreateParagraph({
        Title = "How to Use",
        Content = "1. Select ores in the Ores tab\n2. Enable ESP in the ESP tab\n3. Use the Bring feature to teleport ores to you\n4. Explore other tools in the Tools tab"
    })
    
    InfoTab:CreateParagraph({
        Title = "Credits",
        Content = "Created by NitezTJS\nDiscord: discord.gg/Rcz3BKX9Hz"
    })
    
    -- Ores Tab
    OresTab:CreateSection("Ore Selection")
    
    -- Create toggles for all tiers
    for tier, _ in pairs(ores.tiers) do
        OresTab:CreateSection(tier .. " Ores")
        
        -- Create a toggle for the entire tier
        OresTab:CreateToggle({
            Name = "Select All " .. tier .. " Ores",
            CurrentValue = ores.selectedTiers[tier] or false,
            Flag = "Tier_" .. tier,
            Callback = function(value)
                ores.selectTier(tier, value)
            end,
        })
        
        -- Create toggles for each ore in the tier
        for _, oreName in ipairs(ores.tiers[tier]) do
            OresTab:CreateToggle({
                Name = oreName,
                CurrentValue = ores.selected[oreName] or false,
                Flag = "OreToggle_" .. oreName:gsub(" ", "_"),
                Callback = function(value)
                    ores.selectOre(oreName, value)
                end,
            })
        end
    end
    
    -- Bring Tab
    BringTab:CreateSection("Bring Ores to You")
    
    BringTab:CreateToggle({
        Name = "Enable Bring",
        CurrentValue = config.bringSettings.enabled,
        Flag = "BringEnabled",
        Callback = function(value)
            config.bringSettings.enabled = value
            
            -- Start or stop the bring loop
            if value then
                -- Check if any ores are selected
                local anySelected = false
                for _, selected in pairs(ores.selected) do
                    if selected then
                        anySelected = true
                        break
                    end
                end
                
                if not anySelected then
                    Rayfield:Notify({
                        Title = "No Ores Selected",
                        Content = "Please select at least one ore type to bring.",
                        Duration = 3,
                    })
                    config.bringSettings.enabled = false
                    return
                end
                
                Rayfield:Notify({
                    Title = "Bringing Ores",
                    Content = "Now bringing selected ores to you. Toggle off to stop.",
                    Duration = 3,
                })
                
                -- Create a loop to bring ores
                spawn(function()
                    while config.bringSettings.enabled do
                        ores.bringSelectedOres()
                        wait(config.bringSettings.bringInterval)
                    end
                end)
            else
                Rayfield:Notify({
                    Title = "Stopped Bringing",
                    Content = "No longer bringing ores to you.",
                    Duration = 2,
                })
            end
        end,
    })
    
    BringTab:CreateSlider({
        Name = "Bring Interval",
        Range = {0.1, 1},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = config.bringSettings.bringInterval,
        Flag = "BringInterval",
        Callback = function(value)
            config.bringSettings.bringInterval = value
        end,
    })
    
    BringTab:CreateSlider({
        Name = "Bring Distance",
        Range = {5, 100},
        Increment = 5,
        Suffix = " studs",
        CurrentValue = config.bringSettings.bringDistance,
        Flag = "BringDistance",
        Callback = function(value)
            config.bringSettings.bringDistance = value
        end,
    })
    
    BringTab:CreateSlider({
        Name = "Bring Speed",
        Range = {0.5, 4},
        Increment = 0.5,
        Suffix = "x",
        CurrentValue = config.bringSettings.bringSpeed,
        Flag = "BringSpeed",
        Callback = function(value)
            config.bringSettings.bringSpeed = value
        end,
    })
    
    BringTab:CreateButton({
        Name = "Bring Selected Ores Once",
        Callback = function()
            local success, message = ores.bringAllItems()
            if message then
                Rayfield:Notify({
                    Title = success and "Success" or "Error",
                    Content = message,
                    Duration = 3,
                })
            end
        end,
    })
    
    BringTab:CreateSection("Bring Aura")
    
    BringTab:CreateToggle({
        Name = "Enable Bring Aura",
        CurrentValue = config.bringSettings.bringAuraEnabled,
        Flag = "BringAuraEnabled",
        Callback = function(value)
            config.bringSettings.bringAuraEnabled = value
            
            if value then
                -- Check if any ores are selected
                local anySelected = false
                for _, selected in pairs(ores.selected) do
                    if selected then
                        anySelected = true
                        break
                    end
                end
                
                if not anySelected then
                    Rayfield:Notify({
                        Title = "No Ores Selected",
                        Content = "Please select at least one ore type for Bring Aura.",
                        Duration = 3,
                    })
                    config.bringSettings.bringAuraEnabled = false
                    return
                end
                
                Rayfield:Notify({
                    Title = "Bring Aura Enabled",
                    Content = "Bring Aura will automatically collect nearby selected ores.",
                    Duration = 3,
                })
                
                -- Create a loop for bring aura
                spawn(function()
                    local utils = require("utils")
                    
                    while config.bringSettings.bringAuraEnabled do
                        local playerPos = utils.getPlayerPosition()
                        if playerPos then
                            -- Find all ores in the workspace
                            if workspace and workspace:FindFirstChild("Items") then
                                for _, item in pairs(workspace.Items:GetChildren()) do
                                    if ores.isSelected(item) then
                                        -- Get item position
                                        local itemPosition
                                        if item:IsA("Model") and item.PrimaryPart then
                                            itemPosition = item.PrimaryPart.Position
                                        elseif item:IsA("BasePart") then
                                            itemPosition = item.Position
                                        else
                                            continue
                                        end
                                        
                                        -- Check if ore is within aura radius
                                        local distance = utils.getDistance(playerPos, itemPosition)
                                        if distance <= config.bringSettings.bringAuraRadius then
                                            -- Determine which part to tween
                                            local tweenPart
                                            if item:IsA("Model") and item.PrimaryPart then
                                                tweenPart = item.PrimaryPart
                                            elseif item:IsA("BasePart") then
                                                tweenPart = item
                                            else
                                                continue
                                            end
                                            
                                            -- Calculate tween duration based on distance and speed
                                            local limitedSpeed = math.min(config.bringSettings.bringAuraSpeed, 4)
                                            local duration = distance / (50 * limitedSpeed)
                                            
                                            -- Create and play tween
                                            local tween = utils.createTween(
                                                tweenPart,
                                                {
                                                    time = duration,
                                                    easing = Enum.EasingStyle.Quad,
                                                    direction = Enum.EasingDirection.Out
                                                },
                                                {
                                                    CFrame = CFrame.new(playerPos)
                                                }
                                            )
                                            tween:Play()
                                        end
                                    end
                                end
                            end
                        end
                        
                        wait(0.5) -- Wait before next aura check
                    end
                end)
            else
                Rayfield:Notify({
                    Title = "Bring Aura Disabled",
                    Content = "Bring Aura has been turned off.",
                    Duration = 2,
                })
            end
        end,
    })
    
    BringTab:CreateSlider({
        Name = "Aura Radius",
        Range = {10, 200},
        Increment = 10,
        Suffix = " studs",
        CurrentValue = config.bringSettings.bringAuraRadius,
        Flag = "BringAuraRadius",
        Callback = function(value)
            config.bringSettings.bringAuraRadius = value
        end,
    })
    
    BringTab:CreateSlider({
        Name = "Aura Speed",
        Range = {0.5, 4},
        Increment = 0.5,
        Suffix = "x",
        CurrentValue = config.bringSettings.bringAuraSpeed,
        Flag = "BringAuraSpeed",
        Callback = function(value)
            config.bringSettings.bringAuraSpeed = value
        end,
    })
    
    -- ESP Tab
    ESPTab:CreateSection("ESP Settings")
    
    ESPTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = config.espSettings.enabled,
        Flag = "ESPEnabled",
        Callback = function(value)
            config.espSettings.enabled = value
            esp.toggle(value)
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = config.espSettings.showDistance,
        Flag = "ShowDistance",
        Callback = function(value)
            config.espSettings.showDistance = value
        end,
    })
    
    ESPTab:CreateSlider({
        Name = "Max ESP Distance",
        Range = {100, 2000},
        Increment = 100,
        Suffix = " studs",
        CurrentValue = config.espSettings.maxDistance,
        Flag = "MaxESPDistance",
        Callback = function(value)
            config.espSettings.maxDistance = value
        end,
    })
    
    ESPTab:CreateSlider({
        Name = "Text Size",
        Range = {10, 24},
        Increment = 1,
        Suffix = "px",
        CurrentValue = config.espSettings.textSize,
        Flag = "TextSize",
        Callback = function(value)
            config.espSettings.textSize = value
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "Track All Ores",
        CurrentValue = config.espSettings.trackAllOres,
        Flag = "TrackAllOres",
        Callback = function(value)
            config.espSettings.trackAllOres = value
            esp.toggleTrackAllOres(value)
        end,
    })
    
    -- Simulation Controls
    ESPTab:CreateSection("Simulation Controls")
    
    ESPTab:CreateToggle({
        Name = "Enable Simulation Mode",
        CurrentValue = config.espSettings.simulatePresence,
        Flag = "SimulatePresence",
        Callback = function(value)
            config.espSettings.simulatePresence = value
            esp.toggleSimulatePresence(value)
        end,
    })
    
    ESPTab:CreateParagraph({
        Title = "What is Simulation Mode?",
        Content = "Simulation Mode creates temporary invisible parts around your character to reveal ores in a larger area. This helps you find ores that might be hidden or out of your normal ESP range."
    })
    
    ESPTab:CreateSlider({
        Name = "Simulation Radius",
        Range = {50, 300},
        Increment = 25,
        Suffix = " studs",
        CurrentValue = config.espSettings.simulationRadius,
        Flag = "SimulationRadius",
        Callback = function(value)
            config.espSettings.simulationRadius = value
            esp.setSimulationRadius(value)
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "Show Ore Rarity",
        CurrentValue = config.espSettings.showRarity,
        Flag = "ShowRarity",
        Callback = function(value)
            config.espSettings.showRarity = value
        end,
    })
    
    -- Tools Tab
    ToolsTab:CreateSection("Utility Tools")
    
    ToolsTab:CreateButton({
        Name = "Teleport to Random Ore",
        Callback = function()
            local utils = require("utils")
            local playerPos = utils.getPlayerPosition()
            if not playerPos then return end
            
            local character = Players.LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end
            
            local foundOres = {}
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("BasePart") and ores.isSelected(item) then
                    table.insert(foundOres, item)
                end
            end
            
            if #foundOres > 0 then
                local randomOre = foundOres[math.random(1, #foundOres)]
                character.HumanoidRootPart.CFrame = CFrame.new(randomOre.Position + Vector3.new(0, 5, 0))
                
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "Teleported to " .. randomOre.Name:gsub("_", " "),
                    Duration = 3
                })
            else
                Rayfield:Notify({
                    Title = "No Ores Found",
                    Content = "No selected ores were found in the workspace.",
                    Duration = 3
                })
            end
        end,
    })
    
    ToolsTab:CreateButton({
        Name = "Collect All Nearby Ores",
        Callback = function()
            local utils = require("utils")
            local playerPos = utils.getPlayerPosition()
            if not playerPos then return end
            
            local collectedCount = 0
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("BasePart") and ores.isSelected(item) then
                    local distance = utils.getDistance(playerPos, item.Position)
                    if distance <= 50 then
                        -- Create a tween to bring the ore to the player
                        local tween = utils.createTween(
                            item,
                            {time = 0.5},
                            {Position = playerPos}
                        )
                        tween:Play()
                        collectedCount = collectedCount + 1
                    end
                end
            end
            
            Rayfield:Notify({
                Title = "Collecting Ores",
                Content = "Collecting " .. collectedCount .. " nearby ores.",
                Duration = 3
            })
        end,
    })
    
    -- Settings Tab
    SettingsTab:CreateSection("Script Settings")
    
    SettingsTab:CreateToggle({
        Name = "Save Configuration",
        CurrentValue = config.uiSettings.configSaving,
        Flag = "SaveConfig",
        Callback = function(value)
            config.uiSettings.configSaving = value
        end,
    })
    
    SettingsTab:CreateToggle({
        Name = "Send User Info",
        CurrentValue = config.webhookSettings.sendUserInfo,
        Flag = "SendUserInfo",
        Callback = function(value)
            config.webhookSettings.sendUserInfo = value
        end,
    })
    
    SettingsTab:CreateParagraph({
        Title = "User Information Collection",
        Content = "ZJ/HUB collects basic user information for analytics purposes. This includes your username, user ID, and device information. This data helps us improve the script and prevent abuse."
    })
    
    SettingsTab:CreateButton({
        Name = "Reset All Settings",
        Callback = function()
            Rayfield:Destroy()
            ui.init(modules)
        end,
    })
    
    return ui
end

-- Create toggles for ores in a specific tier
function ui.createOresToggles(tab, tier, ores)
    -- Clear existing toggles
    for i, item in ipairs(tab:GetChildren()) do
        if item.Name:find("OreToggle_") then
            item:Destroy()
        end
    end
    
    -- Create a toggle for the entire tier
    tab:CreateToggle({
        Name = "Select All " .. tier .. " Ores",
        CurrentValue = ores.selectedTiers[tier] or false,
        Flag = "Tier_" .. tier,
        Callback = function(value)
            ores.selectTier(tier, value)
        end,
    })
    
    -- Create toggles for each ore in the tier
    if ores.tiers[tier] then
        for _, oreName in ipairs(ores.tiers[tier]) do
            tab:CreateToggle({
                Name = oreName,
                CurrentValue = ores.selected[oreName] or false,
                Flag = "OreToggle_" .. oreName:gsub(" ", "_"),
                Callback = function(value)
                    ores.selectOre(oreName, value)
                end,
            })
        end
    end
end

return ui
