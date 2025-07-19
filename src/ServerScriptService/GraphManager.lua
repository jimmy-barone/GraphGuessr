local GraphManager = {}

local GraphDrawer = require(game.ServerScriptService.GraphDrawer)
local ConfigSpace = require(game.ServerScriptService.Configure_Space)



local function DrawSurface(def)
	if def.ParamSurface then
		local g = def.ParamSurface
		GraphDrawer.DrawParamSurface(g.x, g.y, g.z, 
			g.uMin, g.uMax, g.uStep, 
			g.vMin, g.vMax, g.vStep)
		return
	elseif def.usePlane then
		GraphDrawer.DrawConstantPlane(def.f, def.span, def.color)
		return
	elseif def.obliquePlane then
		GraphDrawer.DrawObliquePlane(def.span, def.color, def.normal, def.offset)
		return
	else
		GraphDrawer.DrawSurface(def.f, def.span, def.step, 
			def.color, def.use_elevation_coloring)
		return
	end
end



local function DrawCurve(def)
	if def.Param2D then
		local g = def.Param2D
		GraphDrawer.DrawParam2D(g.x, g.y, g.tMin, g.tMax, g.step)
		print("Attempting to draw parametric curve in R2")
	elseif GraphDrawer.isConstant(def.f) then
		GraphDrawer.DrawConstant(def.f, def.domain, def.color)
	elseif GraphDrawer.isVerticalLine(def) then
		print("Drawing vertical line")
		GraphDrawer.DrawVerticalLine(def.x, def.domain.min, def.domain.max)
	else
		GraphDrawer.Draw2D(def.f, def.domain, def.step, 
			def.color or Color3.new(1, 0, 0.0156863), 
			def.adjustment or Vector3.new(0, 0, 0))
	end
end



function GraphManager.DrawGraphByType(def)
	if def.direct_model then
		GraphDrawer.DrawDirectModel(def)
		return
	end
	if def.Point2D then
		local g = def.Point2D
		GraphDrawer.DrawPoint2D(g.x, g.y, def.color)
		return
	end

	if def.Point3D then
		local g = def.Point3D
		GraphDrawer.DrawPoint3D(g.x, g.y, g.z, g.color)
		return
	end

	if def.Surface then
		DrawSurface(def)
	else
		DrawCurve(def)
	end

end

return GraphManager
