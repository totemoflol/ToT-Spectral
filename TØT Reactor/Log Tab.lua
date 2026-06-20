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
-- DROPDOWN SCROLL FIX
-- ==========================================
local function fixDropdownScroll(dropdownObj)
    local container = dropdownObj.Container 
        or dropdownObj.Frame 
        or dropdownObj.List 
        or dropdownObj.Content 
        or dropdownObj.OptionsContainer

    if not container and dropdownObj.Instance then
        container = dropdownObj.Instance:FindFirstChildWhichIsA("ScrollingFrame") 
            or dropdownObj.Instance:FindFirstChildWhichIsA("Frame")
    end

    if container and (container:IsA("ScrollingFrame") or container:IsA("Frame")) then
        container.Size = UDim2.new(1, 0, 0, 150) 
        
        if container:IsA("ScrollingFrame") then
            container.CanvasSize = UDim2.new(0, 0, 0, 0)
            container.AutomaticCanvasSize = Enum.AutomaticSize.Y
            container.ScrollBarThickness = 5
            container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        else
            warn("[Dropdown Fix] The dropdown uses a standard Frame, not a ScrollingFrame.")
        end
    end
end
task.defer(fixDropdownScroll, GhostDropdown)
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

-- Save to Device Button
LeftSection:Button({
    Name = "Save to Device",
    Callback = function()
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
        
        -- Save exactly in the order A, B, C, D
        table.insert(fileData[selectedGhost], {
            numInputs[1] ~= "" and numInputs[1] or "0",
            numInputs[2] ~= "" and numInputs[2] or "0",
            numInputs[3] ~= "" and numInputs[3] or "0",
            numInputs[4] ~= "" and numInputs[4] or "0"
        })
        
        writefile("GhostData.json", HttpService:JSONEncode(fileData))
        getgenv().Library:Notification("Saved data for " .. selectedGhost, 3, Color3.fromRGB(0, 255, 0))
    end
})

-- Right Side: Analyzing & Webhook
local RightSection = DataTab:Section({ Name = "Analyze Data", Side = 2 })

local ResultsLabel = RightSection:Label({ Name = "No data analyzed yet." })

-- Function to analyze the file
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
        
        -- Count how many times each exact pattern appears
        for _, pat in ipairs(patterns) do
            -- Join A, B, C, D with " | "
            local patStr = table.concat(pat, " | ")
            counts[patStr] = (counts[patStr] or 0) + 1
        end
        
        -- Format them as "1 | 2 | 3 | 4 (Count)"
        for patternStr, count in pairs(counts) do
            table.insert(ghostPatternsList, patternStr .. " (" .. count .. ")")
        end
        
        -- If the ghost has multiple different patterns logged, list them all
        if #ghostPatternsList > 0 then
            results[ghostName] = table.concat(ghostPatternsList, "\n")
        else
            results[ghostName] = "No valid patterns"
        end
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
        
        local displayText = "=== Logged Patterns ==="
        for ghostName, patternStr in pairs(results) do
            displayText = displayText .. "\n\n[" .. ghostName .. "]\n" .. patternStr
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
            -- Discord formatting
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
