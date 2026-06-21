local Window = getgenv().Window
local HttpService = game:GetService("HttpService")

local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

local DataTab = Window:Page({ Icon = "rbxassetid://129245697782918" })
local LeftSection = DataTab:Section({ Name = "Log Data", Side = 1 })

local selectedGhost = "Aswang"
local numInputs = {"", "", "", ""}
local pendingData = nil -- Holds the numbers between rounds

-- Label to show if data is pending
local StatusLabel = LeftSection:Label({ Name = "Status: No pending data" })

-- Dropdown for Ghosts
local GhostDropdown = LeftSection:Dropdown({
    Name = "Select Ghost",
    Items = demonologyGhosts,
    Default = "Aswang",
    Flag = "DataGhostSelect",
    Callback = function(val)
        selectedGhost = val
    end
})

-- ==========================================
-- FIX: MAKE DROPDOWN SHORTER FOR PC & MOBILE
-- ==========================================
GhostDropdown.MaxSize = 150 
local optionHolder = GhostDropdown.Items["OptionHolder"].Instance
optionHolder.AutomaticSize = Enum.AutomaticSize.None
optionHolder.Size = UDim2.new(0, 120, 0, 150)
optionHolder.ClipsDescendants = true

optionHolder.AncestryChanged:Connect(function()
    if optionHolder.Parent == getgenv().Library.UnusedHolder.Instance then
        local layout = optionHolder:FindFirstChildWhichIsA("UIListLayout")
        if layout then
            layout.Position = UDim2.new(0, 0, 0, 0)
        end
    end
end)
-- ==========================================

-- 4 Number Textboxes
for i = 1, 4 do
    LeftSection:Textbox({
        Name = "Number " .. i,
        Placeholder = "Enter number...",
        Numeric = true,
        Flag = "DataNum" .. i,
        Callback = function(val)
            numInputs[i] = val
        end
    })
end

-- Button 1: Save numbers to memory during the round
LeftSection:Button({
    Name = "Save Pending Numbers",
    Callback = function()
        pendingData = {
            numInputs[1] ~= "" and numInputs[1] or "0",
            numInputs[2] ~= "" and numInputs[2] or "0",
            numInputs[3] ~= "" and numInputs[3] or "0",
            numInputs[4] ~= "" and numInputs[4] or "0"
        }
        
        StatusLabel:SetText("Status: Pending " .. table.concat(pendingData, "-"))
        getgenv().Library:Notification("Numbers saved temporarily!", 3, Color3.fromRGB(255, 255, 0))
    end
})

-- Button 2: Assign the pending numbers to the ghost at the end of the round
LeftSection:Button({
    Name = "Assign Pending to Ghost",
    Callback = function()
        if not pendingData then
            getgenv().Library:Notification("No pending numbers to save!", 3, Color3.fromRGB(255, 0, 0))
            return
        end
        
        local fileData = {}
        if isfile("GhostData.json") then
            local success, decoded = pcall(function()
                return HttpService:JSONDecode(readfile("GhostData.json"))
            end)
            if success and type(decoded) == "table" then
                fileData = decoded
            end
        end
        
        if not fileData[selectedGhost] then
            fileData[selectedGhost] = {}
        end
        
        table.insert(fileData[selectedGhost], pendingData)
        writefile("GhostData.json", HttpService:JSONEncode(fileData))
        
        -- Clear pending data
        pendingData = nil
        StatusLabel:SetText("Status: No pending data")
        getgenv().Library:Notification("Saved data for " .. selectedGhost, 3, Color3.fromRGB(0, 255, 0))
    end
})

-- ==========================================
-- Right Side: Analyzing & Webhook (Unchanged)
-- ==========================================
local RightSection = DataTab:Section({ Name = "Analyze Data", Side = 2 })

local function GetAnalyzedData()
    if not isfile("GhostData.json") then
        return nil, "No data file found."
    end
    
    local success, fileData = pcall(function()
        return HttpService:JSONDecode(readfile("GhostData.json"))
    end)
    
    if not success or type(fileData) ~= "table" then
        return nil, "Failed to read data file."
    end

    local results = {}
    
    for ghostName, patterns in pairs(fileData) do
        local counts = {}
        local ghostPatternsList = {}
        
        for _, pat in ipairs(patterns) do
            local patStr = table.concat(pat, " | ")
            counts[patStr] = (counts[patStr] or 0) + 1
        end
        
        for patternStr, count in pairs(counts) do
            table.insert(ghostPatternsList, patternStr .. " (" .. count .. ")")
        end
        
        if #ghostPatternsList > 0 then
            results[ghostName] = table.concat(ghostPatternsList, "\n")
        else
            results[ghostName] = "No valid patterns"
        end
    end
    
    return results
end

local ResultsLabel

RightSection:Button({
    Name = "Analyze & Display Data",
    Callback = function()
        local results, err = GetAnalyzedData()
        if err then
            ResultsLabel:SetText(err)
            return
        end
        
        local displayText = "=== Logged Patterns ==="
        for ghostName, patternStr in pairs(results) do
            displayText = displayText .. "\n\n[" .. ghostName .. "]\n" .. patternStr
        end
        
        ResultsLabel:SetText(displayText)
        getgenv().Library:Notification("Data analyzed!", 3, Color3.fromRGB(78, 95, 255))
    end
})

RightSection:Button({
    Name = "Send to Discord Webhook",
    Callback = function()
        local results, err = GetAnalyzedData()
        if err then
            getgenv().Library:Notification(err, 3, Color3.fromRGB(255, 0, 0))
            return
        end
        
        local webhookURL = "YOUR_WEBHOOK_URL_HERE" 
        
        local messageContent = "=== Ghost Data Analysis ===\n"
        for ghostName, patternStr in pairs(results) do
            messageContent = messageContent .. "**" .. ghostName .. "**:\n" .. patternStr .. "\n\n"
        end
        
        local payload = HttpService:JSONEncode({
            ["content"] = messageContent
        })
        
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

ResultsLabel = RightSection:Label({ Name = "No data analyzed yet." })
