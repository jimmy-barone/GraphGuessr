local Queue = {}

return {
	Enqueue = function(player, category)
		table.insert(Queue, {plr = player, category = category})
	end,

	Dequeue = function()
		return table.remove(Queue, 1)
	end,

	Clear = function()
		Queue = {}
	end,

	IsEmpty = function()
		return #Queue == 0
	end,

	Length = function()
		return #Queue
	end,
}
