local RunService = game:GetService("RunService")

local UPDATE_INTERVAL = 5 * 60

local documents = {}

local function addDocument(document, key: string)
	documents[key] = document
end

local function removeDocument(key: string)
	documents[key] = nil
end

local function start()
	local nextUpdateAt = os.time() + UPDATE_INTERVAL

	RunService.Heartbeat:Connect(function()
		if os.time() >= nextUpdateAt then
			nextUpdateAt = os.time() + UPDATE_INTERVAL

			for _, document in documents do
				document:save():catch(warn)
			end
		end
	end)

	game:BindToClose(function() end)
end

return {
	addDocument = addDocument,
	removeDocument = removeDocument,
	start = start,
}
