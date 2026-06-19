local GhostRoom = "Not Set"

local PossibleGhosts = {
    "Aswang",
    "Banshee",
    "Demon",
    "Dullahan",
    "Dybbuk",
    "Entity",
    "Ghoul",
    "Leviathan",
    "Nightmare",
    "Oni",
    "Phantom",
    "Revenant",
    "Shadow",
    "Siren",
    "Skinwalker",
    "Specter",
    "Spirit",
    "Umbra",
    "Wendigo",
    "The Wisp",
    "Wraith"
}

local StatusTab = Window:CreateTab("Status", 4483362458)

local Status = StatusTab:CreateParagraph({
    Title = "Investigation Status",
    Content = ""
})

local function UpdateStatus()
    Status:Set({
        Title = "Investigation Status",
        Content =
            "Ghost Room: " .. GhostRoom ..
            "\n\nPossible Ghosts (" .. #PossibleGhosts .. "):\n" ..
            table.concat(PossibleGhosts, "\n")
    })
end

UpdateStatus()
