local RunService = game:GetService("RunService")

local Stepped = if RunService:IsServer() then RunService.Heartbeat else RunService.RenderStepped

local Package = script.Parent
local Packages = Package.Parent
local Index = Packages._Index

local SpringUtils = require(script.SpringUtils)
local Fusion = require(Packages.Fusion)
local Spring = require(Packages.Spring)
local Janitor = require(Packages.Janitor)

local Observer = Fusion.Observer
local Computed = Fusion.Computed
local Value = Fusion.Value

local WEAK_KEYS_METATABLE = {__mode = "k"}

local function toState(stateOrValue)
	if type(stateOrValue) == "table" then
		if stateOrValue.type == "State" then
			return stateOrValue
		end
	end

	return Value(stateOrValue)
end

local function getOutputState(weakOutputState)
	local outputState = next(weakOutputState)
	return outputState
end


-- Spring object
return function (stateOrValue: any, speed: number, damper: number)
	-- Sanitize input
	local sourceState = toState(stateOrValue)
	local speedState = toState(speed or 10)
	local damperState = toState(damper or 1)


	-- Helper functions
	local function createSpring(janitor, initialValue)
		local spring = Spring.new(initialValue)

		if speedState then
			spring.Speed = speedState:get(false)
			janitor:Add(Observer(speedState):onChange(function()
				local value = speedState:get()
				assert(type(value) == "number", "Bad value")
				spring.Speed = value
			end))
		end

		if damperState then
			spring.Damper = damperState:get(false)
			janitor:Add(Observer(damperState):onChange(function()
				local value = damperState:get()
				assert(type(value) == "number", "Bad value")
				spring.Damper = value
			end))
		end

		return spring
	end


	-- Create a new state object
	local weakOutputState = setmetatable({
		[Value(sourceState:get(false))] = true,
	}, WEAK_KEYS_METATABLE)

	local sharedJanitor = Janitor.new()
	local reusedJanitor = Janitor.new()
	local sharedSpring

	sharedJanitor:Add(reusedJanitor, "Destroy")
	sharedJanitor:Add(Observer(sourceState):onChange(function()
		-- Cleanup reused janitor
		reusedJanitor:Cleanup()

		-- Respond to value update
		local value = sourceState:get()
		if value then
			-- Get linearized target value
			local linearValue = SpringUtils.toLinearIfNeeded(value)
			sharedSpring = sharedSpring or createSpring(sharedJanitor, linearValue)
			sharedSpring.Target = linearValue

			-- Animate spring
			reusedJanitor:Add(Stepped:Connect(function()
				-- Get animation data
				local animating, position = SpringUtils.animating(sharedSpring)
				local outputState = getOutputState(weakOutputState)

				-- Guard
				if not outputState then
					sharedJanitor:Destroy()
					return
				end

				-- Animate
				if animating then
					outputState:set(SpringUtils.fromLinearIfNeeded(position))
				else
					reusedJanitor:Cleanup()
					outputState:set(value)
				end
			end))
		else
			warn("Got nil value from emitted source")
		end
	end))


	-- Return state object
	return getOutputState(weakOutputState)
end