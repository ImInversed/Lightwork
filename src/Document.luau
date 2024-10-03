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
	self._beforeSaveHooks = {}
	self._afterSaveHooks = {}
	self._beforeCloseHooks = {}

	self._data.data = freezeDeep(data.data)

	return self
end

function Document:write(newData)
	self._data.data = freezeDeep(newData)
end

function Document:save()
	for _, beforeSaveHook in self._beforeSaveHooks do
		beforeSaveHook()
	end

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
		end):finally(function()
			for _, afterSaveHook in self._afterSaveHooks do
				afterSaveHook()
			end
		end)
	end, 5, 1)
end

function Document:read()
	return self._data.data
end

function Document:close()
	for _, closingHook in self._beforeCloseHooks do
		closingHook()
	end

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

function Document:beforeSaving(callback)
	table.insert(self._beforeSaveHooks, callback)
end

function Document:afterSaving(callback)
	table.insert(self._afterSaveHooks, callback)
end

function Document:beforeClosing(callback)
	table.insert(self._beforeCloseHooks, callback)
end

return Document
