local Players = game:GetService("Players")

local packages = game.ReplicatedStorage.Packages
local lightwork = require(packages.Lightwork)

local collection = lightwork.createCollection("test", {
	coins = 1,
})

local documents = {}

Players.PlayerAdded:Connect(function(player: Player)
	collection:load(player.UserId):andThen(function(document)
		documents[player.UserId] = document

		document:beforeSaving(function()
			print("Hi")
		end)

		document:afterSaving(function()
			print("Hello")
		end)

		document:beforeClosing(function()
			print("closing")
		end)

		document:save():andThen(function()
			print("Ok?")
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	documents[player.UserId]:close():catch(warn)
	print("wabam")
end)
