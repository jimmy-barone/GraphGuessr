local HintManager = {}

local playerHints = {}

function HintManager.Set(player, amount)
	playerHints[player.UserId] = amount
end

function HintManager.Get(player)
	return playerHints[player.UserId] or 0
end

function HintManager.Decrement(player)
	if playerHints[player.UserId] and playerHints[player.UserId] > 0 then
		playerHints[player.UserId] -= 1
	end
end

function HintManager.HasHints(player)
	return (playerHints[player.UserId] or 0) > 0
end

function HintManager.Remove(player)
	playerHints[player.UserId] = nil
end

function HintManager.GetAll()
	return playerHints
end

return HintManager
