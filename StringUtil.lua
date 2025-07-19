local StringUtil = {}

local function normalizeEquationSides(equation)
	local lhs, rhs = equation:match("^(.-)=(.+)$")
	if not lhs or not rhs then
		error("Equation must contain '='.")
	end
	return lhs:gsub("%s+", ""), rhs:gsub("%s+", "")
end

local function parseSide(expr, sign)
	local coeffs = { x = 0, y = 0, z = 0, const = 0 }
	expr = expr:gsub("-", "+-")

	for term in expr:gmatch("[^%+]+") do
		local num, var = term:match("^([+-]?%d*%.?%d*)%*?([xyz])$")
		if var then
			num = num == "" and "1" or (num == "+" and "1" or (num == "-" and "-1" or num))
			coeffs[var] += sign * tonumber(num)
		else
			local numOnly = tonumber(term)
			if numOnly then
				coeffs.const += sign * numOnly
			else
				error("Unrecognized term: " .. term)
			end
		end
	end

	return coeffs
end

local function calculateCoefficients(lhs, rhs)
	local left = parseSide(lhs, 1)
	local right = parseSide(rhs, -1)

	return {
		A = left.x + right.x,
		B = left.y + right.y,
		C = left.z + right.z,
		D = left.const + right.const,
	}
end

local function generatePointOnPlane(coeffs)
	local x = math.random(-10, 10)
	local y = math.random(-10, 10)
	local z

	if coeffs.C ~= 0 then
		z = (coeffs.D - coeffs.A * x - coeffs.B * y) / coeffs.C
	elseif coeffs.B ~= 0 then
		y = (coeffs.D - coeffs.A * x) / coeffs.B
		z = 0
	elseif coeffs.A ~= 0 then
		x = coeffs.D / coeffs.A
		y = 0
		z = 0
	else
		x, y, z = 0, 0, 0
	end

	return Vector3.new(x, y, z)
end

function StringUtil.ParsePlaneEquation(equation)
	local lhs, rhs = normalizeEquationSides(equation)
	local coeffs = calculateCoefficients(lhs, rhs)

	if coeffs.A == 0 and coeffs.B == 0 and coeffs.C == 0 then
		error("Invalid plane: zero normal vector")
	end

	local normal = Vector3.new(coeffs.A, coeffs.B, coeffs.C)
	local offset = generatePointOnPlane(coeffs)
	return normal, offset
end

return StringUtil
