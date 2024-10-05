local Players = game:GetService("Players")

local packages = game.ReplicatedStorage.Packages
local lightwork = require(packages.Lightwork)

local currentDataTemplate = {
	coins = 0,
}

--[[
	some important information when using migrations:

	1. you do not remove migrations, it will cause errors.
]]
local collection = lightwork.createCollection("test", currentDataTemplate, {
	-- Version 2
	function(oldData)
		oldData.gems = 0

		print("added gems")

		return oldData
	end,

	-- Version 3
	function(oldData)
		oldData.coins = nil

		print("removed coins")

		return oldData
	end,
})

local documents = {}

Players.PlayerAdded:Connect(function(player: Player)
	collection:load(player.UserId):andThen(function(document)
		documents[player.UserId] = document

		document:beforeSaving(function()
			print("Hi")
		end)
		print(document:read())
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
