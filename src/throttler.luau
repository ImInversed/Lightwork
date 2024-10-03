local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

local throttler = {}

function throttler.updateAsync(key: string, dataStore: DataStore, transform: (...any) -> (string, { any }, { number }))
	return Promise.new(function(resolve, _, _)
		dataStore:UpdateAsync(key, function(...)
			local result, transformed, userIds = transform(...)

			if result ~= "success" then
				warn(result)
				return nil
			end

			print(transformed, userIds)

			return transformed, userIds
		end)

		resolve()
	end)
end

return throttler
