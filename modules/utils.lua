--[[
    ZJ/HUB Utilities Module
    
    This module contains utility functions used throughout the script.
]]--

local utils = {}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Player reference
local Player = Players.LocalPlayer

-- Anti-detection: Metamethod hooking (with pcall for safety)
function utils.setupAntiDetection(scriptName)
    pcall(function()
        local mt = getrawmetatable(game)
        if mt then
            local oldIndex = mt.__index
            local oldNamecall = mt.__namecall
            
            -- Only proceed if we can modify the metatable
            pcall(function() setreadonly(mt, false) end)
            
            -- Create a random variable name for our functions
            local funcNames = {}
            for i = 1, 5 do
                funcNames[i] = string.char(math.random(97, 122)) .. string.char(math.random(97, 122)) .. 
                               string.char(math.random(97, 122)) .. string.char(math.random(97, 122))
            end
            
            -- Hook __namecall to avoid detection
            pcall(function()
                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    local args = {...}
                    
                    -- Avoid detection of our script
                    if method == "FindFirstChild" or method == "FindFirstChildOfClass" or method == "FindFirstChildWhichIsA" then
                        if args[1] == scriptName then
                            return nil
                        end
                    end
                    
                    -- Avoid detection when checking for scripts
                    if method == "GetChildren" or method == "GetDescendants" then
                        local results = oldNamecall(self, ...)
                        local filtered = {}
                        
                        for i, v in ipairs(results) do
                            if v.Name ~= scriptName then
                                table.insert(filtered, v)
                            end
                        end
                        
                        return filtered
                    end
                    
                    return oldNamecall(self, ...)
                end)
            end)
            
            -- Hook __index to avoid detection
            pcall(function()
                mt.__index = newcclosure(function(self, key)
                    -- Avoid detection by hiding our variables
                    if key == scriptName or table.find(funcNames, key) then
                        return nil
                    end
                    
                    return oldIndex(self, key)
                end)
            end)
            
            -- Set metatable back to readonly
            pcall(function() setreadonly(mt, true) end)
        end
    end)
end

-- Version checking function
function utils.checkVersion(currentVersion)
    -- Define version URL - using a reliable URL that exists
    local VERSION_URL = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/version"
    
    -- Try to get the latest version
    local success, result = pcall(function()
        return game:HttpGet(VERSION_URL)
    end)
    
    -- If we couldn't get the version, just continue with the script
    if not success then
        print("Failed to check for updates: " .. tostring(result))
        return true
    end
    
    -- Clean up the version string
    local latestVersion = result:gsub("[\n\r\t ]+", "")
    
    -- Compare versions
    if latestVersion ~= currentVersion then
        -- Set Discord link
        local discordLink = "https://discord.gg/Rcz3BKX9Hz"
        
        -- Copy to clipboard
        pcall(function()
            setclipboard(discordLink)
        end)
        
        -- Show warning message
        game.StarterGui:SetCore("SendNotification", {
            Title = "Version Outdated",
            Text = "Your script is outdated! Discord link copied to clipboard. Closing in 3 seconds...",
            Duration = 3
        })
        
        -- Wait 3 seconds and kick
        task.delay(3, function()
            pcall(function()
                game.Players.LocalPlayer:Kick("Script outdated! Please get the latest version from our Discord: " .. discordLink)
            end)
        end)
        
        return false
    end
    
    return true
end

-- Get distance between two Vector3 positions
function utils.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Format distance to a readable string
function utils.formatDistance(distance)
    if distance < 1000 then
        return string.format("%.1f", distance)
    else
        return string.format("%.1f", distance / 1000) .. "k"
    end
end

-- Get player's position
function utils.getPlayerPosition()
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end
    
    return character.HumanoidRootPart.Position
end

-- Create a tween for smooth animations
function utils.createTween(object, info, properties)
    local tweenInfo = TweenInfo.new(
        info.time or 1,
        info.easing or Enum.EasingStyle.Quad,
        info.direction or Enum.EasingDirection.Out,
        info.repeatCount or 0,
        info.reverses or false,
        info.delay or 0
    )
    
    local tween = TweenService:Create(object, tweenInfo, properties)
    return tween
end

return utils
