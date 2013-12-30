
class "Tracker"

local function worldToMap(v)
	origin = Vector3(-16384, 0, -16384)
	v = v - origin
	return {v.x,v.z}
end

function Tracker:__init(resolution)
	self.resolution = resolution or 5
	self.timer = Timer()
	self.tickTimer = Timer()
	self.trackedPlayers = {}
	self.trackerData = {}
	self:RegisterEvents()
end

function Tracker:RegisterEvents()
	Events:Subscribe( "PostTick", self, self.PostTick )
	Events:Subscribe( "PlayerEnterVehicle", self, self.PlayerEnterVehicle )
    Events:Subscribe( "PlayerExitVehicle", self, self.PlayerExitVehicle )
	Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
	Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
end

function Tracker:Reset()
	self.trackedPlayers = {}
	self.trackerData = {}
end

function Tracker:Stop()
	self.tracking = false
end

function Tracker:Start()
	self.tracking = true
	self.timer:Restart()
	self.tickTimer:Restart()
	for id,player in pairs(self.trackedPlayers) do
		local vehicle = player:GetVehicle() 
		if vehicle then
			table.insert(self.trackerData[id], { type = "enterVehicle", vehicle = vehicle:GetName(), position = pos,  time = 0 })
		end
	end
end

function Tracker:AddPlayer(player)
	local id = player:GetId()
	self.trackedPlayers[id] = player
	self.trackerData[id] = {}
end

function Tracker:RemovePlayer(player, removeData)
	local id = player:GetId()
	self.trackedPlayers[id] = nil
	if removeData then
		self.trackerData[id] = nil
	end
end

function Tracker:PostTick(args)
	if not self.tracking then return end
	if self.tickTimer:GetSeconds() > self.resolution then
		self.timer:Restart()
		for i,v in pairs(self.trackedPlayers) do
			local pos = worldToMap(v:GetPosition())
			table.insert(self.trackerData[i], { type = "tick", position = pos, time = self.timer:GetSeconds() })
		end
	end
end

function Tracker:PlayerDeath(args)
	if not self.tracking then return end
	local player, id = args.player, args.player:GetId()
	if self.trackedPlayers[id] then
		local pos = worldToMap(player:GetPosition())
		table.insert(self.trackerData[id], { type = "death", position = pos, time = self.timer:GetSeconds() })
		self:RemovePlayer(player, false) -- Dont remove their data, just stop tracking them
	end
end

function Tracker:PlayerQuit(args)
	if not self.tracking then return end
	local player, id = args.player, args.player:GetId()
	if self.trackedPlayers[id] then
		local pos = worldToMap(player:GetPosition())
		table.insert(self.trackerData[id], { type = "quit", position = pos, time = self.timer:GetSeconds() })
		self:RemovePlayer(player, false) -- Dont remove their data, just stop tracking them
	end
end

function Tracker:PlayerEnterVehicle(args)
	if not self.tracking then return end
	local player = args.player
	if self.trackedPlayers[player:GetId()] then
		local vehicle = args.vehicle
		local pos = worldToMap(player:GetPosition())
		table.insert(self.trackerData[player:GetId()], { type = "enterVehicle", vehicle = vehicle:GetName(), position = pos,  time = self.timer:GetSeconds() })
		self:Broadcast(player:GetName() .. " entered a " .. vehicle:GetName())
	end
end

function Tracker:PlayerExitVehicle(args)
	if not self.tracking then return end
	local player = args.player
	if self.trackedPlayers[player:GetId()] then
		local vehicle = args.vehicle
		local pos = worldToMap(player:GetPosition())
		table.insert(self.trackerData[player:GetId()], { type = "leftVehicle",  position = pos,  time = self.timer:GetSeconds() })
		self:Broadcast(player:GetName() .. " left their " .. vehicle:GetName())
	end
end

function Tracker:Broadcast(msg)
	Chat:Broadcast( "[Tracker] " .. msg, Color(0xfff0c5b0) )
end

function Tracker:Save()
	local save = {}
	for id,player in pairs(self.trackedPlayers) do
		save[player:GetName()] = self.trackerData[id]
	end
	local filename = "TrackedData - " .. os.date("%d-%m %X") .. ".js"
	local f = io.open(filename, "w")
	if f then
		f:write(JSON:encode(save))
		f:close()
	end
end


class "Rally"

function Rally:__init()
	self:RegisterEvents()
	self.tracker = Tracker(5)
    self.timer = Timer()
	self.tickTimer = Timer()
end

function Rally:RegisterEvents()
	Events:Subscribe( "PlayerChat", self, self.ChatMessage )
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
    Events:Subscribe( "PostTick", self, self.PostTick )
    Events:Subscribe( "PlayerEnterVehicle", self, self.PlayerEnterVehicle )
    Events:Subscribe( "PlayerExitVehicle", self, self.PlayerExitVehicle )
end

function Rally:PlayerCount()
	local i = 0
	for __,_ in pairs(self.players) do
		i = i + 1
	end
	return i
end

function Rally:Start(dest)
	self.players = {}
	self.playerCount = 0
	self.tracker:Reset()
	self.finished = {}
	for v in Server:GetPlayers() do
		self.players[v:GetId()] = v
		self.tracker:AddPlayer(v)
	end
	self:Broadcast("Rally underway! Your destination is X:" .. dest[1] .. " Y:" .. dest[2])
	self.tracker:Start()
	self.destination = dest
	self.inRally = true
	self.timer:Restart()
	self.tickTimer:Restart()
	Network:Broadcast("RallyStart", dest)
end

function Rally:Broadcast(msg)
	Chat:Broadcast( "[Rally] " .. msg, Color(0xfff0c5b0) )
end

function Rally:ChatMessage(args)
	local msg = args.text
    local player = args.player
    
    -- If the string is't a command, we're not interested!
    if ( msg:sub(1, 1) ~= "/" ) then
        return true
    end    
    
    local cmdargs = {}
    for word in string.gmatch(msg, "[^%s]+") do
        table.insert(cmdargs, word)
    end
    
    if ( cmdargs[1] == "/rally" ) then
        if self.inRally then
			self:CancelRally()
		elseif tonumber(cmdargs[2] or "lol") and tonumber(cmdargs[3] or "lol") then
			local x,y = tonumber(cmdargs[2]), tonumber(cmdargs[3])
			if x > 0 and x < 32000 and y > 0 and y < 32000 then
				self:Start({x,y})
			else
				self:Broadcast("Bad map coords")
			end
		else
			self:Broadcast("Provide coordinates for destination")
		end
    end
    
    return false
end

function Rally:CancelRally()
	self:Broadcast("Rally Cancelled!")
	self.tracker:Stop()
	self.inRally = false
end

local function distance ( x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )
end

function Rally:PlayerFinish(id,player)
	if not self.finished[id] then
		self.finished[id] = true
		self.finished[#self.finished + 1] = id
		self:Broadcast(player:GetName() .. " reached the destination! They came in " .. #self.finished .. "st/nd/rd")
		if #self.finished == self:PlayerCount() then
			self:EndRally()
		end
	end
end

function Rally:PostTick(args)
	if self.inRally then
		for id,player in pairs(self.players) do
			local pos = worldToMap(player:GetPosition())
			local d = distance(self.destination[1],self.destination[2],pos[1],pos[2])
			if d < 10 then
				self:PlayerFinish(id,player)
			end
		end
	end
end

function Rally:EndRally()
	self.inRally = false
	self:Broadcast("The Rally is over!")
	self.tracker:Save()
	self.tracker:Stop()
	self:Broadcast("Rally saved")
end

function Rally:PlayerEnterVehicle(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		local vehicle = args.vehicle
		self:Broadcast(player:GetName() .. " entered a " .. vehicle:GetName())
	end
end

function Rally:PlayerExitVehicle(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		local vehicle = args.vehicle
		self:Broadcast(player:GetName() .. " left their " .. vehicle:GetName())
	end
end

function Rally:PlayerDeath(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		self:Broadcast(player:GetName() .. " died. Lol. They are out of the race.")
		self.players[player:GetId()] = nil
		if self:PlayerCount() == 0 then
			self:EndRally()
			self:Broadcast("No players left, ending the rally")
		end	
	end
end

function Rally:PlayerQuit(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		self:Broadcast(player:GetName() .. " left the game. They are out of the race.")
		self.players[player:GetId()] = nil
		if self:PlayerCount() == 0 then
			self:EndRally()
			self:Broadcast("No players left, ending the rally")
		end	
	end
end

rally = Rally()
