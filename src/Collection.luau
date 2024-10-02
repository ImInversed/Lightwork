local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage.Packages
local Promise = require(packages.Promise)

local Document = require(script.Parent.Document)
local documentSaver = require(script.Parent.documentSaver)

local SESSION_LOCK_EXPIRE = 20 * 60

local Collection = {}
Collection.__index = Collection

function Collection.new(name: string, dataTemplate)
	local self = setmetatable({}, Collection)

	self._name = name
	self._dataTemplate = dataTemplate
	self._datastore = DataStoreService:GetDataStore(name)

	return self
end

function Collection:load(key: string)
	local canFail = function()
		return Promise.new(function(resolve, reject)
			local result, keyInfo: DataStoreKeyInfo = self._datastore:UpdateAsync(
				key,
				function(value, dataStoreKeyInfo: DataStoreKeyInfo)
					if value == nil then
						value = {
							data = self._dataTemplate,
							sessionId = nil,
						}
					end

					if
						value.sessionId ~= nil
						and (DateTime.now().UnixTimestampMillis - dataStoreKeyInfo.UpdatedTime) / 1000
							< SESSION_LOCK_EXPIRE
					then
						reject("SessionLocked")
					else
						value.sessionId = HttpService:GenerateGUID(false)
					end

					return value
				end
			)

			resolve(result, keyInfo)
		end)
	end

	return Promise.retryWithDelay(canFail, 5, 1):andThen(function(result)
		local document = Document.new(self._datastore, result, result.sessionId, key)

		documentSaver.addDocument(document, key)

		return document
	end)
end

return Collection
