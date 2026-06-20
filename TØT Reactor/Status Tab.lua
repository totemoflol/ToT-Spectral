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
    ["laundry"] = { "Entity", "Nightmare", "Ghoul" },
    ["bathroom"] = { "Shadow", "Phantom", "Oni", "Skinwalker" },
    ["office"] = { "Spirit", "Specter", "Banshee" },
    ["bedroom"] = { "Wendigo", "Demon", "Wraith" }
}

-- Function to handle greying out ghosts based on room
local function FilterGhostsByRoom(roomName)
    local normalizedRoom = string.lower(tostring(roomName))
    local validGhosts = RoomGhostMap[normalizedRoom]
    
    if validGhosts then
        -- Create a quick lookup table
        local isValid = {}
        for _, ghost in ipairs(validGhosts) do
            isValid[ghost] = true
        end
        
        -- Highlight valid ghosts, grey out the rest
        for _, ghostName in ipairs(demonologyGhosts) do
            if isValid[ghostName] then
                getgenv().SetGhostGreyedOut(ghostName, false) -- White
            else
                getgenv().SetGhostGreyedOut(ghostName, true) -- Greyed out
            end
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
    
    if not hasRoomBeenSet then
        local favRoom = tostring(ghostModel:GetAttribute("FavoriteRoom") or "Unknown")
        if favRoom ~= "Unknown" then
            RoomLabel:SetText("Favorite Room: " .. favRoom)
            hasRoomBeenSet = true
            
            -- Run the filter as soon as we get the room!
            FilterGhostsByRoom(favRoom)
        end
    end
    
    local gender = tostring(ghostModel:GetAttribute("Gender") or "Unknown")
    GenderLabel:SetText("Gender: " .. gender)
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
        GenderLabel.SetText("Gender: Unknown")
        
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
