local GridLines = {}



function GridLines.GenerateGridlines(range, spacing)
	local gridFolder = workspace.GridLines


	--Consider tweaking this 
	local lineThickness = 0.5 -- very thin in Z (flat on XY plane)
	local lineLength = range * 2


	local function getStartAndEnd(range, spacing)
		local start = -math.floor(range / spacing) * spacing
		local finish = math.floor(range / spacing) * spacing
		return start, finish
	end

	local startX, endX = getStartAndEnd(range, spacing)
	local startY, endY = getStartAndEnd(range, spacing)


	for x = startX, endX, spacing do
		local line = Instance.new("Part")
		line.Size = Vector3.new(lineThickness, lineLength, lineThickness)
		line.Position = Vector3.new(x, 0, 0)
		line.Anchored = true
		line.CanCollide = false
		line.CastShadow = false
		line.Color = Color3.fromRGB(150, 150, 150)
		line.Name = "GridLineX"
		line.Parent = gridFolder
	end

	for y = startY, endY, spacing do
		local line = Instance.new("Part")
		line.Size = Vector3.new(lineLength, lineThickness, lineThickness)
		line.Position = Vector3.new(0, y, 0)
		line.Anchored = true
		line.CanCollide = false
		line.CastShadow = false
		line.Color = Color3.fromRGB(150, 150, 150)
		line.Name = "GridLineY"
		line.Parent = gridFolder
	end
end

function GridLines.RemoveGridLines()
	for idx, child in pairs(game.Workspace:FindFirstChild("GridLines"):GetChildren()) do
		child.Transparency = 1
	end
end

function GridLines.restoreGridLines()
	for idx, child in pairs(game.Workspace:FindFirstChild("GridLines"):GetChildren()) do
		child.Transparency = 0
	end
end


return GridLines
