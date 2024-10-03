local function freezeDeep(t)
	local valueType = typeof(t)

	if valueType == "table" then
		local newValue = {}

		for key, value in pairs(t) do
			newValue[key] = freezeDeep(value)
		end

		return table.freeze(newValue)
	else
		return t
	end
end

return freezeDeep
