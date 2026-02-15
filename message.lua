-- [[ KEYAUTH CONFIGURATION ]] --
local KeyAuthSettings = {
    ApplicationName = "Roblox",
    OwnerID = "4MjNP5BKjW",
    Secret = "448af7695a7e466ba8dffdbe4a98f4e9d67a83daf0d5020d9c216ac98930a813",
    Version = "1.0"
}

-- [[ SERVICES ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SessionId = nil
local Verified = false

-- [[ KEYAUTH CORE LOGIC ]] --
local function KeyAuthRequest(data)
    local api_url = "https://keyauth.win/api/1.2/"
    local success, response = pcall(function()
        return HttpService:PostAsync(api_url, HttpService:JSONEncode(data))
    end)
    if success then
        return HttpService:JSONDecode(response)
    end
    return { success = false, message = "Connection Error" }
end

-- 1. Initialize Session
local init_res = KeyAuthRequest({
    type = "init",
    name = KeyAuthSettings.ApplicationName,
    ownerid = KeyAuthSettings.OwnerID,
    ver = KeyAuthSettings.Version
})

if init_res.success then
    SessionId = init_res.sessionid
else
    warn("KeyAuth Init Failed: " .. (init_res.message or "Unknown"))
end

-- [[ STATE & GUI ]] --
local State = {
    AimEnabled = false, SilentEnabled = false, HitboxEnabled = false, EspEnabled = false,
    HSize = 5, AimPower = 0.1, TargetPart = "Head", Fov = 150,
    Binds = { AimLock = Enum.KeyCode.Q, Silent = Enum.KeyCode.T, Menu = Enum.KeyCode.RightControl },
    ListeningForBind = nil
}

local Gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
Gui.Name = "Excuteros_KeyAuth_V8"
Gui.ResetOnSpawn = false

-- [[ KEY SYSTEM UI ]] --
local KeyFrame = Instance.new("Frame", Gui)
KeyFrame.Size = UDim2.new(0, 300, 0, 180)
KeyFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", KeyFrame)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.Text = "EXCUTEROS AUTH"
KeyTitle.TextColor3 = Color3.new(1, 1, 1)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Font = Enum.Font.GothamBold

local KeyInput = Instance.new("TextBox", KeyFrame)
KeyInput.Size = UDim2.new(0, 240, 0, 35)
KeyInput.Position = UDim2.new(0, 30, 0, 60)
KeyInput.PlaceholderText = "Enter License Key"
KeyInput.Text = ""
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
KeyInput.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KeyInput)

local SubmitBtn = Instance.new("TextButton", KeyFrame)
SubmitBtn.Size = UDim2.new(0, 240, 0, 35)
SubmitBtn.Position = UDim2.new(0, 30, 0, 110)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
SubmitBtn.Text = "LOGIN"
SubmitBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SubmitBtn)

-- [[ MAIN MENU FRAME (Hidden) ]] --
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 360, 0, 520)
Main.Position = UDim2.new(0.1, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Visible = false
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

-- [[ VERIFICATION LOGIC ]] --
SubmitBtn.MouseButton1Click:Connect(function()
    if not SessionId then return end
    SubmitBtn.Text = "Verifying..."
    
    local auth_res = KeyAuthRequest({
        type = "license",
        key = KeyInput.Text,
        hwid = game:GetService("RbxAnalyticsService"):GetClientId(),
        sessionid = SessionId,
        name = KeyAuthSettings.ApplicationName,
        ownerid = KeyAuthSettings.OwnerID
    })

    if auth_res.success then
        Verified = true
        KeyFrame:Destroy()
        Main.Visible = true
    else
        KeyInput.Text = ""
        KeyInput.PlaceholderText = auth_res.message or "Invalid Key"
        SubmitBtn.Text = "LOGIN"
    end
end)

-- [[ FROM HERE ON: YOUR ORIGINAL FEATURES ]] --
-- Wrap existing functions in 'if Verified then' checks

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "EXCUTEROS MASTER V8"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Title.Font = Enum.Font.GothamBold
Instance.new("UICorner", Title)

-- (Insert the rest of your addMenuRow, slider, getTarget, and Loop logic here)
-- (Just ensure all loops and input connections check 'if Verified then')

local function getTarget()
    if not Verified then return nil end
    local target = nil
    local dist = State.Fov
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(State.TargetPart) then
            local part = p.Character[State.TargetPart]
            local pos, vis = Camera:WorldToViewportPoint(part.Position)
            if vis then
                local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mDist < dist then target = part dist = mDist end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if not Verified then return end
    local target = getTarget()
    
    if State.AimEnabled and target then
        local cf = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(cf, State.AimPower)
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if State.HitboxEnabled then
                    hrp.Size = Vector3.new(State.HSize, State.HSize, State.HSize)
                    hrp.Transparency = 0.8
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end
end)

print("Excuteros V8: Awaiting KeyAuth verification.")