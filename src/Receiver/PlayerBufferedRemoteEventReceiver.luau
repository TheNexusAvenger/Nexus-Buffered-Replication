--Wraps BufferedRemoteEventReceiver for players.
--!strict

local BufferedRemoteEventReceiver = require(script.Parent:WaitForChild("BufferedRemoteEventReceiver"))

local PlayerBufferedRemoteEventReceiver = {}
PlayerBufferedRemoteEventReceiver.Players = game:GetService("Players")
PlayerBufferedRemoteEventReceiver.__index = PlayerBufferedRemoteEventReceiver

export type PlayerBufferedRemoteEventReceiver<TData> = {
    PlayerUserIdLookup: {[number]: Player},
    BufferedRemoteEventReceiver: BufferedRemoteEventReceiver.BufferedRemoteEventReceiver<number, TData>,
} & typeof(setmetatable({}, PlayerBufferedRemoteEventReceiver))



--[[
Creates a player buffered RemoteEvent receiver.
--]]
function PlayerBufferedRemoteEventReceiver.new<TData>(RemoteEvent: UnreliableRemoteEvent | RemoteEvent, DeserializeMessages: (buffer) -> ({[number]: TData})): PlayerBufferedRemoteEventReceiver<TData>
    --Create the object.
    local PlayerUserIdLookup = {}
    local self = setmetatable({
        PlayerUserIdLookup = PlayerUserIdLookup,
        BufferedRemoteEventReceiver = BufferedRemoteEventReceiver.new(RemoteEvent, DeserializeMessages),
    }, PlayerBufferedRemoteEventReceiver) :: PlayerBufferedRemoteEventReceiver<TData>
    
    --Create the player user id lookup.
    for _, Player in PlayerBufferedRemoteEventReceiver.Players:GetPlayers() do
        PlayerUserIdLookup[Player.UserId] = Player
    end
    table.insert(self.BufferedRemoteEventReceiver.EventConnections, PlayerBufferedRemoteEventReceiver.Players.PlayerAdded:Connect(function(Player)
        PlayerUserIdLookup[Player.UserId] = Player
    end))
    table.insert(self.BufferedRemoteEventReceiver.EventConnections, PlayerBufferedRemoteEventReceiver.Players.PlayerRemoving:Connect(function(Player)
        PlayerUserIdLookup[Player.UserId] = nil
    end))
    
    --Return the object.
    return self
end

--[[
Connects data being sent from the server.
--]]
function PlayerBufferedRemoteEventReceiver.OnDataReceived<TData>(self: PlayerBufferedRemoteEventReceiver<TData>, Callback: (Player: Player, Data: TData) -> ()): ()
    self.BufferedRemoteEventReceiver:OnDataReceived(function(UserId: number, Data: TData)
        local Player = self.PlayerUserIdLookup[UserId]
        if not Player then return end
        Callback(Player, Data)
    end)
end

--[[
Destroys the player buffered RemoteEvent receiver.
--]]
function PlayerBufferedRemoteEventReceiver.Destroy<TData>(self: PlayerBufferedRemoteEventReceiver<TData>): ()
    self.BufferedRemoteEventReceiver:Destroy()
end



return PlayerBufferedRemoteEventReceiver