local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

local Document = require(script.Parent.Document)
local documentSaver = require(script.Parent.documentSaver)
local throttler = require(script.Parent.throttler)

local SESSION_LOCK_EXPIRE = 20 * 60

local Collection = {}
Collection.__index = Collection

function Collection.new(name: string, dataTemplate)
	local self = setmetatable({}, Collection)

	self._name = name
	self._dataTemplate = dataTemplate
	self._dataStore = DataStoreService:GetDataStore(name)

	return self
end

function Collection:load(key: string)
	return Promise.retryWithDelay(function()
		return throttler.updateAsync(key, self._dataStore, function(currentData, dataStoreKeyInfo: DataStoreKeyInfo)
			currentData = nil
			if currentData == nil then
				currentData = {
					data = self._dataTemplate,
					sessionId = nil,
				}
			end

			if
				currentData.sessionId ~= nil
				and (DateTime.now().UnixTimestampMillis - dataStoreKeyInfo.UpdatedTime) / 1000 < SESSION_LOCK_EXPIRE
			then
				return "fail"
			else
				currentData.sessionId = HttpService:GenerateGUID(false)
			end

			return "success", currentData
		end)
	end, 5, 1):andThen(function(_, data, _)
		local document = Document.new(self._dataStore, data, data.sessionId, key)

		documentSaver.addDocument(document)

		return document
	end)
end

return Collection
