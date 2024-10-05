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

export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type Promise = {
	andThen: (
		self: Promise,
		successHandler: (...any) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,
	andThenCall: <T...>(self: Promise, callback: (T...) -> ...any, T...) -> any,
	andThenReturn: (self: Promise, ...any) -> Promise,

	await: (self: Promise) -> (boolean, ...any),
	awaitStatus: (self: Promise) -> (Status, ...any),

	cancel: (self: Promise) -> (),
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	expect: (self: Promise) -> ...any,

	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	finallyCall: <T...>(self: Promise, callback: (T...) -> ...any, T...) -> Promise,
	finallyReturn: (self: Promise, ...any) -> Promise,

	getStatus: (self: Promise) -> Status,
	now: (self: Promise, rejectionValue: any?) -> Promise,
	tap: (self: Promise, tapHandler: (...any) -> ...any) -> Promise,
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

export type TypedPromise<T...> = {
	andThen: (self: Promise, successHandler: (T...) -> ...any, failureHandler: ((...any) -> ...any)?) -> Promise,
	andThenCall: <T...>(self: Promise, callback: (T...) -> ...any, T...) -> Promise,
	andThenReturn: (self: Promise, ...any) -> Promise,

	await: (self: Promise) -> (boolean, T...),
	awaitStatus: (self: Promise) -> (Status, T...),

	cancel: (self: Promise) -> (),
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	expect: (self: Promise) -> T...,

	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	finallyCall: <T...>(self: Promise, callback: (T...) -> ...any, T...) -> Promise,
	finallyReturn: (self: Promise, ...any) -> Promise,

	getStatus: (self: Promise) -> Status,
	now: (self: Promise, rejectionValue: any?) -> Promise,
	tap: (self: Promise, tapHandler: (T...) -> ...any) -> Promise,
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

export type Collection<T> = {
	load: (self: Collection<T>, key: string, userIds: { number }?) -> TypedPromise<Document<T>>,
	read: (self: Collection<T>, key: string) -> TypedPromise<T?>,
	remove: (self: Collection<T>, key: string) -> TypedPromise<()>,
}

export type Document<T> = {
	read: (self: Document<T>) -> T,
	write: (self: Document<T>, T) -> (),
	save: (self: Document<T>) -> TypedPromise<()>,
	close: (self: Document<T>) -> TypedPromise<()>,
	beforeSaving: (self: Document<T>, callback: () -> ()) -> (),
	afterSaving: (self: Document<T>, callback: () -> ()) -> (),
	beforeClosing: (self: Document<T>, callback: () -> ()) -> (),
}

local Collection = require(script.Collection)
local documentSaver = require(script.documentSaver)
local throttler = require(script.throttler)

throttler.start()
documentSaver.start()

local function createCollection<T>(
	name: string,
	dataTemplate: unknown,
	migrations: { (data: unknown) -> () }
): Collection<T>
	return Collection.new(name, dataTemplate, migrations)
end

return {
	createCollection = createCollection,
}
