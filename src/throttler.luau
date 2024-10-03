local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

local requestFulfilled = Instance.new("BindableEvent")

local function getUpdateAsyncBudget()
	return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
end

local function updateUpdateAsync(request)
	return Promise.new(function(resolve, reject, _)
		local success, transformedData, keyInfo = pcall(function()
			return request.dataStore:UpdateAsync(request.key, function(...)
				local result, transformed, userIds = request.transform(...)

				if result ~= "success" then
					warn(result)
					return nil
				end

				return transformed, userIds
			end)
		end)

		if success then
			resolve(transformedData, keyInfo)
		else
			reject()
		end

		requestFulfilled:Fire(request.key, transformedData, keyInfo)
	end)
end

local throttler = {}
throttler.queue = {}
throttler.requestFulfilled = requestFulfilled.Event

function throttler.updateAsync(key: string, dataStore: DataStore, transform: (...any) -> (string, { any }, { number }))
	table.insert(throttler.queue, {
		key = key,
		dataStore = dataStore,
		transform = transform,
	})

	return Promise.fromEvent(throttler.requestFulfilled, function(fulfilledKey: string, _, _)
		return fulfilledKey == key
	end)
end

function throttler.start()
	RunService.Heartbeat:Connect(function()
		local request = throttler.queue[1]

		if not request then
			return
		end

		if getUpdateAsyncBudget() == 0 then
			return
		end

		updateUpdateAsync(request)

		table.remove(throttler.queue, 1)
	end)
end

return throttler
