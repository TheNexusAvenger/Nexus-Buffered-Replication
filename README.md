# Nexus Buffered Replication
Nexus Buffered Replication packs multiple `UnreliableRemoteEvent`/`RemoteEvent`
packets together for more efficient network usage with high player counts. It
is intended for continuous updates that don't transfer a lot of data (such as
character or aim updates).

This project uses `buffer`s, and any data must be writable to and parsed from
buffers.

## Usage
Both the sender and receiver components rely on a key and data for the key.
Since the sender is intended for continuous updates on a fixed scheduler,
the key allows for not sending duplicate keys for each update. There is special
support for players, as well as generic keys.

### Generic Keys
On the server, `BufferedRemoteEventSender` is used to package data. It takes
in a `UnreliableRemoteEvent` or `RemoteEvent` and function to convert the key
and data to a buffer.

```luau
local BufferedRemoteEventSender = require(...)
local RemoteEvent = ... --Can be an UnreliableRemoteEvent or RemoteEvent.

--Create the BufferedRemoteEventSender instance.
local MyBufferedRemoteEventSender = BufferedRemoteEventSender.new(RemoteEvent, function(Key: number, Value: number)
    local Buffer = buffer.create(2 * 8) --Must be the size of the data to send! Unused data will be wasted.
    buffer.writef64(Buffer, 0, Key) --Key must be included readable in the receiver. It doesn't have to be at the beginning, but most use cases will.
    buffer.writef64(Buffer, 8, Value)
    return Buffer
end)

--Start sending data at 30hz.
MyBufferedRemoteEventSender:StartDataSendingWithDelay(1 / 30)

--Or, start sending data on RunService.Heartbeat.
MyBufferedRemoteEventSender:StartDataSendingWithEvent(game:GetService("RunService").Heartbeat)

--Send data continuously.
--Note: not all data is guaranteed to be sent! Unsent data will be replaced if a new key is sent.
while true do
    MyBufferedRemoteEventSender:QueueData(1, math.random(1, 1000))
    MyBufferedRemoteEventSender:QueueData(2, math.random(1, 1000))
    MyBufferedRemoteEventSender:QueueData(3, math.random(1, 1000))
    task.wait(1 / 30)
end
```

On the client, `BufferedRemoteEventReceiver` can optionally be used as a wrapper.
```luau
local BufferedRemoteEventReceiver = require(...)
local RemoteEvent = ... --Can be an UnreliableRemoteEvent or RemoteEvent.

--Create the BufferedRemoteEventReceiver instance.
local MyBufferedRemoteEventReceiver = BufferedRemoteEventReceiver.new(RemoteEvent, function(Buffer)
    --This parses *all* the values in the buffer, instead of individual values.
    local Data = {}
    for i = 1, buffer.len(Buffer) / 16 do
        local Offset = (i - 1) * 16
        Data[buffer.readf64(Buffer, Offset)] = buffer.readf64(Buffer, Offset + 8)
    end
    return Data
end)

--Listen for data being sent from the server.
MyBufferedRemoteEventReceiver:OnDataReceived(function(Key, Data)
    print(`{Key} = {Data}`)
end)
```

### Player Keys
Most uses of this library are for player updates. Players have special support.
On the server, this is done with `BufferedRemoteEventSender.WithPlayerKeys`.

```luau
local BufferedRemoteEventSender = require(...)
local RemoteEvent = ... --Can be an UnreliableRemoteEvent or RemoteEvent.

--Create the BufferedRemoteEventSender instance.
local MyBufferedRemoteEventSender = BufferedRemoteEventSender.WithPlayerKeys(RemoteEvent, function(Value: number)
    --The key is the player's user id, which is handled internally. The key does not need to be sent here.
    local Buffer = buffer.create(8) --Must be the size of the data to send! Unused data will be wasted.
    buffer.writef64(Buffer, 0, Data)
    return Buffer
end)

--Start sending data at 30hz.
MyBufferedRemoteEventSender:StartDataSendingWithDelay(1 / 30)

--Or, start sending data on RunService.Heartbeat.
MyBufferedRemoteEventSender:StartDataSendingWithEvent(game:GetService("RunService").Heartbeat)

--Send data continuously.
--Note: not all data is guaranteed to be sent! Unsent data will be replaced if a new key is sent.
while true do
    for _, Player in game:GetService("Players"):GetPlayers() do
        MyBufferedRemoteEventSender:QueueData(Player, math.random(1, 1000))
    end
    task.wait(1 / 30)
end
```

On the client, `PlayerBufferedRemoteEventReceiver` should be used to handle player
keys efficiently.

```luau
local PlayerBufferedRemoteEventReceiver = require(...)
local RemoteEvent = ... --Can be an UnreliableRemoteEvent or RemoteEvent.

--Create the PlayerBufferedRemoteEventReceiver instance.
local MyPlayerBufferedRemoteEventReceiver = PlayerBufferedRemoteEventReceiver.new(RemoteEvent, function(Buffer)
    --This parses *all* the values in the buffer, instead of individual values.
    --Due to unknown buffer lengths, the keys must be parsed. The key *must* use readf64.
    local Data = {}
    for i = 1, buffer.len(Buffer) / 16 do
        local Offset = (i - 1) * 16
        Data[buffer.readf64(Buffer, Offset)] = buffer.readf64(Buffer, Offset + 8)
    end
    return Data
end)

--Listen for data being sent from the server.
--If player references don't exist yet (shouldn't really happen?), this will not be called.
MyPlayerBufferedRemoteEventReceiver:OnDataReceived(function(Player, Data)
    print(`{Player} = {Data}`)
end)
```

### Enrollable RemoteEvents
For systems with loading stages (ex: Nexus VR Character Model),
`EnrollableRemoteEvent` can be used in place of `UnreliableRemoteEvent`s
and `RemoteEvent`s.

```luau
local EnrollableRemoteEvent = require(...)
local RemoteEvent = ... --Can be an UnreliableRemoteEvent or RemoteEvent.

--Create the EnrollableRemoteEvent.
local MyEnrollableRemoteEvent = EnrollableRemoteEvent.new(RemoteEvent)

--Enroll players after they load.
--UnenrollPlayer also exists, but is not needed in most cases.
--Players that leave will automatically be unenrolled.
OtherRemoteEvent.OnServerEvent:Connect(function(Player)
    MyEnrollableRemoteEvent:EnrollPlayer(Player)
end)
```

## Contributing
Both issues and pull requests are accepted for this project.

## License
Nexus Buffered Replication is available under the terms of the MIT License. See
[LICENSE](LICENSE) for details.