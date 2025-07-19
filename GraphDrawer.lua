local GraphDrawer = {}
local Util = require(game.ServerScriptService.Util)
local Globals = require(game.ServerScriptService.Globals)
local ActiveGraphs = "ActiveGraph"
local ActiveShape = workspace.ActiveShape
local ActiveGraph = workspace.ActiveGraph
local graphingRadius = 300
local red = Color3.new(1, 0, 0.0156863)
local pointSize = Vector3.new(5, 5, 5)
local ORIGIN    = Vector3.new(0, 0, 0)  
local SCALE_XZ  = Globals.SCALE_XZ
local SCALE_Y   = Globals.SCALE_Y                 



local function toWorldXZ(x, z)
	return Vector3.new(x * SCALE_XZ, 0, z * SCALE_XZ) + ORIGIN
end

local function toWorldXYZ(x, y, z)
	local p = toWorldXZ(x, z)
	return Vector3.new(p.X, y * SCALE_Y + ORIGIN.Y, p.Z)
end

local function _toWorldXYZ(x, y, z, adjustment)
	local dx = adjustment.X
	return Vector3.new((x + dx) * SCALE_XZ, y * SCALE_Y, z * SCALE_XZ) + ORIGIN
end


local DEFAULT_STEP_2D   = 0.25
local DEFAULT_STEP_3D   = 1        
local SEG_THICKNESS     = 3    
local SURF_THICKNESS    = 2        


local function getRunFolder()
	return Globals.getRunFolder(ActiveGraphs)
end


function GraphDrawer.DrawSegment(p1: Vector2, p2: Vector2, thickness: number?, color: Color3?)
	local v1 = Vector3.new(p1.X, p1.Y, 0)
	local v2 = Vector3.new(p2.X, p2.Y, 0)
	local line = Instance.new("Part")

	line.Anchored = true
	line.CanCollide = false
	line.CastShadow = false
	line.Locked = true
	line.Material = Enum.Material.Neon
	line.Color = color or Color3.new(1, 1, 1)
	line.Size = Vector3.new(thickness or 0.2, thickness or 0.2, (v2 - v1).Magnitude)
	local midpoint = (v1 + v2) / 2
	line.CFrame = CFrame.lookAt(midpoint, v2)
	line.Name = "Segment2D"
	return line
end


local function makeTile(x, y, z, step, color)
	local tile       = Instance.new("Part")
	tile.Anchored    = true
	tile.CastShadow  = false
	tile.CanCollide  = true
	tile.Locked      = true
	tile.Material    = Enum.Material.SmoothPlastic
	tile.Color       = color
	tile.Size        = Vector3.new(step, SURF_THICKNESS, step)
	tile.Position    = Vector3.new(x, y, z)
	return tile
end


function GraphDrawer.Clear()
	getRunFolder():ClearAllChildren()
end


function GraphDrawer.isConstant(func)
	if not func then return end
	local a = func(0)
	for dx = -5, 5 do
		if func(dx) ~= a then return false end
	end
	return true
end


function GraphDrawer.isVerticalLine(def)
	return def.isVerticalLine
end


function GraphDrawer.DrawVerticalLine(x, yMin, yMax)
	local midY = (yMin + yMax) / 2
	local height = yMax - yMin
	local part = Instance.new("Part")
	part.Anchored = true
	local thickness = SEG_THICKNESS / SCALE_XZ
	part.Size = Vector3.new(thickness, height, thickness)
	part.Position = toWorldXYZ(x, midY, 0)
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 0, 0.0156863)
	part.Parent = ActiveGraph
end


function GraphDrawer.DrawConstant(func, domain, color)
	local y = func(0)
	local minX, maxX = domain.min, domain.max
	local midX = (minX + maxX) / 2
	local part = Instance.new("Part")
	part.Anchored = true
	local thickness = SEG_THICKNESS / SCALE_XZ
	part.Size = toWorldXYZ(maxX - minX, thickness, thickness)
	part.Position = toWorldXYZ(midX, y, 0)
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.new(1, 0, 0.0156863)
	part.Parent = ActiveGraph
	part.CastShadow = false
end


function GraphDrawer.DrawConstantPlane(func, span, color)
	local y  = func(0, 0)   
	local height = 1 / SCALE_Y
	local sizeX = (span.xMax - span.xMin)
	local sizeZ = (span.zMax - span.zMin)
	local midX = (span.xMin + span.xMax) / 2
	local midZ = (span.zMin + span.zMax) / 2

	local part        = Instance.new("Part")
	part.Anchored     = true
	part.CanCollide   = true
	part.Size 	      = toWorldXYZ(sizeX, height, sizeZ)
	part.Position     = toWorldXYZ(midX, y, midZ)
	part.Material     = Enum.Material.SmoothPlastic
	part.CastShadow   = false
	part.Color        = color or Color3.new(1, 0, 0.0156863)
	part.Parent       = ActiveGraph
end


--[[
	Accounts for switching the coordinate axes such that y is the vertical axis and the xy plane is the floor,
	rather than the usual xz plane
	Linear transformation that is just the permutation T(x, y, z) -> T(y, z, x)
	Dot product is invariant under this transformation
--]]
local function ToWorldVector(mathVec)
	return Vector3.new(mathVec.Y, mathVec.Z, mathVec.X)
end


local function IsOriginOnPlane(normal, offset)
	return Util.AreOrthogonal(normal, offset)
end



function GraphDrawer.DrawObliquePlane(span, color, normal, offset)
	local folder = ActiveGraph
	
	local normal = ToWorldVector(normal).Unit
	local offset = ToWorldVector(offset)

	-- Pick an arbitrary vector that is not parallel to the normal
	--If <0, 1, 0> happens to be parallel to the plane's normal vector, <1, 0, 0> cannot be (and vice versa)
	local arbitrary = math.abs(normal:Dot(Vector3.new(0, 1, 0))) < 0.99 and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0)


	local right = (normal:Cross(arbitrary)).Unit
	local forward = (normal:Cross(right)).Unit


	local width = (span.xMax - span.xMin)
	local depth = (span.yMax - span.yMin)


	local planePart = Instance.new("Part")
	planePart.Anchored = true
	planePart.CanCollide = false
	local height = 0.5 / SCALE_Y
	planePart.Size = toWorldXYZ(width, height, depth)
	planePart.Color = color or Color3.new(1, 0, 0.0156863)
	planePart.Material = Enum.Material.SmoothPlastic
	planePart.CastShadow = false

	local position
	
	if IsOriginOnPlane(normal, offset) then
		--If plane passes through the origin, there is no need to apply an offset vector
		position = Vector3.new(0, 0, 0)
	else
		local centerOffset = right * ((span.xMin + span.xMax) / 2) + forward * ((span.yMin + span.yMax) / 2)
		position = offset + centerOffset
	end
	
	local lookAtTarget = position + forward
	planePart.CFrame = CFrame.lookAt(position, lookAtTarget, normal)
	planePart.Parent = ActiveGraph
end



function GraphDrawer.Draw2D(func, domain, step, color)
	step = step or DEFAULT_STEP_2D
	local folder = ActiveGraph
	for x = domain.min, domain.max - step, step do
		local p1 = toWorldXYZ(x, func(x), 0)
		local nextX = math.min(x + step, domain.max)
		local p2 = toWorldXYZ(nextX, func(nextX), 0)
		GraphDrawer.DrawSegment(p1, p2, SEG_THICKNESS, color).Parent = folder
	end
end


function GraphDrawer.DrawSurface(func, span, step, color, use_elevation_coloring, useCircle)
	step = step or DEFAULT_STEP_3D
	local folder = ActiveGraph
	local tileSize = step * SCALE_XZ

	for x = span.xMin, span.xMax - step, step do
		for z = span.zMin, span.zMax - step, step do
			if x * x + z * z < graphingRadius then
				local y = func(x, z)
				local worldPos = toWorldXYZ(x, y, z)
				local tileColor = use_elevation_coloring and Color3.fromHSV((y % 20)/20, 1, 1) or (color or red)
				makeTile(worldPos.X, worldPos.Y, worldPos.Z, tileSize, tileColor).Parent = folder
			end
		end
	end
end

function GraphDrawer.DrawParam2D(xOfT, yOfT, tMin, tMax, step)
	local folder = ActiveGraph
	local prevPoint = nil

	local steps = math.floor((tMax - tMin) / step)
	for i = 0, steps do
		local t = tMin + i * step
		local x = xOfT(t)
		local y = yOfT(t)
		local p = toWorldXYZ(x, y, 0)

		if prevPoint then
			GraphDrawer.DrawSegment(prevPoint, p, SEG_THICKNESS, red).Parent = folder
		end

		prevPoint = p
	end
end

function GraphDrawer.DrawParamSurface(xOf, yOf, zOf, uMin, uMax, uStep, vMin, vMax, vStep)
	local folder = ActiveGraph
	local colorFunc = function(y)
		return Color3.fromHSV((y % 20) / 20, 1, 1)
	end

	local uSteps = math.floor((uMax - uMin) / uStep)
	local vSteps = math.floor((vMax - vMin) / vStep)
	local tileSize = ((uStep + vStep) / 2) * SCALE_XZ

	for i = 0, uSteps do
		local u = uMin + i * uStep
		for j = 0, vSteps do
			local v = vMin + j * vStep
			local x = xOf(u, v)
			local y = yOf(u, v)
			local z = zOf(u, v)
			local pos = toWorldXYZ(x, y, z)
			local color = colorFunc(y)
			makeTile(pos.X, pos.Y, pos.Z, tileSize, color).Parent = folder
		end
	end
end

function GraphDrawer.DrawPoint2D(x, y, color)
	local folder = ActiveGraph
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Size = pointSize
	part.Position = toWorldXYZ(x, y, 0)
	part.Color = color or red
	part.Parent = folder
end

function GraphDrawer.DrawPoint3D(x, y, z, color)
	local folder = ActiveGraph
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Size = pointSize
	part.Position = toWorldXYZ(x, y, z)
	part.Color = color or red
	part.Parent = folder
end


--Assumes if the template model for the graph exists, it is already in the right position
--Barely used
function GraphDrawer.DrawDirectModel(def)
	local template = def.direct_model
	if not template then
		warn("No direct model found.")
		return
	end
	local graph = template:Clone()
	graph.Parent= ActiveGraph	
end



return GraphDrawer
