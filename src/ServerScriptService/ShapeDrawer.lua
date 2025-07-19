local Globals = require(game.ServerScriptService.Globals)
local GraphDrawer = require(game.ServerScriptService.GraphDrawer)
local ActiveShape = workspace.ActiveShape

local ShapeDrawer = {}

local maxX = 10
local maxY = 10
local minWidth = 2
local minHeight = 2
local scale = Globals.SCALE_XZ

function ShapeDrawer.clearShape()
	for _, child in ipairs(ActiveShape:GetChildren()) do
		child:Destroy()
	end
end

function ShapeDrawer.generateSimplePolygon()
	local origin = Vector2.new(scale * math.random(0, maxX), scale * math.random(0, maxY))

	local shapeType = math.random(1, 2) == 1 and "Triangle" or "Rectangle"

	if shapeType == "Rectangle" then
		local width = math.random(minWidth, 10)
		local height = math.random(minHeight, 10)

		local p1 = origin
		local p2 = origin + Vector2.new(width * scale, 0)
		local p3 = origin + Vector2.new(width * scale, height * scale)
		local p4 = origin + Vector2.new(0, height * scale)

		local vertices = { p1, p2, p3, p4 }
		local area = width * height
		return vertices, area
	elseif shapeType == "Triangle" then
		local base = math.random(minWidth, 10)
		local height = math.random(minHeight, 10)

		--Always a right triangle for the easy rounds since it's easier to calculate area
		local p1 = origin
		local p2 = origin + Vector2.new(base * scale, 0)
		local p3 = origin + Vector2.new(0, height * scale)

		local vertices = { p1, p2, p3 }
		local area = 0.5 * base * height
		return vertices, area
	end
end

local function isRegularPolygon(radii)
	for _, radius in ipairs(radii) do
		if radius ~= radii[1] then
			return false
		end
	end
	return true
end

function ShapeDrawer.generateRandomPolygon(minSides, maxSides, maxRadius, angleVariation)
	local sides = math.random(minSides or 3, maxSides or 12)
	local center = Vector2.new(0, 0)
	local vertices = {}

	for i = 1, sides do
		-- Angle with jitter
		local baseAngle = (2 * math.pi) * (i / sides)
		local jitter = math.rad(math.random(-angleVariation or 0, angleVariation or 0))
		local angle = baseAngle + jitter

		local radius = math.random(8, maxRadius or 20) --If radius were constant we'd get a regular polygon centered at the origin
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius

		table.insert(vertices, Vector2.new(x, y))
	end

	--[[This is necessary - especially if the random variation in the angle is high - to ensure there are no intersecting segments
	Recall that tan(theta) = y/x for a point (x, y), so roughly speaking,
	arctan(y/x) = arctan(tan(theta)) = theta (atan2 determines the correct quadrant)
	Thus this function is sorting in order of increasing theta going counterclockwise
	--]]
	table.sort(vertices, function(a, b)
		return math.atan2(a.Y, a.X) < math.atan2(b.Y, b.X)
	end)

	return vertices
end

function ShapeDrawer.shoelaceArea(vertices)
	local n = #vertices
	local area = 0
	for i = 1, n do
		local j = (i % n) + 1
		area += (vertices[i].X * vertices[j].Y) - (vertices[j].X * vertices[i].Y)
	end
	local area_studs = math.abs(area) / 2
	return area_studs / (scale * scale)
end

function ShapeDrawer.DrawPolygon(vertices)
	for i = 1, #vertices do
		local start = vertices[i]
		local stop = vertices[(i % #vertices) + 1]
		GraphDrawer.DrawSegment(start, stop, 1, Color3.new(1, 0, 0)).Parent = ActiveShape
	end
end

function ShapeDrawer.generateControlPoints(n, radius, jitterAmount)
	local controlPoints = {}

	for i = 1, n do
		local angle = (2 * math.pi) * (i / n)
		local jitterX = math.random() * 2 - 1
		local jitterY = math.random() * 2 - 1

		local x = math.cos(angle) * radius + jitterX * jitterAmount
		local y = math.sin(angle) * radius + jitterY * jitterAmount

		table.insert(controlPoints, Vector2.new(x, y))
	end

	-- Add first few points again to make a loopable spline
	table.insert(controlPoints, controlPoints[1])
	table.insert(controlPoints, controlPoints[2])
	table.insert(controlPoints, controlPoints[3])

	return controlPoints
end

local function catmullRom(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t

	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

function ShapeDrawer.sampleSpline(controlPoints, segmentsPerPair)
	local samples = {}

	for i = 1, #controlPoints - 3 do
		local p0 = controlPoints[i]
		local p1 = controlPoints[i + 1]
		local p2 = controlPoints[i + 2]
		local p3 = controlPoints[i + 3]

		for j = 0, segmentsPerPair - 1 do
			local t = j / segmentsPerPair
			local pt = catmullRom(p0, p1, p2, p3, t)
			table.insert(samples, pt)
		end
	end

	return samples
end

return ShapeDrawer
