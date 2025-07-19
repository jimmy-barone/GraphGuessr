local Util = {}


function Util.countParts(folder)
	local count = 0
	for _, part in pairs(folder:GetChildren()) do
		count += 1
	end
	return count
end

function Util.AreOrthogonal(v1: Vector3, v2: Vector3)
	--Account for limited precision, check if dot product is very close to 0
	return math.abs(v1:Dot(v2)) < 1e-6 
end


return Util
