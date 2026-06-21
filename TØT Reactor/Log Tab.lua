local Window = getgenv().Window
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Define the ghost list again for this file
local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

-- Create the Data Logger Page
local DataTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- ==========================================
-- MOVED UP: Function to analyze the file
-- ==========================================
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
-- FIX: MAKE DROPDOWN SHORTER (150px) AND SCROLLABLE
-- ==========================================
GhostDropdown.MaxSize = 150 -- Prevents the UI library from erroring on nil size
local optionHolder = GhostDropdown.Items["OptionHolder"].Instance

-- Disable AutomaticSize so our fixed height applies
optionHolder.AutomaticSize = Enum.AutomaticSize.None
optionHolder.Size = UDim2.new(0, 120, 0, 150)
optionHolder.ClipsDescendants = true

-- Add custom scrolling logic for the UIListLayout
local layout = optionHolder:FindFirstChildWhichIsA("UIListLayout")
if layout then
    local isHovering = false
    optionHolder.MouseEnter:Connect(function() isHovering = true end)
    optionHolder.MouseLeave:Connect(function() isHovering = false end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isHovering and input.UserInputType == Enum.UserInputType.MouseWheel then
            -- Calculate how far down we can scroll
            local maxY = (#demonologyGhosts * 28) - 150
            if maxY < 0 then maxY = 0 end
            
            local currentY = layout.Position.Y.Offset
            local newY = math.clamp(currentY + (input.Position.Z * 30), -maxY, 0)
            layout.Position = UDim2.new(0, 0, 0, newY)
        end
    end)
    
    -- Reset scroll position when dropdown closes
    optionHolder.AncestryChanged:Connect(function()
        if optionHolder.Parent == getgenv().Library.UnusedHolder.Instance then
            layout.Position = UDim2.new(0, 0, 0, 0)
        end
    end)
end
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

-- Forward declare the label so the buttons can edit it, even though it's created at the bottom
local ResultsLabel

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

-- Create the Results Label LAST so it visually appears below the buttons
ResultsLabel = RightSection:Label({ Name = "No data analyzed yet." })
