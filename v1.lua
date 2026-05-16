--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Local player
local player = Players.LocalPlayer

--// GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryHelper"
screenGui.Parent = player.PlayerGui

--// Drop Button (Only shows when holding tool)
local dropButton = Instance.new("TextButton")
dropButton.Name = "Drop"
dropButton.Size = UDim2.new(0, 100, 0, 40)
dropButton.Position = UDim2.new(0, 10, 1, -50)
dropButton.AnchorPoint = Vector2.new(0, 1)
dropButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
dropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropButton.Text = "DROP"
dropButton.Visible = false
dropButton.BackgroundTransparency = 0.3
local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0.5, 0)
dropCorner.Parent = dropButton
dropButton.Parent = screenGui

--// Grab Button
local grabButton = Instance.new("TextButton")
grabButton.Name = "Grab"
grabButton.Size = UDim2.new(0, 100, 0, 40)
grabButton.Position = UDim2.new(1, -110, 1, -50)
grabButton.AnchorPoint = Vector2.new(1, 1)
grabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
grabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
grabButton.Text = "GRAB"
grabButton.Visible = true
grabButton.BackgroundTransparency = 0.3
local grabCorner = Instance.new("UICorner")
grabCorner.CornerRadius = UDim.new(0.5, 0)
grabCorner.Parent = grabButton
grabButton.Parent = screenGui

--// State variables
local currentTool = nil
local isGrabbing = false
local grabConnection = nil
local lastGrabTime = 0
local GRAB_COOLDOWN = 0.5 -- Reduced frequency to prevent lag

--// Function to drop only the equipped tool
local function dropTool()
    if currentTool then
        currentTool.Parent = workspace
        
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                currentTool.Handle.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 5
            end
        end
        
        currentTool = nil
        dropButton.Visible = false
    end
end

--// Optimized tool collection with cooldown
local function collectTools()
    if not isGrabbing or not player.Character then return end
    
    local currentTime = tick()
    if currentTime - lastGrabTime < GRAB_COOLDOWN then return end
    lastGrabTime = currentTime
    
    -- Only collect tools that are in workspace, not from other players
    for _, tool in ipairs(workspace:GetChildren()) do
        if tool:IsA("Tool") and tool.Parent == workspace then
            tool.Parent = player.Backpack
        end
    end
end

--// Check equipped tool from character
local function updateEquippedTool()
    local character = player.Character
    if not character then
        currentTool = nil
        dropButton.Visible = false
        return
    end
    
    -- Find currently equipped tool
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") then
            currentTool = item
            dropButton.Visible = true
            return
        end
    end
    
    -- No tool equipped
    currentTool = nil
    dropButton.Visible = false
end

--// Character setup
local function setupCharacter(character)
    currentTool = nil
    dropButton.Visible = false
    grabButton.Visible = true
    
    -- Monitor tool equip/unequip
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            currentTool = child
            dropButton.Visible = true
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            updateEquippedTool()
        end
    end)
    
    -- Handle player death
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        dropButton.Visible = false
        grabButton.Visible = false
        isGrabbing = false
        grabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
        grabButton.Text = "GRAB"
        
        if grabConnection then
            grabConnection:Disconnect()
            grabConnection = nil
        end
    end)
end

--// Initial setup
if player.Character then
    setupCharacter(player.Character)
    updateEquippedTool()
end

player.CharacterAdded:Connect(setupCharacter)
player.CharacterRemoving:Connect(function()
    dropButton.Visible = false
    grabButton.Visible = false
    currentTool = nil
end)

--// Periodic equipped tool check (optimized)
RunService.Heartbeat:Connect(function()
    if player.Character then
        updateEquippedTool()
    else
        dropButton.Visible = false
        grabButton.Visible = false
    end
end)

--// Button events
dropButton.MouseButton1Click:Connect(dropTool)

grabButton.MouseButton1Click:Connect(function()
    if not player.Character then return end
    
    isGrabbing = not isGrabbing
    
    if isGrabbing then
        grabButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        grabButton.Text = "GRABBING"
        
        -- Use slower update to prevent lag
        grabConnection = RunService.Heartbeat:Connect(collectTools)
    else
        grabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
        grabButton.Text = "GRAB"
        
        if grabConnection then
            grabConnection:Disconnect()
            grabConnection = nil
        end
    end
end)
