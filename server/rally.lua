
class "Rally"

function Rally:__init()
    Events:Subscribe( "PlayerChat", self, self.ChatMessage )
    
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    
    Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
    
    Events:Subscribe( "PostTick", self, self.PostTick )

    Events:Subscribe( "PlayerEnterVehicle", self, self.PlayerEnterVehicle )
    Events:Subscribe( "PlayerExitVehicle", self, self.PlayerExitVehicle )

    self.timer = Timer()
	self.tickTimer = Timer()
	self.resolution = 5
end

function Rally:Start(dest)
	self.players = {}
	self.playerCount = 0
	self.finished = {}
	self.hasFinished = {}
	for v in Server:GetPlayers() do
		self.players[v:GetId()] = {}
		self.playerCount = self.playerCount + 1
	end
	self:Broadcast("Rally underway! Your destination is X:" .. dest[1] .. " Y:" .. dest[2])
	self.destination = dest
	self.inRally = true
	self.timer:Restart()
	self.tickTimer:Restart()
	Network:Broadcast("RallyStart", dest)
end

function Rally:Broadcast(msg)
	Chat:Broadcast( "[Rally] " .. msg, Color(0xfff0c5b0) )
end

local function worldToMap(v)
	origin = Vector3(-16384, 0, -16384)
	v = v - origin
	return {v.x,v.z}
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
	elseif cmdargs[1] == "/pos" then
		self:Broadcast(tostring(player:GetPosition()))
		print(player:GetPosition())
    end
    
    return false
end

function Rally:CancelRally()
	self:Broadcast("Rally Cancelled!")
	self.inRally = false
end

local function distance ( x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )
end

function Rally:PlayerFinish(id,player)
	if not self.hasFinished[id] then
		self.hasFinished[id] = true
		self.finished[#self.finished + 1] = id
		self:Broadcast(player:GetName() .. " reached the destination! They came in " .. #self.finished .. "st/nd/rd")
		print(#self.finished, #self.players)
		if #self.finished == self.playerCount then
			self:EndRally()
		end
	end
end

function Rally:PostTick(args)
	if self.inRally then
		local doUpdate = self.tickTimer:GetSeconds() > self.resolution
		for i,v in pairs(self.players) do
			local p = Player.GetById(i)
			local pos = p:GetPosition()
			pos = worldToMap(pos)
			local d = distance(self.destination[1],self.destination[2],pos[1],pos[2])
			if doUpdate then
				table.insert(v, { type = "tick", position = {pos[1], pos[2]}})
				self.tickTimer:Restart()
			end
			
			if d < 10 then
				self:PlayerFinish(i,p)
			end
		end
		if doUpdate then
			self.tickTimer:Restart()
		end
	end
end

function Rally:EndRally()
	self.inRally = false
	self:Broadcast("The Rally is over!")
	local save = {}
	for i,v in pairs(self.players) do
		local p = Player.GetById(i)
		save[p:GetName()] = v
	end
	local f = io.open("lol.js", "w")
	f:write(JSON:encode(save))
	f:close()
	self:Broadcast("Rally saved")
end

function Rally:PlayerEnterVehicle(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		local vehicle = args.vehicle
		local pos = worldToMap(player:GetPosition())
		table.insert(self.players[player:GetId()], { type = "enterVehicle", vehicle = vehicle:GetName(), position = {pos[1], pos[2]} })
		self:Broadcast(player:GetName() .. " entered a " .. vehicle:GetName())
	end
end

function Rally:PlayerExitVehicle(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		local vehicle = args.vehicle
		local pos = worldToMap(player:GetPosition())
		table.insert(self.players[player:GetId()], { type = "leftVehicle",  position = {pos[1], pos[2]} })
		self:Broadcast(player:GetName() .. " left their " .. vehicle:GetName())
	end
end

function Rally:PlayerDeath(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		local pos = worldToMap(player:GetPosition())
		table.insert(self.players[player:GetId()], { type = "death", position = {pos[1], pos[2]} })
		self:Broadcast(player:GetName() .. " died. Lol")
	end
end

function Rally:PlayerQuit(args)
	local player = args.player
	if self.inRally and self.players[player:GetId()] then
		self:Broadcast(player:GetName() .. " left the game.")
		self.players[player:GetId()] = nil
	end
end

rally = Rally()
