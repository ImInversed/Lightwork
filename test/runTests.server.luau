local Players = game:GetService("Players")

local packages = game.ReplicatedStorage.Packages
local lightwork = require(packages.Lightwork)

local collection = lightwork.createCollection("test", {
	coins = 1,
})

local documents = {}

Players.PlayerAdded:Connect(function(player: Player)
	collection:load(player.UserId):andThen(function(document)
		print(document)
		documents[player.UserId] = document

		local data = document:read()

		print(data)

		document:write({
			coins = 2,
		})
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	documents[player.UserId]:close():catch(warn)
	print("wabam")
end)
