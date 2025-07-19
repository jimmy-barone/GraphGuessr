local Globals = {}

local Players = game:GetService("Players")


Globals.before_first_round_time = 1
Globals.VOTE_DURATION = 5
Globals.ROUND_TIME = 5
Globals.BETWEEN_TIME = 2
Globals.podium_time = 7
Globals.MIN_PLAYERS_FOR_FULL_SCORING = 2  
Globals.PER_QUESTION_POINTS = {5,5,5,5}    
Globals.QUESTIONS_PER_ROUND = 2000  
Globals.marble_guess_time = 25
Globals.SCALE_XZ = 5
Globals.SCALE_Y = 5
Globals.curveChance = 0.9 --During a "guess the area" round, the probability that the figure is a smooth curve rather than a polygon
Globals.pOfSpecial = 0.2
Globals.area_guess_time = 2
Globals.default_points = 1

Globals.axis_label_positions = 
{
		["x"] = Vector3.new(78.796, 6.472, -0.249),
		["-x"] = Vector3.new(-81.428, 6.472, 0.062),
		["z"] = Vector3.new(-0.249, 6.472, 83.927),
		["-z"] = Vector3.new(0.589, 6.472, -83.883),
		["y"] = Vector3.new(0, 109.072, 0),
		["-y"] = Vector3.new(0, -112.227, -0) --Should rarely be used, if ever
}

Globals.numberMap = {
	[1] = "A",
	[2] = "B",
	[3] = "C",
	[4] = "D"
}

function Globals.setTransparency(containerOrList, value)
	if typeof(containerOrList) == "Instance" and containerOrList:IsA("Folder") then
		for _, obj in ipairs(containerOrList:GetChildren()) do
			obj.Transparency = value
		end
	elseif typeof(containerOrList) == "table" then
		for _, obj in ipairs(containerOrList) do
			obj.Transparency = value
		end
	end
end


function Globals.use_minimum_points()
	return #Players:GetPlayers() < Globals.MIN_PLAYERS_FOR_FULL_SCORING
end

function Globals.getRunFolder(FolderName)
	local f = workspace:FindFirstChild(FolderName)
	if not f then
		f = Instance.new("Folder")
		f.Name = FolderName
		f.Parent = workspace
	end
	return f
end


return Globals
