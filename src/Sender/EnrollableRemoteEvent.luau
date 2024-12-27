--Sends RemoteEvent events to players "enrolled" in the event.
--This is intended to prevent sending requests to players that haven't loaded yet, such as modules loaded in using require-by-id.

local EnrollableRemoteEvent = {}
EnrollableRemoteEvent.Players = game:GetService("Players")
EnrollableRemoteEvent.__index = EnrollableRemoteEvent

export type EnrollableRemoteEvent = {
    RemoteEvent: UnreliableRemoteEvent | RemoteEvent,
    TotalPlayers: number,
    EnrolledPlayers: {Player},
    EventConnections: {RBXScriptConnection},
} & typeof(setmetatable({}, EnrollableRemoteEvent))



--[[
Creates an enrollable RemoteEvent.
--]]
function EnrollableRemoteEvent.new(RemoteEvent: UnreliableRemoteEvent | RemoteEvent): EnrollableRemoteEvent
    --Create the object.
    local self = setmetatable({
        RemoteEvent = RemoteEvent,
        TotalPlayers = #EnrollableRemoteEvent.Players:GetPlayers(),
        EnrolledPlayers = {},
        EventConnections = {},
    }, EnrollableRemoteEvent) :: EnrollableRemoteEvent

    --Update player counts.
    table.insert(self.EventConnections, EnrollableRemoteEvent.Players.PlayerAdded:Connect(function()
        self.TotalPlayers = #EnrollableRemoteEvent.Players:GetPlayers()
    end))
    table.insert(self.EventConnections, EnrollableRemoteEvent.Players.PlayerRemoving:Connect(function(Player)
        self.TotalPlayers = #EnrollableRemoteEvent.Players:GetPlayers()
        self:UnenrollPlayer(Player)
    end))

    --Return the object.
    return self
end

--[[
Enrolls a player in receiving data.
--]]
function EnrollableRemoteEvent.EnrollPlayer(self: EnrollableRemoteEvent, Player: Player): ()
    if table.find(self.EnrolledPlayers, Player) then return end
    table.insert(self.EnrolledPlayers, Player)
end

--[[
Unenrolls a player from receiving data.
--]]
function EnrollableRemoteEvent.UnenrollPlayer(self: EnrollableRemoteEvent, Player: Player): ()
    local Index = table.find(self.EnrolledPlayers, Player)
    if not Index then return end
    table.remove(self.EnrolledPlayers, Index)
end

--[[
Sends data to all the enrolled players.
--]]
function EnrollableRemoteEvent.FireAllClients(self: EnrollableRemoteEvent, ...: any): ()
    --Return if there is no enrolled players.
    local TotalEnrolledPlayers = #self.EnrolledPlayers
    if #self.EnrolledPlayers == 0 then return end

    --Send the data.
    local RemoteEvent = (self.RemoteEvent :: UnreliableRemoteEvent)
    if TotalEnrolledPlayers == self.TotalPlayers then
        --Send the data to all players.
        RemoteEvent:FireAllClients(...)
    else
        --Send the data to only the enrolled players.
        for _, Player in self.EnrolledPlayers do
            RemoteEvent:FireClient(Player, ...)
        end
    end
end

--[[
Destroys the enrollable RemoteEvent.
--]]
function EnrollableRemoteEvent.Destroy(self: EnrollableRemoteEvent): ()
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
end



return EnrollableRemoteEvent