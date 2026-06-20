local Window = getgenv().Window
local HttpService = game:GetService("HttpService")

-- Define the ghost list again for this file
local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

-- Create the Data Logger Page
local DataTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Logging
local LeftSection = DataTab:Section({ Name = "Log Data", Side = 1 })

local selectedGhost = "Aswang"
local numInputs = {"", "", "", ""}

-- Dropdown for Ghosts
LeftSection:Dropdown({
    Name = "Select Ghost",
    Items = demonologyGhosts,
    Default = "Aswang",
    Flag = "DataGhostSelect",
    Callback = function(val)
        selectedGhost = val
    end
})

-- 4 Number Textboxes
for i = 1, 4 do
    LeftSection:Textbox({
        Name = "Number " .. i,
        Placeholder = "Enter number...",
        Numeric = true, -- Forces only numbers to be typed
        Flag = "DataNum" .. i,
        Callback = function(val)
            numInputs[i] = val
        end
    })
end

-- Save to Device Button
LeftSection:Button({
    Name = "Save to Device",
    Callback = function()
        -- Read existing data
        local fileData = {}
        if isfile("GhostData.json") then
            local success, decoded = pcall(function()
                return HttpService:JSONDecode(readfile("GhostData.json"))
            end)
            if success and type(decoded) == "table" then
                fileData = decoded
            end
        end
        
        -- Ensure ghost has a table
        if not fileData[selectedGhost] then
            fileData[selectedGhost] = {}
        end
        
        -- Insert new pattern
        table.insert(fileData[selectedGhost], {
            numInputs[1] or "0",
            numInputs[2] or "0",
            numInputs[3] or "0",
            numInputs[4] or "0"
        })
        
        -- Save back to file
        writefile("GhostData.json", HttpService:JSONEncode(fileData))
        getgenv().Library:Notification("Saved data for " .. selectedGhost, 3, Color3.fromRGB(0, 255, 0))
    end
})


-- Right Side: Analyzing & Webhook
local RightSection = DataTab:Section({ Name = "Analyze Data", Side = 2 })

local ResultsLabel = RightSection:Label({ Name = "No data analyzed yet." })

-- Function to analyze the file and get the most common pattern
local function GetAnalyzedData()
    if not isfile("GhostData.json") then
        return nil, "No data file found."
    end
    
    local fileData = HttpService:JSONDecode(readfile("GhostData.json"))
    local results = {}
    
    for ghostName, patterns in pairs(fileData) do
        local counts = {}
        local maxCount = 0
        local bestPattern = "None"
        
        for _, pat in ipairs(patterns) do
            local patStr = table.concat(pat, "-")
            counts[patStr] = (counts[patStr] or 0) + 1
            
            if counts[patStr] > maxCount then
                maxCount = counts[patStr]
                bestPattern = patStr
            end
        end
        
        results[ghostName] = bestPattern .. " (Found " .. maxCount .. " times)"
    end
    
    return results
end

-- Analyze Button
RightSection:Button({
    Name = "Analyze & Display Data",
    Callback = function()
        local results, err = GetAnalyzedData()
        if err then
            ResultsLabel:SetText(err)
            return
        end
        
        local displayText = "=== Most Common Patterns ==="
        for ghostName, patternStr in pairs(results) do
            displayText = displayText .. "\n" .. ghostName .. ": " .. patternStr
        end
        
        ResultsLabel:SetText(displayText)
        getgenv().Library:Notification("Data analyzed!", 3, Color3.fromRGB(78, 95, 255))
    end
})

-- Send to Webhook Button
RightSection:Button({
    Name = "Send to Discord Webhook",
    Callback = function()
        local results, err = GetAnalyzedData()
        if err then
            getgenv().Library:Notification(err, 3, Color3.fromRGB(255, 0, 0))
            return
        end
        
        local webhookURL = "YOUR_WEBHOOK_URL_HERE" -- <--- PASTE YOUR WEBHOOK HERE
        
        local messageContent = "=== Ghost Data Analysis ===\n"
        for ghostName, patternStr in pairs(results) do
            messageContent = messageContent .. "**" .. ghostName .. "**: " .. patternStr .. "\n"
        end
        
        local payload = HttpService:JSONEncode({
            ["content"] = messageContent
        })
        
        -- Send the request
        pcall(function()
            (syn and syn.request or http_request or http.request or fluxus.request)({
                Url = webhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
        
        getgenv().Library:Notification("Sent to Discord!", 3, Color3.fromRGB(0, 255, 0))
    end
})
