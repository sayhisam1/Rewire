--!strict
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Constants = require(script.Parent.Constants)

local HotReloader = {}
HotReloader.__index = HotReloader

--[=[
	@class HotReloader
]=]

type Context = {
	originalModule: ModuleScript,
	isReloading: boolean,
}

--[=[
	@interface Context
	@within HotReloader

	.originalModule ModuleScript
	.isReloading boolean
]=]

--[=[
	Creates a new HotReloader.

	@return HotReloader
]=]
function HotReloader.new()
	local self = setmetatable({
		_listeners = {},
		_clonedModules = {},
	}, HotReloader)
	return self
end

--[=[
	Cleans up this HotReloader, forgetting about any previously modules that were being listened to.
]=]
function HotReloader:destroy()
	for _, listener: RBXScriptConnection in pairs(self._listeners) do
		listener:Disconnect()
	end
	self._listeners = {}
	for _, cloned in pairs(self._clonedModules) do
		cloned:Destroy()
	end
	self._clonedModules = {}
end

--[=[
	Listen to changes from a single module.

	Runs the given `callback` once to start, and then again whenever the module changes.

	Runs the given `cleanup` callback after a module is changed, but before `callback` is run.

	Both are passed a [Context] object, which contains information about the original module
	and whether or not the script is reloading.

	- For `callback`, `Context.isReloading` is true if running as a result of a hot-reload (false indicates first run).
	- For `cleanup`, `Context.isReloading` is true if the module is about to be hot-reloaded (false indicates this is the last cleanup).

	@param module -- The original module to attach listeners to
	@param callback -- A callback that runs when the ModuleScript is added or changed
	@param cleanup -- A callback that runs when the ModuleScript is changed or removed
]=]
function HotReloader:listen(
	_module: ModuleScript | { ModuleScript },
	callback: (ModuleScript, Context) -> (),
	cleanup: (ModuleScript, Context) -> ()
)
	local scripts = if type(_module) ~= "table" then { _module } else _module

	for _, module in ipairs(scripts) do
		if RunService:IsStudio() then
			local moduleChanged = module.Changed:Connect(function()
				local originalStillExists = game:IsAncestorOf(module)

				local cleanupContext = {
					isReloading = originalStillExists,
					originalModule = module,
				}

				if self._clonedModules[module] then
					cleanup(self._clonedModules[module], cleanupContext)
					self._clonedModules[module]:Destroy()
				else
					cleanup(module, cleanupContext)
				end

				if not originalStillExists then
					return
				end

				local cloned = module:Clone()

				CollectionService:AddTag(cloned, Constants.CollectionServiceTag)

				cloned.Parent = module.Parent
				self._clonedModules[module] = cloned

				callback(cloned, {
					originalModule = module,
					isReloading = true,
				})
				warn(("HotReloaded %s!"):format(module:GetFullName()))
			end)
			table.insert(self._listeners, moduleChanged)
		end

		callback(module, {
			originalModule = module,
			isReloading = false,
		})
	end
end

--[=[
	Scans current and new descendants of an object for ModuleScripts, and runs `callback` for each of them.

	This function has the same semantics as [HotReloader:listen].

	@param container -- The root instance
	@param callback -- A callback that runs when the ModuleScript is added or changed
	@param cleanup -- A callback that runs when the ModuleScript is changed or removed
]=]
function HotReloader:scan(
	_containers: Instance | { Instance },
	callback: (ModuleScript, Context) -> (),
	cleanup: (ModuleScript, Context) -> ()
)
	local function add(module)
		self:listen(module, callback, cleanup)
	end

	local containers = if type(_containers) ~= "table" then { _containers } else _containers

	for _, container in ipairs(containers) do
		for _, instance in container:GetDescendants() do
			if instance:IsA("ModuleScript") then
				add(instance)
			end
		end

		local descendantAdded = container.DescendantAdded:Connect(function(instance)
			if
				instance:IsA("ModuleScript") and not CollectionService:HasTag(instance, Constants.CollectionServiceTag)
			then
				add(instance)
			end
		end)

		table.insert(self._listeners, descendantAdded)
	end
end

return HotReloader
