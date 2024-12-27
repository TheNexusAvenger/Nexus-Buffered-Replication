--Buffers requests to be sent to the client.
--!strict

local DEFAULT_MAX_REQUEST_SIZE = 900

local BufferedRemoteEventSender = {}
BufferedRemoteEventSender.__index = BufferedRemoteEventSender

export type BufferedRemoteEvent = {
    FireAllClients: (self: BufferedRemoteEvent, Data: any) -> (),
    [any]: any,
} | UnreliableRemoteEvent | RemoteEvent
export type BufferedRemoteEventSender<TKey, TData> = {
    MaxRequestSize: number,
    QueuedData: {[TKey]: TData},
    RemoteEvent: BufferedRemoteEvent,
    SerializeMessage: (Key: TKey, Data: TData) -> (buffer),
    SendingActive: boolean,
} & typeof(setmetatable({}, BufferedRemoteEventSender))



--[[
Creates a buffered RemoteEvent sender.
--]]
function BufferedRemoteEventSender.new<TKey, TData>(RemoteEvent: BufferedRemoteEvent, SerializeMessage: (Key: TKey, Data: TData) -> (buffer)): BufferedRemoteEventSender<TKey, TData>
    return setmetatable({
        MaxRequestSize = DEFAULT_MAX_REQUEST_SIZE,
        QueuedData = {},
        RemoteEvent = RemoteEvent,
        SerializeMessage = SerializeMessage,
        SendingActive = true,
    }, BufferedRemoteEventSender) :: BufferedRemoteEventSender<TKey, TData>
end

--[[
Creates a buffered RemoteEvent sender with player keys.
--]]
function BufferedRemoteEventSender.WithPlayerKeys<TData>(RemoteEvent: BufferedRemoteEvent, SerializeMessage: (Data: TData) -> (buffer)): BufferedRemoteEventSender<Player, TData>
    return BufferedRemoteEventSender.new(RemoteEvent, function(Player: Player, Data: TData)
        local Buffer = SerializeMessage(Data)
        local NewBuffer = buffer.create(8 + buffer.len(Buffer))
        buffer.writef64(NewBuffer, 0, Player.UserId)
        buffer.copy(NewBuffer, 8, Buffer)
        return NewBuffer
    end)
end

--[[
Queues data to send to clients.
If there was previous data that was queued but not sent for the key, the previous request will be dropped.
--]]
function BufferedRemoteEventSender.QueueData<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>, Key: TKey, Data: TData): ()
    self.QueuedData[Key] = Data
end

--[[
Sends the queued data to the clients.
--]]
function BufferedRemoteEventSender.SendQueuedData<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>): ()
    --Get the data to send and clear it for new data to be queued.
    local QueuedData = self.QueuedData
    self.QueuedData = {}

    --Convert the queued data into individual buffers.
    --Drop buffers that are too long.
    local QueuedDataBufferGroups = {
        {
            Buffers = {},
            CurrentLength = 0,
        },
    }
    local MaxRequestSize = self.MaxRequestSize
    for Key, Data in QueuedData do
        --Serialize the data and warn if the data is too long.
        local BufferedData = self.SerializeMessage(Key, Data)
        local BufferLength = buffer.len(BufferedData)
        if BufferLength > self.MaxRequestSize then
            warn(`Data was serialzied for key {Key} and was too long ({BufferLength} > {MaxRequestSize}). The data will be dropped.`)
            continue
        end

        --Add the buffer.
        local LastGroup = QueuedDataBufferGroups[#QueuedDataBufferGroups]
        local LastGroupNewLength = LastGroup.CurrentLength + BufferLength
        if LastGroupNewLength > MaxRequestSize then
            table.insert(QueuedDataBufferGroups, {
                Buffers = {BufferedData},
                CurrentLength = BufferLength,
            })
        else
            table.insert(LastGroup.Buffers, BufferedData)
            LastGroup.CurrentLength = LastGroupNewLength
        end
    end

    --Combine the buffers and send them.
    for _, BufferGroup in QueuedDataBufferGroups do
        if BufferGroup.CurrentLength == 0 then return end
        local BufferToSend = buffer.create(BufferGroup.CurrentLength)
        local CurrentOffset = 0
        for _, Buffer in BufferGroup.Buffers do
            buffer.copy(BufferToSend, CurrentOffset, Buffer)
            CurrentOffset += buffer.len(Buffer)
        end
        (self.RemoteEvent :: UnreliableRemoteEvent):FireAllClients(BufferToSend)
    end
end

--[[
Starts sending data in the background with a delay function.
--]]
function BufferedRemoteEventSender.StartDataSending<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>, DelayFunction: () -> ()): ()
    task.spawn(function()
        while self.SendingActive do
            self:SendQueuedData()
            DelayFunction()
        end
    end)
end

--[[
Starts sending data in the background with a wait delay.
--]]
function BufferedRemoteEventSender.StartDataSendingWithDelay<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>, Delay: number): ()
    self:StartDataSending(function()
        task.wait(Delay)
    end)
end

--[[
Starts sending data in the background with an event delay.
--]]
function BufferedRemoteEventSender.StartDataSendingWithEvent<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>, Event: RBXScriptSignal): ()
    self:StartDataSending(function()
        Event:Wait()
    end)
end

--[[
Destroys the buffered RemoteEvent sender.
--]]
function BufferedRemoteEventSender.Destroy<TKey, TData>(self: BufferedRemoteEventSender<TKey, TData>): ()
    self.SendingActive = false
end



return BufferedRemoteEventSender