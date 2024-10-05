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

function Collection.new(name: string, dataTemplate, migrations)
	local self = setmetatable({}, Collection)

	self._name = name
	self._dataTemplate = dataTemplate
	self._dataStore = DataStoreService:GetDataStore(name)
	self._migrations = migrations

	return self
end

function Collection:load(key: string)
	return Promise.retryWithDelay(function()
		return throttler.updateAsync(key, self._dataStore, function(currentData, dataStoreKeyInfo: DataStoreKeyInfo)
			if currentData == nil then
				currentData = {
					data = self._dataTemplate,
					sessionId = nil,
					migrationVersion = #self._migrations,
				}
			end

			if
				currentData.sessionId ~= nil
				and (DateTime.now().UnixTimestampMillis - dataStoreKeyInfo.UpdatedTime) / 1000 < SESSION_LOCK_EXPIRE
			then
				return "session locked"
			else
				currentData.sessionId = HttpService:GenerateGUID(false)
			end

			local serverVersion = #self._migrations
			local savedVersion = currentData.migrationVersion

			if serverVersion > savedVersion then
				for version = savedVersion + 1, #self._migrations do
					local ok, data = pcall(self._migrations[version], currentData.data)

					if not ok then
						return false, `Migration {version} threw an error: {data}`
					end

					if data == nil then
						return false, `Migration {version} returned 'nil'`
					end

					currentData.data = data
				end
			end

			currentData.migrationVersion = serverVersion

			return "success", currentData
		end)
	end, 5, 1):andThen(function(_, data, _)
		local document = Document.new(self._dataStore, data, data.sessionId, key)

		documentSaver.addDocument(document)

		return document
	end)
end

return Collection
