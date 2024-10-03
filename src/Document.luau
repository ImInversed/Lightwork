local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

local Document = {}
Document.__index = Document

function Document.new(dataStore, data, sessionId: string, key: string)
	local self = setmetatable({}, Document)

	self._dataStore = dataStore
	self._key = key
	self._data = data
	self._sessionId = sessionId

	return self
end

function Document:write(newData)
	self._data.data = newData
end

function Document:save()
	local canFail = function()
		return Promise.new(function(resolve, _)
			local result, keyInfo: DataStoreKeyInfo = self._dataStore:UpdateAsync(self._key, function(currentData)
				if currentData == nil then
					print("Fail")

					return
				end

				if currentData.sessionId ~= self._sessionId then
					print("Session was stolen from us")

					return
				end

				return self._data
			end)

			resolve(result, keyInfo)
		end)
	end

	return Promise.retryWithDelay(canFail, 5, 1)
end

function Document:read() end

function Document:close()
	print("Closing")

	pcall(function()
		self._dataStore:UpdateAsync(self._key, function(currentData)
			if currentData == nil then
				print("Fail")

				return
			end

			if currentData.sessionId ~= self._sessionId then
				print("Session was stolen from us")

				return
			end

			-- Perfect, we own the current sessionId, therefore we can close it.

			print("Closed")

			self._data.sessionId = nil

			return self._data
		end)
	end)
end

return Document
