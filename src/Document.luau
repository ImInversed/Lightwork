local ReplicatedStorage = game:GetService("ReplicatedStorage")

local documentSaver = require(script.Parent.documentSaver)
local freezeDeep = require(script.Parent.freezeDeep)
local throttler = require(script.Parent.throttler)

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

	-- nil returns in UpdateAsync calls cancel the operation. Which is nice

	return Promise.retryWithDelay(function()
		throttler
			.updateAsync(self._key, self._dataStore, function(currentData)
				if currentData == nil then
					return "failed"
				end

				if currentData.sessionId ~= self._sessionId then
					return "session was stolen"
				end

				return "success", self._data
			end)
			:finally(function()
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
		pcall(closingHook)
	end

	documentSaver.removeDocument(self)

	return throttler.updateAsync(self._key, self._dataStore, function(currentData)
		if currentData == nil then
			return "fail"
		end

		if currentData.sessionId ~= self._sessionId then
			return "session was stolen"
		end

		self._data.sessionId = nil

		return "success", self._data
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
