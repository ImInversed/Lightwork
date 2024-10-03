local ReplicatedStorage = game:GetService("ReplicatedStorage")

local documentSaver = require(script.Parent.documentSaver)
local freezeDeep = require(script.Parent.freezeDeep)

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

type Data = {
	sessionId: string?,
	data: { unknown },
}

local Document = {}
Document.__index = Document

function Document.new(dataStore, data: Data, sessionId: string, key: string)
	local self = setmetatable({}, Document)

	self._dataStore = dataStore
	self._key = key
	self._data = data
	self._sessionId = sessionId

	return self
end

function Document:write(newData)
	freezeDeep(newData)

	self._data.data = newData
end

function Document:save()
	return Promise.retryWithDelay(function()
		return Promise.new(function(resolve, reject)
			local result, keyInfo: DataStoreKeyInfo = self._dataStore:UpdateAsync(
				self._key,
				function(currentData: Data?)
					if currentData == nil then
						reject("Fail")

						return
					end

					if currentData.sessionId ~= self._sessionId then
						reject("Session was stolen from us")

						return
					end

					return self._data
				end
			)

			resolve(result, keyInfo)
		end)
	end, 5, 1)
end

function Document:read()
	return self._data.data
end

function Document:close()
	documentSaver.removeDocument(self)

	return Promise.new(function(resolve, reject)
		local data, keyInfo = self._dataStore:UpdateAsync(self._key, function(currentData: Data?)
			if currentData == nil then
				reject("Fail")

				return currentData
			end
			if currentData.sessionId ~= self._sessionId then
				reject("Session was stolen from us")

				return currentData
			end

			self._data.sessionId = nil

			return self._data
		end)

		resolve("success", data, keyInfo)
	end)
end

return Document
