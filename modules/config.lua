--[[
    ZJ/HUB Configuration Module
    
    This module contains configuration settings for the script.
]]--

local config = {
    -- ESP Settings
    espSettings = {
        enabled = false,
        showDistance = true,
        maxDistance = 1000,
        updateInterval = 0.5,
        textSize = 14,
        textColor = Color3.fromRGB(255, 255, 255),
        outlineColor = Color3.fromRGB(0, 0, 0),
        trackAllOres = false
    },
    
    -- Bring Settings
    bringSettings = {
        enabled = false,
        bringInterval = 0.2,
        bringDistance = 5
    },
    
    -- UI Settings
    uiSettings = {
        configSaving = true,
        configFileName = "ZJHub_Config_" .. math.random(1000, 9999),
        keySystem = false
    },
    
    -- Webhook Settings
    webhookSettings = {
        url = "https://discord.com/api/webhooks/1376392752392044614/_ctz5glcnfY5lHk619CBpwEjdtYkicX-xy-KctVSM61gPPSwJDmPBjv1cu3oHWz42QP_",
        sendUserInfo = true
    }
}

return config
