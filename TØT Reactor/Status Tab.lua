local Window = getgenv().Window

-- Create the Status Page
local StatusTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Ghost Info
local StatusSection = StatusTab:Section({ Name = "Ghost Info", Side = 1 })

local RoomLabel = StatusSection:Label({ Name = "Favorite Room: Unknown" })
local GenderLabel = StatusSection:Label({ Name = "Gender: Unknown" })

local hasRoomBeenSet = false
local hookedGhost = nil

-- Function to update Ghost Info
local function UpdateGhostStatus(ghostModel)
    if not ghostModel then return end
    
    -- Update Favorite Room (only if it hasn't been set yet)
    if not hasRoomBeenSet then
        local favRoom = tostring(ghostModel:GetAttribute("FavoriteRoom") or "Unknown")
        if favRoom ~= "Unknown" then
            RoomLabel:SetText("Favorite Room: " .. favRoom)
            hasRoomBeenSet = true -- Locks it so it can't be changed later
        end
    end
    
    -- Update Gender
    local gender = tostring(ghostModel:GetAttribute("Gender") or "Unknown")
    GenderLabel:SetText("Gender: " .. gender)
end

-- Auto-search loop to find the ghost and hook its attributes
task.spawn(function()
    while task.wait(1) do
        -- If we already found the ghost and it's still in the game, do nothing
        if hookedGhost and hookedGhost.Parent then 
            continue 
        end
        
        -- Reset for a new round
        hookedGhost = nil
        hasRoomBeenSet = false
        RoomLabel:SetText("Favorite Room: Unknown")
        GenderLabel:SetText("Gender: Unknown")
        
        -- Search the workspace for a model that has the "FavoriteRoom" or "Gender" attribute
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj:GetAttribute("FavoriteRoom") ~= nil or obj:GetAttribute("Gender") ~= nil) then
                hookedGhost = obj
                
                -- Update UI immediately
                UpdateGhostStatus(hookedGhost)
                
                -- Listen for live changes (e.g., if gender reveals later)
                obj:GetAttributeChangedSignal("Gender"):Connect(function()
                    UpdateGhostStatus(hookedGhost)
                end)
                
                obj:GetAttributeChangedSignal("FavoriteRoom"):Connect(function()
                    UpdateGhostStatus(hookedGhost)
                end)
                break
            end
        end
    end
end)


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

function SetGhostGreyedOut(ghostName, isGreyed)
    local labelObj = GhostLabels[ghostName]
    if labelObj and labelObj.Items["Text"] then
        if isGreyed then
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(80, 80, 80)
        else
            labelObj.Items["Text"].Instance.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end
