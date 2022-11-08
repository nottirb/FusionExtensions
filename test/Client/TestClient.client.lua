local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Fusion = require(Packages.Fusion)
local FusionExtensions = require(Packages.FusionExtensions)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Spring = FusionExtensions.Spring

local ONE_SEVENTH = 1/7
local ONE_FOURTEENTH = 1/14

local targetSize = Value(UDim2.fromScale(ONE_SEVENTH, 1))
local targetPosition = Value(UDim2.fromScale(0.5, 0.5))
local targetColor = Value(Color3.fromRGB(255, 0, 0))

local positionSpring = Spring(targetPosition, 30, 0.5)

local App = New "ScreenGui" {
	ResetOnSpawn = false,
	Parent = PlayerGui,

	[Children] = {
		New "Frame" {
			Size = UDim2.fromScale(0.9, 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.new(0, 0, 0),

			[Children] = {
				New "UIAspectRatioConstraint" {
					AspectRatio = 7,
				},

				New "Frame" {
					BackgroundTransparency = 0,
					BackgroundColor3 = Spring(targetColor, 30, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = positionSpring,
					Size = Spring(targetSize, 30, 0.5),
				}
			}
		},
	}
}

-- Test spring
for i = 1, 10 do
	task.wait(0.1)

	-- Set size
	local scale = math.random()
	local one_seventh_scale = ONE_SEVENTH * scale
	targetSize:set(UDim2.fromScale(one_seventh_scale, scale))

	-- Set color
	targetColor:set(Color3.fromHSV(math.random(), math.random(), math.random()))

	-- Set position
	targetPosition:set(UDim2.fromScale(math.random() * (1 - ONE_SEVENTH) + ONE_FOURTEENTH, 0.5))
end


-- Verify the spring gets cleaned up
local weakPositionSpring = setmetatable({[positionSpring] = true}, { __mode = "k" })
positionSpring = nil

App:Destroy()

local Connection Connection = RunService.RenderStepped:Connect(function()
	local tempPositionSpring = next(weakPositionSpring)

	if tempPositionSpring ~= nil then
		print("Still connected")
		local a = Instance.new("Part")
		a.Parent = workspace
		task.defer(function()
			a:Destroy()
		end)
	else
		print("Disconnected")
		Connection:Disconnect()
	end

	tempPositionSpring = nil
end)