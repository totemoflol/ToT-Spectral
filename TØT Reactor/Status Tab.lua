local Window = getgenv().Window

-- Create the Status Page
local StatusTab = Window:Page({ Icon = "rbxassetid://129245697782918" })

-- Left Side: Ghost Info
local StatusSection = StatusTab:Section({ Name = "Ghost Info", Side = 1 })

local RoomLabel = StatusSection:Label({ Name = "Favorite Room: Unknown" })
local GenderLabel = StatusSection:Label({ Name = "Gender: Unknown" })

local hasRoomBeenSet = false
local hookedGhost = nil

-- Function to update Ghost Info (Made Global so other files can call it)
getgenv().UpdateGhostStatus = function(ghostModel)
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

-- Auto-search loop to find the ghost and hook its attributes
task.spawn(function()
    while task.wait(1) do
        if hookedGhost and hookedGhost.Parent then 
            continue 
        end
        
        hookedGhost = nil
        hasRoomBeenSet = false
        RoomLabel:SetText("Favorite Room: Unknown")
        GenderLabel:SetText("Gender: Unknown")
        
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
