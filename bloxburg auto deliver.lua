local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UNDER_Y = -15
local FLY_TIME_XZ = 5
local FLY_TIME_Y = 1

local running = false
local loopThread = nil

-- 🖱️ GUI button
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "DeliveryToggleGui"
screenGui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0, 0) -- anchor from top-left corner
button.Size = UDim2.new(0, 150, 0, 40) -- fixed size
button.Position = UDim2.new(0, 20, 0, 20) -- 20px from left and top
button.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 20
button.Font = Enum.Font.SourceSansBold
button.Text = "Start Auto Delivery"
button.AutomaticSize = Enum.AutomaticSize.None
button.Parent = screenGui

local targets = {
    "Railing",
    "InnerWall",
    "Belt"
}

-- Recursive function to search through a folder and its children
local function applyPropertiesToTargets(parent)
    for _, descendant in ipairs(parent:GetDescendants()) do
        if descendant:IsA("BasePart") and table.find(targets, descendant.Name) then
            descendant.Transparency = 1
            descendant.CanCollide = true
        end
    end
end

-- Target the PizzaPlanet interior
local interior = workspace.Environment.Locations.City.PizzaPlanet:FindFirstChild("Interior")
if interior then
    applyPropertiesToTargets(interior)
end

local function restorePlayerToNormal()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    -- Restore physics
    if humanoid then
        humanoid.PlatformStand = false
    end

    if hrp then
        hrp.Anchored = false
    end

    -- Re-enable collisions
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end

    print("✅ Player restored to normal state.")
end


local function pressEUntilPizzaBoxGone()
	local player = game:GetService("Players").LocalPlayer
	local VirtualInputManager = game:GetService("VirtualInputManager")

	while true do
		-- Check if Pizza Box is gone from player's folder
		local playerFolder = workspace:FindFirstChild(player.Name)
		local hasPizzaBox = playerFolder and playerFolder:FindFirstChild("Pizza Box")
        local gui = player:FindFirstChild("PlayerGui", true)
        local indicator = gui and gui:FindFirstChild("InteractIndicator", true)

		if not hasPizzaBox then
			print("✅ Pizza Box gone, delivery confirmed!")
			break
		end

		-- Press E key
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		print("🔁 Pressed E, waiting for Pizza Box to disappear...")

		task.wait(0.5)
        if indicator and not indicator.Visible then
            break
        end
	end
end


local function pressEUntilPizzaBox()
	while true do
		-- Check if Pizza Box exists under the player's folder
		local playerFolder = workspace:FindFirstChild(player.Name)
		if playerFolder and playerFolder:FindFirstChild("Pizza Box") then
			print("🍕 Pizza Box found!")
			break
		end

		-- Press E key
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		print("🔁 Pressed E, waiting for Pizza Box...")

		task.wait(0.5) -- Small delay before trying again
	end
end

local function pressEUntilMoped()
	while true do
		-- Check if Pizza Box exists under the player's folder
		local playerFolder = workspace:FindFirstChild(player.Name)
		if playerFolder and playerFolder:FindFirstChild("Vehicle_Delivery Moped") then
			print("Moped found!")
			break
		end

		-- Press E key
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

		task.wait(0.5) -- Small delay before trying again
	end
end



-- 📦 Tween to position
local function tweenToPosition(targetPos, duration)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	hrp.Anchored = true

	local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos)
	})
	tween:Play()
	tween.Completed:Wait()
end

function checkMoped()
    local charFolder = workspace:FindFirstChild(player.Name)

    if charFolder and charFolder:FindFirstChild("Vehicle_Delivery Moped") then
        return true
    end
    return false
end

local function lookAtMoped()
    local camera = workspace.CurrentCamera

    camera.CFrame = CFrame.new(-64.805069, 13.5722952, -18.1985264, 0.715940595, 0.392118871, -0.577643394, 1.49011612e-08, 0.827378273, 0.56164515, 0.698161244, -0.402104557, 0.592353642)
end

function goToMoped()
    local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")


    if checkMoped() == false then
        local mopedPos = Vector3.new(-57.58452606201172, 4.571730613708496, -25.602947235107422)

		-- 2. Fly under to customer
		tweenToPosition(Vector3.new(mopedPos.X, UNDER_Y, mopedPos.Z), FLY_TIME_XZ)
		-- 3. Fly up to customer
		tweenToPosition(mopedPos, FLY_TIME_Y)
        task.wait(0.2)
        lookAtMoped()
        task.wait(0.2)
        pressEUntilMoped()
    end
end

local function getLatestCustomer()
	local customers = workspace._game.SpawnedCharacters:GetChildren()
	local latest = nil

	-- Loop through in order, pick the last customer with the correct name
	for _, c in ipairs(customers) do
		if c.Name == "PizzaPlanetDeliveryCustomer" and c:FindFirstChild("HumanoidRootPart") then
			latest = c
		end
	end

	return latest
end

local function lookAtPizzaBox()
    local camera = workspace.CurrentCamera

    camera.CFrame = CFrame.new(-59.3084412, 10.4807405, -38.2421989, 0.724805474, 0.336535662, -0.601166129, -1.4901163e-08, 0.872578621, 0.488473654, 0.688953578, -0.354048371, 0.632449746)
end

function tpToPizza()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- Set target position
    local targetPos = Vector3.new(-48.278194427490234, 5,-43.2014045715332)

    -- Teleport
    hrp.CFrame = CFrame.new(targetPos)
end


-- 🚚 Auto delivery loop
local function autoDeliveryLoop()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	-- Setup: flying mode
	humanoid.PlatformStand = true
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

    tpToPizza()
    lookAtPizzaBox()
    pressEUntilPizzaBox()

	while running do
		local customer = getLatestCustomer()

		if not (customer and customer:FindFirstChild("HumanoidRootPart")) then
			task.wait(1)
			return
		end

		local customerPos = customer.HumanoidRootPart.Position
		local doorPos = Vector3.new(-48.278194427490234, 5,-43.2014045715332)

		-- 1. Drop under map
		hrp.CFrame = CFrame.new(hrp.Position.X, UNDER_Y, hrp.Position.Z)

		-- 2. Fly under to customer
		tweenToPosition(Vector3.new(customerPos.X, UNDER_Y, customerPos.Z), FLY_TIME_XZ)

		-- 3. Fly up to customer
		tweenToPosition(customerPos, FLY_TIME_Y)
		task.wait(1)
		pressEUntilPizzaBoxGone()

        local playerFolder = workspace:FindFirstChild(player.Name)
		local hasPizzaBox = playerFolder and playerFolder:FindFirstChild("Pizza Box")

        if not hasPizzaBox then
            -- 4. Drop under map again
            hrp.CFrame = CFrame.new(hrp.Position.X, UNDER_Y, hrp.Position.Z)

            -- 5. Fly under to door
            tweenToPosition(Vector3.new(doorPos.X, UNDER_Y, doorPos.Z), FLY_TIME_XZ)

            -- 6. Fly up to door
            tweenToPosition(doorPos, FLY_TIME_Y)
            task.wait(10)

            local movingBoxes = workspace.Environment.Locations.City.PizzaPlanet.Interior.Conveyor:FindFirstChild("MovingBoxes")

            if movingBoxes then
                for _, child in ipairs(movingBoxes:GetChildren()) do
                    if child:IsA("BasePart") then
                        tweenToPosition(child.Position, 1)
                        break
                    end
                end
            else
                warn("❌ MovingBoxes not found")
            end

            lookAtPizzaBox()
            pressEUntilPizzaBox()
            task.wait(2)
        end
        
	end
    
    restorePlayerToNormal()
    tweenToPosition(Vector3.new(doorPos.X, 8, doorPos.Z), 1)
end

-- 🔘 Toggle button
button.MouseButton1Click:Connect(function()
	running = not running

	if running then
		button.Text = "Stop Auto Delivery"
		button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

		loopThread = coroutine.create(autoDeliveryLoop)
		coroutine.resume(loopThread)
	else
		button.Text = "Start Auto Delivery"
		button.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	end
end)
