local StatusTab = Window:CreateTab("Status", 4483362458)

StatusTab:CreateLabel("Favorite Room: " .. tostring(ghostModel:GetAttribute("FavoriteRoom") or "Unknown"))
StatusTab:CreateLabel("Gender: " .. tostring(ghostModel:GetAttribute("Gender") or "Unknown"))