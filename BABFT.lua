local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")
local TPService = game:GetService("TeleportService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

getgenv().FarmHubStats = getgenv().FarmHubStats or {
    StartTime = "April 05, 2025 - 11:47 AM",
    GoldEarned = 0,
    RunCount = 0,
    Executor = identifyexecutor and identifyexecutor() or "Unknown"
}
getgenv().AutoFarm = getgenv().AutoFarm or {
    Enabled = true,
    TeleportDelay = 1.30,
    HopDelay = 10
}

local folder = "FarmHub"
local sessionsFile = folder .. "/Sessions.json"
if not isfolder(folder) then makefolder(folder) end

local function saveFarmHubStats()
    local stats = getgenv().FarmHubStats
    local user = Players.LocalPlayer
    local data = {}

    if isfile(sessionsFile) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(sessionsFile))
        end)
        if success and type(result) == "table" then
            data = result
        end
    end

    local session = {
        UserId = user.UserId,
        Username = user.DisplayName or user.Name,
        Executor = stats.Executor,
        GameId = game.PlaceId,
        StartTime = stats.StartTime,
        EndTime = os.date("%B %d, %Y - %I:%M %p"),
        GoldEarned = stats.GoldEarned,
        RunsCompleted = stats.RunCount
    }

    table.insert(data, session)
    local encoded = HttpService:JSONEncode(data):gsub("},{", "},\n    {")
    writefile(sessionsFile, "[\n    " .. encoded:sub(2, -2) .. "\n]")
end

local function dropPlatform(pos)
    local part = Instance.new("Part")
    part.Size = Vector3.new(10,1,10)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.3
    part.Position = pos - Vector3.new(0,3.5,0)
    part.BrickColor = BrickColor.new("New Yeller")
    part.Parent = workspace
    Debris:AddItem(part, 10)
end

local function teleportAndTouch(part)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and part then
        root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        dropPlatform(part.Position + Vector3.new(0, 3, 0))
        firetouchinterest(root, part, 0)
        firetouchinterest(root, part, 1)
    end
end

local function serverHop()
    local servers = {}
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result and result.data then
        for _, v in ipairs(result.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
    end
    if #servers > 0 then
        TPService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    end
end

local function autoFarm()
    repeat task.wait() until workspace:FindFirstChild("BoatStages")
    local stages = workspace.BoatStages.NormalStages

    for i = 1, 10 do
        if not getgenv().AutoFarm.Enabled then return end
        local stage = stages:FindFirstChild("CaveStage"..i)
        if stage and stage:FindFirstChild("DarknessPart") then
            teleportAndTouch(stage.DarknessPart)
            task.wait(getgenv().AutoFarm.TeleportDelay)
        end
    end

    if not getgenv().AutoFarm.Enabled then return end

    local chest = stages:FindFirstChild("TheEnd") and stages.TheEnd:FindFirstChild("GoldenChest") and stages.TheEnd.GoldenChest:FindFirstChild("Trigger")
    if chest then
        teleportAndTouch(chest)
        getgenv().FarmHubStats.RunCount += 1
        saveFarmHubStats()

        for i = 1, getgenv().AutoFarm.HopDelay do
            if not getgenv().AutoFarm.Enabled then return end
            task.wait(1)
        end

        serverHop()
    end
end

task.spawn(function()
    local gold = LocalPlayer:WaitForChild("Data"):WaitForChild("Gold")
    local last = gold.Value
    gold:GetPropertyChangedSignal("Value"):Connect(function()
        local gain = gold.Value - last
        if gain > 0 then
            getgenv().FarmHubStats.GoldEarned += gain
            saveFarmHubStats()
        end
        last = gold.Value
    end)
end)

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "FarmHub"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 160)
frame.Position = UDim2.new(0, 25, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(255, 255, 0)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 0, 30)
label.Text = "🌾 FarmHub - BABFT"
label.TextColor3 = Color3.fromRGB(255, 255, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.BackgroundTransparency = 1

local toggleFrame = Instance.new("Frame", frame)
toggleFrame.Position = UDim2.new(0, 10, 0, 40)
toggleFrame.Size = UDim2.new(0, 60, 0, 30)
toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", toggleFrame).Color = Color3.fromRGB(255, 255, 0)

local knob = Instance.new("Frame", toggleFrame)
knob.Size = UDim2.new(0, 26, 0, 26)
knob.Position = UDim2.new(1, -28, 0, 2)
knob.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local toggleLabel = Instance.new("TextLabel", toggleFrame)
toggleLabel.Size = UDim2.new(1, 80, 1, 0)
toggleLabel.Position = UDim2.new(1, 10, 0, 0)
toggleLabel.Text = "AutoFarm: ON"
toggleLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
toggleLabel.Font = Enum.Font.Gotham
toggleLabel.TextSize = 14
toggleLabel.BackgroundTransparency = 1
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left

local function toggleAutoFarm(state)
    getgenv().AutoFarm.Enabled = state
    toggleLabel.Text = state and "AutoFarm: ON" or "AutoFarm: OFF"
    toggleLabel.TextColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    TweenService:Create(knob, TweenInfo.new(0.25), {
        Position = state and UDim2.new(1, -28, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    }):Play()
end

toggleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleAutoFarm(not getgenv().AutoFarm.Enabled)
    end
end)
toggleAutoFarm(true)

local msg = Instance.new("TextLabel", frame)
msg.Position = UDim2.new(0, 10, 0, 80)
msg.Size = UDim2.new(1, -20, 0, 30)
msg.Text = "📁 Logging to: FarmHub/Sessions.json"
msg.TextColor3 = Color3.fromRGB(255, 255, 255)
msg.TextSize = 13
msg.Font = Enum.Font.Gotham
msg.BackgroundTransparency = 1
msg.TextWrapped = true

local tip = Instance.new("TextLabel", frame)
tip.Position = UDim2.new(0, 10, 0, 110)
tip.Size = UDim2.new(1, -20, 0, 30)
tip.Text = "💡 Tip: Add this to autoexecute to AFK forever!"
tip.TextColor3 = Color3.fromRGB(255, 255, 100)
tip.TextSize = 12
tip.Font = Enum.Font.Gotham
tip.BackgroundTransparency = 1
tip.TextWrapped = true

task.spawn(function()
    while true do
        if getgenv().AutoFarm.Enabled then
            autoFarm()
        end
        task.wait(1)
    end
end)
