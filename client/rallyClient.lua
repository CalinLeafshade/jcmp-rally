
local function mapToWorld(v)
	origin = Vector3(-16384, 0, -16384)
	v = v + origin
	return v
end

local rallyStart = function(dest)
	dest = mapToWorld(Vector3(dest[1],0,dest[2]))
	Waypoint:SetPosition(dest)
end
-- Subscribe ClientFunction to the network event "Test".
Network:Subscribe("RallyStart", rallyStart)