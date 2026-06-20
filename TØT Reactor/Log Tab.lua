local Window = getgenv().Window

-- Create the Status Page
local StatusTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Ghost Info
local StatusSection = StatusTab:Section({ Name = "Ghost Info", Side = 1 })

local RoomLabel = StatusSection:Label({ Name = "Favorite Room: Unknown" })
local GenderLabel = StatusSection:Label({ Name = "Gender: Unknown" })

local hasRoomBeenSet = false
local hookedGhost = nil

-- Right Side: Ghost List
local GhostsSection = StatusTab:Section({ Name = "Demonology Ghosts", Side = 2 })

-- ==========================================
-- SCROLL FIX
-- ==========================================
local function forceScrolling(sectionObj)
    -- Attempt to find the internal container frame of the section
    local container = sectionObj.Container or sectionObj.Frame or sectionObj.Instance or sectionObj.Content
    
    if container and container:IsA("ScrollingFrame") then
        -- Automatically expands the canvas height when labels are added
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        -- Makes the scrollbar visible and styled
        container.ScrollBarThickness = 5
        container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        container.ScrollBarImageTransparency = 0
        
        -- OPTIONAL: If it still stretches the page, uncomment the line below 
        -- and change '300' to your desired max height for the list.
        -- container.Size = UDim2.new(1, -20, 0, 300)
    else
        warn("[Scroll Fix Failed] The UI library didn't use a ScrollingFrame for this section.")
    end
end
forceScrolling(GhostsSection)
-- ==========================================

local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

local GhostLabels = {}

for _, ghostName in ipairs(demonologyGhosts) do
    GhostLabels[ghostName] = GhostsSection:Label({ Name = ghostName })
end

-- Made Global so other files can grey out ghosts!
getgenv().SetGhostGreyedOut = function(ghostName, isGreyed)
    local labelObj = GhostLabels[ghostName]
    if labelObj and labelObj.Items["Text"] then
        if isGreyed then
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(80, 80, 80)
        else
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- Room to Ghost mapping (all lowercase to prevent case issues)
local RoomGhostMap = {
    ["pantry"] = { "Leviathan", "Revenant", "Umbra" },
    ["kitchen"] = { "Siren", "Aswang", "Dybbuk", "The Wisp" },
    ["laundry room"] = { "Entity", "Nightmare", "Ghoul" },
    ["bathroom"] = { "Shadow", "Phantom", "Oni", "Skinwalker" },
    ["office"] = { "Spirit", "Specter", "Banshee" },
    ["bedroom"] = { "Wendigo", "Demon", "Wraith" }
}

-- Function to handle greying out ghosts based on room AND gender
local function FilterGhostsByRoom(roomName, currentGender)
    local normalizedRoom = string.lower(tostring(roomName))
    local validGhosts = RoomGhostMap[normalizedRoom]
    
    if validGhosts then
        local isValid = {}
        for _, ghost in ipairs(validGhosts) do
            isValid[ghost] = true
        end
        
        for _, ghostName in ipairs(demonologyGhosts) do
            -- Check if ghost is valid for the room
            local shouldBeWhite = isValid[ghostName] or false
            
            -- Override to grey if gender is Male and ghost is Siren or Keres
            if currentGender == "Male" and (ghostName == "Siren" or ghostName == "Keres") then
                shouldBeWhite = false
            end
            
            getgenv().SetGhostGreyedOut(ghostName, not shouldBeWhite)
        end
    else
        -- If room isn't in the list, make them all white again
        for _, ghostName in ipairs(demonologyGhosts) do
            getgenv().SetGhostGreyedOut(ghostName, false)
        end
    end
end

-- Function to update Ghost Info (Made Global)
getgenv().UpdateGhostStatus = function(ghostModel)
    if not ghostModel then return end
    
    local currentGender = tostring(ghostModel:GetAttribute("Gender") or "Unknown")
    
    if not hasRoomBeenSet then
        local favRoom = tostring(ghostModel:GetAttribute("FavoriteRoom") or "Unknown")
        if favRoom ~= "Unknown" then
            RoomLabel:SetText("Favorite Room: " .. favRoom)
            hasRoomBeenSet = true
            
            -- Run the filter as soon as we get the room!
            FilterGhostsByRoom(favRoom, currentGender)
        end
    end
    
    GenderLabel:SetText("Gender: " .. currentGender)
end

-- Auto-search loop to find the ghost and hook its attributes
task.spawn(function()
    while task.wait(1) do
        if hookedGhost and hookedGhost.Parent then 
            continue 
        end
        
        -- Reset for a new round
        hookedGhost = nil
        hasRoomBeenSet = false
        RoomLabel:SetText("Favorite Room: Unknown")
        GenderLabel:SetText("Gender: Unknown")
        
        -- Reset all ghosts to white when a new round starts
        for _, ghostName in ipairs(demonologyGhosts) do
            getgenv().SetGhostGreyedOut(ghostName, false)
        end
        
        -- Search the workspace for the ghost model
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj:GetAttribute("FavoriteRoom") ~= nil or obj:GetAttribute("Gender") ~= nil) then
                hookedGhost = obj
                getgenv().UpdateGhostStatus(hookedGhost)
                
                obj:GetAttributeChangedSignal("Gender"):Connect(function()
                    getgenv().UpdateGhostStatus(hookedGhost)
                end)
                
                obj:GetAttributeChangedSignal("FavoriteRoom"):Connect(function()
                    getgenv().UpdateGhostStatus(hookedGhost)
                end)
                break
            end
        end
    end
end)
