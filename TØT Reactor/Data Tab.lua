local Window = getgenv().Window
local HttpService = game:GetService("HttpService")

-- Safety check
if not Window then
    warn("DataLogger: Window not found! Make sure loader.lua ran first.")
    return
end

-- Create the Spectral folder in the executor workspace
if not isfolder("Spectral") then
    makefolder("Spectral")
end

local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

-- ==========================================
-- AUTO-CORRECT LOGIC (Triggers on Enter/FocusLost)
-- ==========================================
local function levenshtein(str1, str2)
    local len1, len2 = #str1, #str2
    local char1, char2, dist, row, diag, ch1, ch2
    
    if len1 == 0 then return len2 end
    if len2 == 0 then return len1 end
    
    local matrix = {}
    for i = 0, len1 do matrix[i] = {} end
    for i = 0, len1 do matrix[i][0] = i end
    for j = 0, len2 do matrix[0][j] = j end
    
    for i = 1, len1 do
        char1 = string.sub(str1, i, i)
        for j = 1, len2 do
            char2 = string.sub(str2, j, j)
            dist = char1 == char2 and 0 or 1
            matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + dist)
        end
    end
    return matrix[len1][len2]
end

local function getValidGhostName(input)
    if not input or input == "" then return nil end
    local lowerInput = string.lower(input)
    
    -- 1. Check for exact match
    for _, ghost in ipairs(demonologyGhosts) do
        if lowerInput == string.lower(ghost) then
            return ghost
        end
    end
    
    -- 2. Check for prefix match (e.g., "Asw" -> "Aswang")
    if #lowerInput >= 3 then
        local matchCount = 0
        local bestMatch = nil
        for _, ghost in ipairs(demonologyGhosts) do
            if string.sub(string.lower(ghost), 1, #lowerInput) == lowerInput then
                matchCount = matchCount + 1
                bestMatch = ghost
            end
        end
        if matchCount == 1 then
            return bestMatch
        end
    end
    
    -- 3. Fallback to Levenshtein for typos (e.g., "Banshe" -> "Banshee")
    local bestMatch = nil
    local bestDist = math.huge
    for _, ghost in ipairs(demonologyGhosts) do
        local dist = levenshtein(lowerInput, string.lower(ghost))
        if dist < bestDist then
            bestDist = dist
            bestMatch = ghost
        end
    end
    
    if bestDist <= 2 then -- Allow up to 2 typos
        return bestMatch
    end
    
    return nil
end
-- ==========================================

-- ==========================================
-- FILE AND DATA FUNCTIONS
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
    if not isfile("Spectral/GhostData.json") then
        return nil, "No data file found."
    end
    
    local success, fileData = pcall(function()
        return HttpService:JSONDecode(readfile("Spectral/GhostData.json"))
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

-- Check if pending data exists from a previous server
local function CheckPendingStatus()
    if isfile("Spectral/PendingData.json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("Spectral/PendingData.json"))
        end)
        if success and data then
            local numStr = table.concat(data.Numbers, "-")
            return "Status: Pending [" .. (data.Room or "Unknown") .. "] " .. numStr
        end
    end
    return "Status: No pending data"
end

local StatusLabel = LeftSection:Label({ Name = CheckPendingStatus() })

-- Textbox for Ghosts (Corrects on Enter / FocusLost)
local GhostTextbox = LeftSection:Textbox({
    Name = "Select Ghost",
    Placeholder = "Type name & press Enter",
    Default = "Aswang",
    Flag = "DataGhostSelect",
    Finished = true, -- Fires when you press Enter or click away
    Callback = function(val)
        local corrected = getValidGhostName(val)
        if corrected then
            selectedGhost = corrected
            getgenv().Library:Notification("Ghost set to: " .. corrected, 2, Color3.fromRGB(255, 255, 0))
        else
            getgenv().Library:Notification("Unknown ghost! Defaulting to Aswang.", 3, Color3.fromRGB(255, 0, 0))
            selectedGhost = "Aswang"
        end
    end
})

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

-- Button 1: Save numbers AND room to FILE (Survives server changes)
LeftSection:Button({
    Name = "Save Pending Numbers",
    Callback = function()
        local currentRoom = GetCurrentGhostRoom()
        
        local pendingData = {
            Room = currentRoom,
            Numbers = {
                numInputs[1] ~= "" and numInputs[1] or "0",
                numInputs[2] ~= "" and numInputs[2] or "0",
                numInputs[3] ~= "" and numInputs[3] or "0",
                numInputs[4] ~= "" and numInputs[4] or "0"
            }
        }
        
        -- Save to the Spectral folder so it persists across server changes
        writefile("Spectral/PendingData.json", HttpService:JSONEncode(pendingData))
        
        StatusLabel:SetText("Status: Pending [" .. currentRoom .. "] " .. table.concat(pendingData.Numbers, "-"))
        getgenv().Library:Notification("Numbers & Room saved to file!", 3, Color3.fromRGB(255, 255, 0))
    end
})

-- Button 2: Assign the pending data to the ghost at the end of the round
LeftSection:Button({
    Name = "Assign Pending to Ghost",
    Callback = function()
        if not isfile("Spectral/PendingData.json") then
            getgenv().Library:Notification("No pending data found!", 3, Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Read the pending data from the file
        local success, pendingData = pcall(function()
            return HttpService:JSONDecode(readfile("Spectral/PendingData.json"))
        end)
        
        if not success or not pendingData then
            getgenv().Library:Notification("Pending file is corrupted!", 3, Color3.fromRGB(255, 0, 0))
            return
        end
        
        local fileData = {}
        if isfile("Spectral/GhostData.json") then
            local decodeSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(readfile("Spectral/GhostData.json"))
            end)
            if decodeSuccess and type(decoded) == "table" then
                fileData = decoded
            end
        end
        
        if not fileData[selectedGhost] then
            fileData[selectedGhost] = {}
        end
        
        table.insert(fileData[selectedGhost], pendingData)
        writefile("Spectral/GhostData.json", HttpService:JSONEncode(fileData))
        
        -- Delete the pending file so it's fresh for the next round
        delfile("Spectral/PendingData.json")
        
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
