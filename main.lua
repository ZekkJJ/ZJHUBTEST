--[[
    ZJ/HUB Main Loader
    Version: 1.6
    Author: NitezTJS
    
    This is the main entry point for the ZJ/HUB script.
    It loads all modules using loadstring for obfuscation support.
]]--

-- Constants
local CURRENT_VERSION = "1.5"
local scriptName = "ZJHub_" .. math.random(1000, 9999)

-- Module URLs - Replace these with your actual URLs after obfuscating and hosting each module
local moduleUrls = {
    config = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/config.lua", -- Replace with actual URL
    utils = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/utils.lua", -- Replace with actual URL
    tracking = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/tracking.lua", -- Replace with actual URL
    ores = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/ores.lua", -- Replace with actual URL
    esp = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/esp.lua", -- Replace with actual URL
    ui = "https://raw.githubusercontent.com/NitezTJS/ZJHub/refs/heads/main/modules/ui.lua" -- Replace with actual URL
}

-- Initialize module cache
local moduleCache = {}

-- Function to load a module
local function loadModule(moduleName)
    if moduleCache[moduleName] then 
        return moduleCache[moduleName] 
    end
    
    if not moduleUrls[moduleName] then
        warn("Module URL not found: " .. moduleName)
        return nil
    end
    
    local success, moduleContent = pcall(function()
        return game:HttpGet(moduleUrls[moduleName])
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleName)
        return nil
    end
    
    local moduleFunc = loadstring(moduleContent)
    if not moduleFunc then
        warn("Failed to compile module: " .. moduleName)
        return nil
    end
    
    -- Create environment for the module
    local env = setmetatable({
        require = function(dependencyName)
            return loadModule(dependencyName)
        end,
        CURRENT_VERSION = CURRENT_VERSION,
        scriptName = scriptName
    }, {__index = getfenv()})
    
    -- Set the environment and run the module
    setfenv(moduleFunc, env)
    local module = moduleFunc()
    moduleCache[moduleName] = module
    
    return module
end

-- Load core modules
local config = loadModule("config")
local utils = loadModule("utils")
local tracking = loadModule("tracking")
local ores = loadModule("ores")
local esp = loadModule("esp")
local ui = loadModule("ui")

-- Check version before proceeding
if not utils.checkVersion(CURRENT_VERSION) then
    return
end

-- Initialize tracking
tracking.init()

-- Initialize UI
ui.init({
    version = CURRENT_VERSION,
    ores = ores,
    esp = esp,
    tracking = tracking,
    utils = utils,
    config = config
})

-- Print success message
print("ZJ/HUB v" .. CURRENT_VERSION .. " loaded successfully!")
