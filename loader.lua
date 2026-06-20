 -- loader.lua
local Library = (loadstring(game:HttpGet("https://raw.githubusercontent.com/jodta/my-scripts/refs/heads/main/Other/Library2"))()) or getgenv().Library

-- 2) Set the Window Name and Logo
getgenv().Window = Library:Window({
    Name = "TØT Spectrum", -- If the library supports a text title
    Logo = "rbxassetid://77749228793011" -- Custom logo image ID
})

loadstring(game:HttpGet("https://raw.githubusercontent.com/totemoflol/ToT-Spectral/refs/heads/main/TØT%20Reactor/Status%20Tab.lua"))()

https://raw.githubusercontent.com/totemoflol/ToT-Spectral/refs/heads/main/TØT%20Reactor/Log%20Tab.lua
