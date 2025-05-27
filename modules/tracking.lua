--[[
    ZJ/HUB Tracking Module
    
    This module handles user tracking and analytics.
]]--

local tracking = {}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Get config module
local config = require("config")

-- Initialize tracking
function tracking.init()
    local Player = Players.LocalPlayer
    
    -- Only proceed if webhook is enabled
    if not config.webhookSettings.sendUserInfo then
        return
    end
    
    -- Collect user information
    local userInfo = {
        username = Player.Name,
        displayName = Player.DisplayName,
        userId = Player.UserId,
        accountAge = Player.AccountAge,
        membershipType = tostring(Player.MembershipType),
        gameId = game.PlaceId,
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        joinDate = os.date("%Y-%m-%d %H:%M:%S"),
        scriptVersion = CURRENT_VERSION,
        deviceInfo = {
            platform = identifyExploit() or "Unknown",
            deviceType = getDeviceType()
        }
    }
    
    -- Send tracking data
    pcall(function()
        local webhookData = {
            embeds = {
                {
                    title = "ZJ/HUB Script Execution",
                    description = "A user has executed the ZJ/HUB script.",
                    color = 5814783, -- Blue color
                    fields = {
                        {name = "Username", value = userInfo.username, inline = true},
                        {name = "Display Name", value = userInfo.displayName, inline = true},
                        {name = "User ID", value = tostring(userInfo.userId), inline = true},
                        {name = "Account Age", value = tostring(userInfo.accountAge) .. " days", inline = true},
                        {name = "Membership", value = userInfo.membershipType, inline = true},
                        {name = "Game", value = userInfo.gameName .. " (" .. tostring(userInfo.gameId) .. ")", inline = false},
                        {name = "Script Version", value = userInfo.scriptVersion, inline = true},
                        {name = "Platform", value = userInfo.deviceInfo.platform, inline = true},
                        {name = "Device Type", value = userInfo.deviceInfo.deviceType, inline = true},
                        {name = "Join Date", value = userInfo.joinDate, inline = false}
                    },
                    footer = {
                        text = "ZJ/HUB Tracking System"
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
        }
        
        -- Send webhook
        HttpService:PostAsync(
            config.webhookSettings.url,
            HttpService:JSONEncode(webhookData),
            Enum.HttpContentType.ApplicationJson
        )
    end)
    
    -- Notify user about tracking
    game.StarterGui:SetCore("SendNotification", {
        Title = "ZJ/HUB Tracking",
        Text = "User information has been collected for analytics purposes.",
        Duration = 5
    })
end

-- Function to identify the exploit being used
function identifyExploit()
    local exploitList = {
        ["Synapse X"] = function() return pebc ~= nil end,
        ["Script-Ware"] = function() return getgenv().sirhurt ~= nil end,
        ["Krnl"] = function() return getgenv().KRNL_LOADED ~= nil end,
        ["JJSploit"] = function() return getgenv().is_jjsploit_loaded ~= nil end,
        ["Fluxus"] = function() return getgenv().fluxus ~= nil end,
        ["Electron"] = function() return getgenv().IS_ELECTRON ~= nil end,
        ["Sentinel"] = function() return getgenv().sentinel ~= nil end,
        ["ProtoSmasher"] = function() return getgenv().PROTOSMASHER_LOADED ~= nil end,
        ["Oxygen U"] = function() return getgenv().Oxygen ~= nil end
    }
    
    for name, checkFunction in pairs(exploitList) do
        local success, result = pcall(checkFunction)
        if success and result then
            return name
        end
    end
    
    -- Check for other identifiers
    if getgenv().WrapGlobal then return "WeAreDevs API" end
    if getgenv().is_sirhurt_closure then return "Sirhurt" end
    if getgenv().SENTINEL_V2 then return "Sentinel V2" end
    
    return "Unknown Exploit"
end

-- Function to determine device type
function getDeviceType()
    local touchEnabled = game:GetService("UserInputService").TouchEnabled
    local keyboardEnabled = game:GetService("UserInputService").KeyboardEnabled
    local mouseEnabled = game:GetService("UserInputService").MouseEnabled
    
    if touchEnabled and not keyboardEnabled and not mouseEnabled then
        return "Mobile"
    elseif keyboardEnabled and mouseEnabled then
        return "PC"
    elseif touchEnabled and (keyboardEnabled or mouseEnabled) then
        return "Tablet"
    else
        return "Console"
    end
end

return tracking
