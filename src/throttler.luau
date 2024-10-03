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
	return Promise.new(function(resolve, _, _)
		request.dataStore:UpdateAsync(request.key, function(...)
			local result, transformed, userIds = request.transform(...)

			if result ~= "success" then
				warn(result)
				return nil
			end

			print(transformed, userIds)

			return transformed, userIds
		end)

		resolve()
	end):finally(function()
		requestFulfilled:Fire(request.key)
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

	return Promise.fromEvent(throttler.requestFulfilled, function(fulfilledKey: string)
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
