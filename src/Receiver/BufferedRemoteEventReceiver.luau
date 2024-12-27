--Reads buffered requests from the server.
--!strict

local BufferedRemoteEventReceiver = {}
BufferedRemoteEventReceiver.__index = BufferedRemoteEventReceiver

export type BufferedRemoteEventReceiver<TKey, TData> = {
    RemoteEvent: UnreliableRemoteEvent | RemoteEvent,
    DeserializeMessages: (buffer) -> ({[TKey]: TData}),
    OnDataReceivedCallbacks: {(Key: TKey, Data: TData) -> ()},
    EventConnections: {RBXScriptConnection},
} & typeof(setmetatable({}, BufferedRemoteEventReceiver))



--[[
Creates a buffered RemoteEvent receiver.
--]]
function BufferedRemoteEventReceiver.new<TKey, TData>(RemoteEvent: UnreliableRemoteEvent | RemoteEvent, DeserializeMessages: (buffer) -> ({[TKey]: TData})): BufferedRemoteEventReceiver<TKey, TData>
    return setmetatable({
        RemoteEvent = RemoteEvent,
        DeserializeMessages = DeserializeMessages,
        OnDataReceivedCallbacks = {},
        EventConnections = {},
    }, BufferedRemoteEventReceiver) :: BufferedRemoteEventReceiver<TKey, TData>
end

--[[
Connects data being sent from the server.
--]]
function BufferedRemoteEventReceiver.OnDataReceived<TKey, TData>(self: BufferedRemoteEventReceiver<TKey, TData>, Callback: (Key: TKey, Data: TData) -> ()): ()
    --Add the callback.
    table.insert(self.OnDataReceivedCallbacks, Callback)

    --Connect events from the server if it hasn't been connected yet.
    if #self.OnDataReceivedCallbacks > 1 then return end
    table.insert(self.EventConnections, (self.RemoteEvent :: UnreliableRemoteEvent).OnClientEvent:Connect(function(Buffer: buffer)
        for Key, Data in self.DeserializeMessages(Buffer) do
            for _, OnDataReceivedCallback in self.OnDataReceivedCallbacks do
                task.spawn(OnDataReceivedCallback, Key, Data)
            end
        end
    end))
end

--[[
Destroys the buffered RemoteEvent receiver.
--]]
function BufferedRemoteEventReceiver.Destroy<TKey, TData>(self: BufferedRemoteEventReceiver<TKey, TData>): ()
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
    self.OnDataReceivedCallbacks = {}
end



return BufferedRemoteEventReceiver