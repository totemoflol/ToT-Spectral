local Window = getgenv().Window
local HttpService = game:GetService("HttpService")

-- Safety check
if not Window then
    warn("DataLogger: Window not found! Make sure loader.lua ran first.")
    return
end

local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

-- ==========================================
-- FUNCTIONS DEFINED AT THE TOP
-- ==========================================
local function GetCurrentGhostRoom()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("FavoriteRoom") ~= nil then
            return tostring(obj:GetAttribute("FavoriteRoom") or "Unknown")
        end
    end
    return "Unknown"
end

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
            local roomStr = pat.Room or "Unknown"
            local numStr = table.concat(pat.Numbers, " | ")
            local fullStr = "Room: " .. roomStr .. " | Numbers: " .. numStr
            
            counts[fullStr] = (counts[fullStr] or 0) + 1
        end
        
        for patternStr, count in pairs(counts) do
            table.insert(ghostPatternsList, patternStr .. " (Found " .. count .. " times)")
        end
        
        if #ghostPatternsList > 0 then
            results[ghostName] = table.concat(ghostPatternsList, "\n")
        else
            results[ghostName] = "No valid patterns"
        end
    end
    
    return results
end
-- ==========================================

-- Create the Data Logger Page
local DataTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Logging
local LeftSection = DataTab:Section({ Name = "Log Data", Side = 1 })

local selectedGhost = "Aswang"
local numInputs = {"", "", "", ""}
local pendingData = nil 

local StatusLabel = LeftSection:Label({ Name = "Status: No pending data" })

-- ==========================================
-- TEXTBOX WITH REAL-TIME AUTO-COMPLETE
-- ==========================================
local GhostTextbox = LeftSection:Textbox({
    Name = "Select Ghost",
    Placeholder = "Type ghost name...",
    Default = "Aswang",
    Flag = "DataGhostSelect",
    Callback = function(val)
        selectedGhost = val
    end
})

-- Access the internal TextBox to hook typing events
local inputInstance = GhostTextbox.Items["Input"].Instance
local isUpdating = false
local oldLen = 0

inputInstance:GetPropertyChangedSignal("Text"):Connect(function()
    if isUpdating then return end
    
    local text = inputInstance.Text
    local newLen = #text
    
    -- Only auto-complete if the user is typing forward
    if newLen > oldLen and newLen > 0 then
        local lowerText = string.lower(text)
        local match = nil
        local matchCount = 0
        
        -- Find ghosts that start with what they typed
        for _, ghost in ipairs(demonologyGhosts) do
            if string.sub(string.lower(ghost), 1, #lowerText) == lowerText then
                match = ghost
                matchCount = matchCount + 1
            end
        end
        
        -- If exactly one ghost matches, auto-complete it
        if matchCount == 1 and lowerText ~= string.lower(match) then
            isUpdating = true
            
            inputInstance.Text = match
            
            -- Highlight the auto-completed part so they can type over it if it's wrong
            inputInstance.CursorPosition = newLen + 1
            inputInstance.SelectionStart = #match + 1
            
            isUpdating = false
            oldLen = #match
            return
        end
    end
    
    oldLen = newLen
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

-- Button 1: Save numbers AND room to memory during the round
LeftSection:Button({
    Name = "Save Pending Numbers",
    Callback = function()
        local currentRoom = GetCurrentGhostRoom()
        
        pendingData = {
            Room = currentRoom,
            Numbers = {
                numInputs[1] ~= "" and numInputs[1] or "0",
                numInputs[2] ~= "" and numInputs[2] or "0",
                numInputs[3] ~= "" and numInputs[3] or "0",
                numInputs[4] ~= "" and numInputs[4] or "0"
            }
        }
        
        StatusLabel:SetText("Status: Pending [" .. currentRoom .. "] " .. table.concat(pendingData.Numbers, "-"))
        getgenv().Library:Notification("Numbers & Room saved!", 3, Color3.fromRGB(255, 255, 0))
    end
})

-- Button 2: Assign the pending data to the ghost at the end of the round
LeftSection:Button({
    Name = "Assign Pending to Ghost",
    Callback = function()
        if not pendingData then
            getgenv().Library:Notification("No pending data to save!", 3, Color3.fromRGB(255, 0, 0))
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
        
        pendingData = nil
        StatusLabel:SetText("Status: No pending data")
        getgenv().Library:Notification("Saved data for " .. selectedGhost, 3, Color3.fromRGB(0, 255, 0))
    end
})

-- ==========================================
-- Right Side: Analyzing & Webhook
-- ==========================================
local RightSection = DataTab:Section({ Name = "Analyze Data", Side = 2 })

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
        
        local webhookURL = "https://discord.com/api/webhooks/1517845813152186370/1-h_g2Qw5NB2tSnKmgBnK8CVxbRuRALldBXnGw2vc5B2v3sL-pg06EHypyKx4uIxaS0i" 
        
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
