--[[
    TODO:

    API:

    type CollectionOptions = {
        lockSessions: boolean,
    }

    -- Changing this will not update old player's data. You need to migrate their document.
    local dataTemplate = {
        coins = 0,
    }

    local collection = Lightwork.createCollection("hello", dataTemplate, collectionOptions)

    collection:load(key, userIds):andThen(function(document)
        local data = document:read()

        document:save()
    end)

    Desirable Features:

    Session Locking + -- Only allows one server to read and manipulate data.
    Data Validation
    Migrations
    Throttling +
    Forces Immutability +
    Auto Save +
    Hooks + -- Run hooks before and after operations
    Retries + -- Failed datastore requests will be retried
    Bind To Close +
]]

local Collection = require(script.Collection)
local documentSaver = require(script.documentSaver)
local throttler = require(script.throttler)

throttler.start()
documentSaver.start()

local function createCollection(...)
	return Collection.new(...)
end

return {
	createCollection = createCollection,
}
