--Tests PlayerBufferedRemoteEventReceiver.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerBufferedRemoteEventReceiver = require(ReplicatedStorage.NexusBufferedReplication.Receiver.PlayerBufferedRemoteEventReceiver)

return function()
    describe("A PlayerBufferedRemoteEventReceiver", function()
        local MockPlayer1, MockPlayer2 = {UserId = 1} :: any, {UserId = 3} :: any
        local MockRemoteEvent = nil
        local TestPlayerBufferedRemoteEventReceiver = nil
        beforeEach(function()
            MockRemoteEvent = Instance.new("BindableEvent")

            PlayerBufferedRemoteEventReceiver.Players = {
                GetPlayers = function() return {MockPlayer1, MockPlayer2} end,
                PlayerAdded = Instance.new("BindableEvent").Event,
                PlayerRemoving = Instance.new("BindableEvent").Event,
            } :: any
            TestPlayerBufferedRemoteEventReceiver = PlayerBufferedRemoteEventReceiver.new({
                OnClientEvent = MockRemoteEvent.Event,
            } :: any, function(Buffer)
                local Data = {}
                for i = 1, buffer.len(Buffer) / 16 do
                    Data[buffer.readf64(Buffer, 16 * (i - 1))] = buffer.readf64(Buffer, (16 * (i - 1)) + 8)
                end
                return Data
            end)
        end)

        afterEach(function()
            PlayerBufferedRemoteEventReceiver.Players = game:GetService("Players")
            TestPlayerBufferedRemoteEventReceiver:Destroy()
        end)

        it("should run callbacks with called data.", function()
            local CallbackCalls = {}
            TestPlayerBufferedRemoteEventReceiver:OnDataReceived(function(Key, Value)
                CallbackCalls[Key.UserId] = Value
            end)

            local Buffer = buffer.create(6 * 8)
            buffer.writef64(Buffer, 0, 1)
            buffer.writef64(Buffer, 8, 2)
            buffer.writef64(Buffer, 16, 3)
            buffer.writef64(Buffer, 24, 4)
            buffer.writef64(Buffer, 32, 5)
            buffer.writef64(Buffer, 40, 6)
            MockRemoteEvent:Fire(Buffer)
            task.wait()
            expect(CallbackCalls[1]).to.equal(2)
            expect(CallbackCalls[3]).to.equal(4)
            expect(CallbackCalls[5]).to.equal(nil)
        end)
    end)
end