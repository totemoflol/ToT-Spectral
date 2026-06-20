local Window = getgenv().Window

-- Create the Status Page
local StatusTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Ghost Info
local StatusSection = StatusTab:Section({ Name = "Ghost Info", Side = 1 })

local RoomLabel = StatusSection:Label({ Name = "Favorite Room: Unknown" })
local GenderLabel = StatusSection:Label({ Name = "Gender: Unknown" })

local hasRoomBeenSet = false

-- Function to update Ghost Info
local function UpdateGhostStatus(ghostModel)
    if not ghostModel then return end
    
    if not hasRoomBeenSet then
        local favRoom = tostring(ghostModel:GetAttribute("FavoriteRoom") or "Unknown")
        if favRoom ~= "Unknown" then
            RoomLabel:SetText("Favorite Room: " .. favRoom)
            hasRoomBeenSet = true
        end
    end
    
    local gender = tostring(ghostModel:GetAttribute("Gender") or "Unknown")
    GenderLabel:SetText("Gender: " .. gender)
end


-- Right Side: Ghost List
local GhostsSection = StatusTab:Section({ Name = "Demonology Ghosts", Side = 2 })

-- The true working list of Roblox Demonologist ghosts
local demonologyGhosts = {
    "Aswang", "Banshee", "Demon", "Dullahan", "Dybbuk", "Entity", "Ghoul", 
    "Keres", "Leviathan", "Nightmare", "Oni", "Phantom", "Revenant", 
    "Shadow", "Siren", "Skinwalker", "Specter", "Spirit", "The Wisp", 
    "Umbra", "Vex", "Wendigo", "Wraith", "Ravager", "Vesper"
}

-- Store the labels so we can change their colors later
local GhostLabels = {}

-- Create a label for each ghost
for _, ghostName in ipairs(demonologyGhosts) do
    GhostLabels[ghostName] = GhostsSection:Label({ Name = ghostName })
end

-- Function to grey out or restore a ghost's name
function SetGhostGreyedOut(ghostName, isGreyed)
    local labelObj = GhostLabels[ghostName]
    if labelObj and labelObj.Items["Text"] then
        if isGreyed then
            -- Greyed out (Dark Text)
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(80, 80, 80)
        else
            -- Restored to normal (White Text)
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- Example usage for later in your script:
-- SetGhostGreyedOut("Banshee", true) -- This will grey out Banshee
-- SetGhostGreyedOut("Banshee", false) -- This will restore Banshee to white
