
local Configure_Space = {}
local xLetter = game.Workspace.TextModel23.X
local yLetter = game.Workspace.TextModel24.Y
local zLetter = game.Workspace.TextModel25.Z
local Letters = {xLetter, yLetter, zLetter}
local Globals = require(game.ServerScriptService.Globals)
local GridLines = require(script.Parent.GridLines)
local GridLinesFolder = game.Workspace.GridLines
local CoordinateAxes = workspace.Coordinate_Axes
local Quadrants = workspace.Quadrants
local Cones = workspace.Cones



local function setTransparency(objects, value)
	return Globals.setTransparency(objects, value)
end


local function toggleSpin(objects, value: boolean)
	for _, letter in ipairs(objects) do
		if letter:FindFirstChild("Spin") then
			letter.Spin.Enabled = value
		end
	end
end

local function lockOrientation()
	xLetter.Orientation = Vector3.new(0, 180, 0)
	yLetter.Orientation = Vector3.new(0, 180, 0)
	zLetter.Orientation = Vector3.new(0, -180, 0)
end


function Configure_Space.clear_environment()
	GridLines.RemoveGridLines()
	setTransparency(CoordinateAxes, 1)
	setTransparency(Quadrants, 1)
	setTransparency(Cones, 1)
	setTransparency(Letters, 1)
end


function Configure_Space.reset_environment()
	GridLines.restoreGridLines()
	setTransparency(CoordinateAxes, 0)
	setTransparency(Quadrants, 0)
	setTransparency(Cones, 0)
	setTransparency(Letters, 0)
end
	
	

function Configure_Space.swap_coordinate_axes(upward_axis_name)
	if upward_axis_name == "z" then
		xLetter.Position = Globals.axis_label_positions["z"]
		yLetter.Position = Globals.axis_label_positions["x"]
		zLetter.Position = Globals.axis_label_positions["y"]
	elseif upward_axis_name == "y" or not upward_axis_name then
		xLetter.Position = Globals.axis_label_positions["x"]
		yLetter.Position = Globals.axis_label_positions["y"]
		zLetter.Position = Globals.axis_label_positions["z"]
	elseif upward_axis_name == "x" then
		xLetter.Position = Globals.axis_label_positions["y"]
		yLetter.Position = Globals.axis_label_positions["z"]
		zLetter.Position = Globals.axis_label_positions["x"]
	else
		warn("Error: " .. upward_axis_name .. " is not a valid axis name.")
	end
end



function Configure_Space.configureSpaceEasy()
	GridLines.restoreGridLines()
	toggleSpin(Letters, false)
	lockOrientation()
	zLetter.Transparency = 1
	setTransparency(Quadrants, 0)
end


function Configure_Space.configureSpaceHard()
	GridLines.RemoveGridLines()
	toggleSpin(Letters, true)
	zLetter.Transparency = 0
	setTransparency(Quadrants, 1)
end


return Configure_Space
