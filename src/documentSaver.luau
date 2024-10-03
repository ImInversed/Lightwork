local RunService = game:GetService("RunService")

local UPDATE_INTERVAL = 5 * 60

local documents = {}

local function addDocument(document)
	table.insert(documents, document)
end

local function removeDocument(document)
	local index = table.find(documents, document)

	table.remove(documents, index)
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

	game:BindToClose(function()
		while #documents > 0 do
			documents[1]:close():await()

			table.remove(documents, 1)
		end
	end)
end

return {
	addDocument = addDocument,
	removeDocument = removeDocument,
	start = start,
}
