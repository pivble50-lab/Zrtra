--[[
    Zyrta MM2
    Author: pivble_5
    All English | ESP auto-refresh | Fixed Auto Farm
]]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

WindUI:AddTheme({
    Name = "Dark",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"),
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#a1a1aa"),
})

local Window = WindUI:CreateWindow({
    Title   = "Zyrta MM2",
    Author  = "pivble_5",
    Folder  = "zyrtamm2",
    Icon    = "skull",
    Theme   = "Dark",
    Acrylic = true,
    Transparent = true,
    Background = "rbxassetid://17582945577",
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    BackgroundImageTransparency = 0.65,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton = {
        Title = "Zyrta MM2", Icon = "skull",
        CornerRadius = UDim.new(1, 0), StrokeThickness = 3,
        Enabled = true, Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#000000"), Color3.fromHex("#000000")),
    },
    User = { Enabled = true, Anonymous = false, Callback = function() end },
})

-- ==========================================
-- STATE
-- ==========================================
local espEnabled = false
local espHighlights = {}
local roleFilter = { Murderer = true, Sheriff = true, Innocent = true }
local autoGunEnabled = false
local autoCoinEnabled = false
local infJumpEnabled = false
local noclipEnabled = false
local fullbrightEnabled = false
local flyEnabled = false
local flyBV = nil
local flyBG = nil
local killAllEnabled = false
local autoShootEnabled = false
local gunESPEnabled = false
local gunESPObjects = {}
local coinESPEnabled = false
local coinESPObjects = {}

-- ==========================================
-- ROLE DETECTION
-- ==========================================
local function getRole(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    if char then
        if char:FindFirstChild("Knife") then return "Murderer" end
        if char:FindFirstChild("Gun") then return "Sheriff" end
    end
    if bp then
        if bp:FindFirstChild("Knife") then return "Murderer" end
        if bp:FindFirstChild("Gun") then return "Sheriff" end
    end
    return "Innocent"
end

local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 40, 40)
    elseif role == "Sheriff" then return Color3.fromRGB(40, 120, 255)
    else return Color3.fromRGB(40, 255, 80)
    end
end

-- ==========================================
-- ESP (AUTO REFRESH)
-- ==========================================
local function clearESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    espHighlights = {}
end

local function applyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local role = getRole(player)
    if not roleFilter[role] then
        local ex = espHighlights[player]
        if ex and ex.Parent then ex:Destroy() end
        espHighlights[player] = nil
        return
    end
    local hl = espHighlights[player]
    if hl and hl.Parent then
        hl.Adornee = char
        hl.FillColor = roleColor(role)
    else
        hl = Instance.new("Highlight")
        hl.Name = "Zyrta_ESP"
        hl.Adornee = char
        hl.FillColor = roleColor(role)
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.65
        hl.OutlineTransparency = 0
        hl.Parent = char
        espHighlights[player] = hl
    end
end

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = espHighlights[p]
            if not hl or not hl.Parent or hl.Adornee ~= p.Character then
                applyHighlight(p)
            else
                hl.FillColor = roleColor(getRole(p))
            end
        end
    end
    for p, hl in pairs(espHighlights) do
        if not p.Parent or not p.Character then
            if hl and hl.Parent then hl:Destroy() end
            espHighlights[p] = nil
        end
    end
end)

-- ==========================================
-- HELPERS
-- ==========================================
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function teleportTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos)
    elseif LocalPlayer.Character then
        LocalPlayer.Character:PivotTo(CFrame.new(pos))
    end
end

local function findDroppedGun()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Gun" then
            local parent = obj.Parent
            if not parent or not parent:FindFirstChild("Humanoid") then return obj end
        end
    end
    return nil
end

local function getAllCoins()
    local coins = {}
    for _, name in ipairs({"CoinContainer", "Coins", "CoinFolder"}) do
        local container = workspace:FindFirstChild(name)
        if container then
            for _, c in ipairs(container:GetChildren()) do
                if c:IsA("BasePart") then table.insert(coins, c) end
            end
        end
    end
    if #coins == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name:find("Coin")) then
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

-- ==========================================
-- AUTO FARM
-- ==========================================
local function startAutoCoins()
    autoCoinEnabled = true
    task.spawn(function()
        while autoCoinEnabled do
            task.wait(0.3)
            local root = getRoot()
            if root then
                local coins = getAllCoins()
                for _, coin in ipairs(coins) do
                    if not autoCoinEnabled then break end
                    if coin and coin.Parent then
                        teleportTo(coin.Position)
                        task.wait(0.15)
                    end
                end
            end
        end
    end)
end

local function startAutoGun()
    autoGunEnabled = true
    task.spawn(function()
        while autoGunEnabled do
            task.wait(0.4)
            local root = getRoot()
            if root then
                local gun = findDroppedGun()
                if gun and gun.Parent then
                    teleportTo(gun.Position)
                    task.wait(0.2)
                end
            end
        end
    end)
end

-- ==========================================
-- TAB 1: MAIN
-- ==========================================
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
MainTab:Paragraph({ Title = "Welcome", Desc = "Hi, thank you for using my script!" })
MainTab:Paragraph({ Title = "About", Desc = "Zyrta MM2 | by pivble_5" })
MainTab:Paragraph({ Title = "Toggle UI", Desc = "RightShift" })
MainTab:Button({ Title = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })
MainTab:Button({ Title = "Reset Character", Callback = function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.Health = 0 end end })

-- ==========================================
-- TAB 2: ESP
-- ==========================================
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
ESPTab:Toggle({
    Title = "Player ESP (Outline)",
    Desc = "Red = Murderer | Blue = Sheriff | Green = Innocent",
    Value = false,
    Callback = function(state)
        espEnabled = state
        if not state then clearESP() end
    end,
})
ESPTab:Toggle({ Title = "Show Murderer", Value = true, Callback = function(s) roleFilter.Murderer = s end })
ESPTab:Toggle({ Title = "Show Sheriff", Value = true, Callback = function(s) roleFilter.Sheriff = s end })
ESPTab:Toggle({ Title = "Show Innocent", Value = true, Callback = function(s) roleFilter.Innocent = s end })

-- ==========================================
-- TAB 3: COMBAT
-- ==========================================
local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords" })
CombatTab:Toggle({
    Title = "Kill All (as Murderer)",
    Value = false,
    Callback = function(s)
        killAllEnabled = s
        if s then
            task.spawn(function()
                while killAllEnabled do
                    task.wait(0.5)
                    if getRole(LocalPlayer) == "Murderer" then
                        local root = getRoot()
                        if root then
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                    root.CFrame = p.Character.HumanoidRootPart.CFrame
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})
CombatTab:Toggle({
    Title = "Auto Shoot Murderer (as Sheriff)",
    Value = false,
    Callback = function(s)
        autoShootEnabled = s
        if s then
            task.spawn(function()
                while autoShootEnabled do
                    task.wait(0.3)
                    if getRole(LocalPlayer) == "Sheriff" then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and getRole(p) == "Murderer" then
                                local head = p.Character:FindFirstChild("Head")
                                if head then
                                    local mouse = LocalPlayer:GetMouse()
                                    if mouse then mouse.Target = head end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})
CombatTab:Button({
    Title = "Teleport to Murderer",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and getRole(p) == "Murderer" then
                teleportTo(p.Character.HumanoidRootPart.Position + Vector3.new(0,0,2))
                break
            end
        end
    end,
})
CombatTab:Button({
    Title = "Teleport to Sheriff",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and getRole(p) == "Sheriff" then
                teleportTo(p.Character.HumanoidRootPart.Position + Vector3.new(0,0,2))
                break
            end
        end
    end,
})

-- ==========================================
-- TAB 4: FARM
-- ==========================================
local FarmTab = Window:Tab({ Title = "Farm", Icon = "coins" })
FarmTab:Toggle({
    Title = "Auto Pickup Gun",
    Value = false,
    Callback = function(s)
        autoGunEnabled = s
        if s then startAutoGun() end
    end,
})
FarmTab:Toggle({
    Title = "Auto Collect Coins",
    Value = false,
    Callback = function(s)
        autoCoinEnabled = s
        if s then startAutoCoins() end
    end,
})
FarmTab:Button({
    Title = "Teleport to Gun",
    Callback = function()
        local gun = findDroppedGun()
        if gun then teleportTo(gun.Position) end
    end,
})
FarmTab:Button({
    Title = "Teleport to Nearest Coin",
    Callback = function()
        local coins = getAllCoins()
        if #coins > 0 then teleportTo(coins[1].Position) end
    end,
})

-- ==========================================
-- TAB 5: PLAYER
-- ==========================================
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
PlayerTab:Slider({
    Title = "WalkSpeed", Step = 1,
    Value = { Min = 16, Max = 250, Default = 16 },
    Callback = function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end,
})
PlayerTab:Slider({
    Title = "JumpPower", Step = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
            LocalPlayer.Character.Humanoid.UseJumpPower = true
        end
    end,
})
PlayerTab:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(s) infJumpEnabled = s end })
PlayerTab:Toggle({ Title = "Noclip", Value = false, Callback = function(s) noclipEnabled = s end })

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
end)

-- ==========================================
-- TAB 6: MOVEMENT
-- ==========================================
local MoveTab = Window:Tab({ Title = "Movement", Icon = "move" })
MoveTab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(s)
        flyEnabled = s
        local char = LocalPlayer.Character
        if s and char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
                flyBV.Velocity = Vector3.new(0,0,0)
                flyBV.Parent = hrp
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
                flyBG.Parent = hrp
                task.spawn(function()
                    while flyEnabled and hrp.Parent do
                        local move = Vector3.new()
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                        flyBV.Velocity = move * 50
                        flyBG.CFrame = Camera.CFrame
                        task.wait()
                    end
                end)
            end
        else
            if flyBV then flyBV:Destroy(); flyBV = nil end
            if flyBG then flyBG:Destroy(); flyBG = nil end
        end
    end,
})
MoveTab:Button({ Title = "Teleport Up (+50)", Callback = function()
    local root = getRoot()
    if root then root.CFrame = root.CFrame + Vector3.new(0,50,0) end
end })
MoveTab:Button({ Title = "Teleport to Spawn", Callback = function() teleportTo(Vector3.new(0,10,0)) end })

-- ==========================================
-- TAB 7: GUN ESP
-- ==========================================
local GunESPTab = Window:Tab({ Title = "Gun ESP", Icon = "crosshair" })
GunESPTab:Toggle({
    Title = "Gun ESP",
    Value = false,
    Callback = function(s)
        gunESPEnabled = s
        if not s then
            for _, obj in pairs(gunESPObjects) do
                if obj and obj.Parent then obj:Destroy() end
            end
            gunESPObjects = {}
        end
    end,
})
GunESPTab:Button({
    Title = "Refresh Gun ESP",
    Callback = function()
        for _, obj in pairs(gunESPObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        gunESPObjects = {}
    end,
})
task.spawn(function()
    while true do
        task.wait(1)
        if gunESPEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "Gun" and not gunESPObjects[obj] then
                    local hl = Instance.new("Highlight")
                    hl.Adornee = obj
                    hl.FillColor = Color3.fromRGB(255, 255, 0)
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.FillTransparency = 0.5
                    hl.Parent = obj
                    gunESPObjects[obj] = hl
                end
            end
        end
    end
end)

-- ==========================================
-- TAB 8: COIN ESP
-- ==========================================
local CoinESPTab = Window:Tab({ Title = "Coin ESP", Icon = "circle-dollar-sign" })
CoinESPTab:Toggle({
    Title = "Coin ESP",
    Value = false,
    Callback = function(s)
        coinESPEnabled = s
        if not s then
            for _, obj in pairs(coinESPObjects) do
                if obj and obj.Parent then obj:Destroy() end
            end
            coinESPObjects = {}
        end
    end,
})
CoinESPTab:Button({
    Title = "Refresh Coin ESP",
    Callback = function()
        for _, obj in pairs(coinESPObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        coinESPObjects = {}
    end,
})
task.spawn(function()
    while true do
        task.wait(1)
        if coinESPEnabled then
            for _, coin in ipairs(getAllCoins()) do
                if not coinESPObjects[coin] then
                    local hl = Instance.new("Highlight")
                    hl.Adornee = coin
                    hl.FillColor = Color3.fromRGB(255, 215, 0)
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.FillTransparency = 0.4
                    hl.Parent = coin
                    coinESPObjects[coin] = hl
                end
            end
        end
    end
end)

-- ==========================================
-- TAB 9: TELEPORT
-- ==========================================
local TPTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end
TPTab:Dropdown({
    Title = "Teleport to Player",
    Values = playerNames,
    Value = nil,
    Callback = function(name)
        local t = Players:FindFirstChild(name)
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            teleportTo(t.Character.HumanoidRootPart.Position + Vector3.new(0,0,2))
        end
    end,
})
TPTab:Button({
    Title = "Teleport to Lobby",
    Callback = function() teleportTo(Vector3.new(0,10,0)) end,
})
TPTab:Button({
    Title = "Teleport to Random Player",
