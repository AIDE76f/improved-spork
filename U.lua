-- سكربت خادم واحد متكامل: جمع الأموال وإنشاء GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- إنشاء حدث لإرسال المبالغ المجموعة إلى اللاعبين
local moneyCollectedEvent = Instance.new("RemoteEvent")
moneyCollectedEvent.Name = "MoneyCollectedEvent"
moneyCollectedEvent.Parent = ReplicatedStorage

-- التأكد من وجود مجلد السيارات
local carsFolder = Workspace:FindFirstChild("Cars")
if not carsFolder then
    carsFolder = Instance.new("Folder")
    carsFolder.Name = "Cars"
    carsFolder.Parent = Workspace
    warn("تم إنشاء مجلد 'Cars' في Workspace. يرجى وضع السيارات فيه.")
end

-- إعداد leaderstats للاعب الجديد وإنشاء واجهة GUI
local function setupPlayer(player)
    -- leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    
    local money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = 0
    money.Parent = leaderstats
    
    leaderstats.Parent = player
    
    -- إنشاء GUI (سيرسل إلى العميل مع LocalScript داخله)
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MoneyCollectorGUI"
    screenGui.ResetOnSpawn = false   -- تبقى الواجهة بعد الموت
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 80)
    frame.Position = UDim2.new(0, 15, 0, 15)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💰 جمع الأموال"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.ArialBold
    titleLabel.TextSize = 20
    titleLabel.Parent = frame
    
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "AmountLabel"
    amountLabel.Size = UDim2.new(1, 0, 0, 30)
    amountLabel.Position = UDim2.new(0, 0, 0, 30)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "آخر مبلغ: 0"
    amountLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    amountLabel.Font = Enum.Font.Arial
    amountLabel.TextSize = 18
    amountLabel.Parent = frame
    
    -- إنشاء LocalScript داخل GUI (سيتم تنفيذه على جهاز اللاعب)
    local localScript = Instance.new("LocalScript")
    localScript.Name = "GUIClientHandler"
    localScript.Source = [[
        -- هذا الكود يعمل على العميل
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local screenGui = playerGui:WaitForChild("MoneyCollectorGUI")
        local amountLabel = screenGui:WaitForChild("Frame"):WaitForChild("AmountLabel")
        
        local moneyEvent = ReplicatedStorage:WaitForChild("MoneyCollectedEvent")
        moneyEvent.OnClientEvent:Connect(function(amount)
            amountLabel.Text = "آخر مبلغ: " .. tostring(amount)
            amountLabel.TextColor3 = Color3.fromRGB(0, 255, 0)  -- أخضر
            task.wait(0.3)
            amountLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- أصفر
        end)
    ]]
    localScript.Parent = screenGui
end

-- ربط حدث انضمام اللاعبين
Players.PlayerAdded:Connect(setupPlayer)

-- حلقة جمع الأموال كل 5 ثوانٍ
local COLLECTION_INTERVAL = 5
while true do
    task.wait(COLLECTION_INTERVAL)
    
    local earnings = {}
    
    for _, car in ipairs(carsFolder:GetChildren()) do
        if car:IsA("Model") then
            local ownerUserId = car:GetAttribute("OwnerUserId")
            local income = car:GetAttribute("Income")
            
            if ownerUserId and income then
                local player = Players:GetPlayerByUserId(ownerUserId)
                if player then
                    earnings[player] = (earnings[player] or 0) + income
                end
            end
        end
    end
    
    for player, amount in pairs(earnings) do
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local moneyValue = leaderstats:FindFirstChild("Money")
            if moneyValue then
                moneyValue.Value += amount
            end
        end
        
        moneyCollectedEvent:FireClient(player, amount)
    end
end
