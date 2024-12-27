--Tests BufferedRemoteEventReceiver.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BufferedRemoteEventReceiver = require(ReplicatedStorage.NexusBufferedReplication.Receiver.BufferedRemoteEventReceiver)

return function()
    describe("A BufferedRemoteEventReceiver", function()
        local MockRemoteEvent = nil
        local TestBufferedRemoteEventReceiver = nil
        beforeEach(function()
            MockRemoteEvent = Instance.new("BindableEvent")

            TestBufferedRemoteEventReceiver = BufferedRemoteEventReceiver.new({
                OnClientEvent = MockRemoteEvent.Event,
            } :: any, function(Buffer)
                local Data = {}
                for i = 1, buffer.len(Buffer) / 16 do
                    Data[buffer.readf64(Buffer, 16 * (i - 1))] = buffer.readf64(Buffer, (16 * (i - 1)) + 8)
                end
                return Data
            end)
        end)

        it("should run callbacks with called data.", function()
            local CallbackCalls = {}
            TestBufferedRemoteEventReceiver:OnDataReceived(function(Key, Value)
                CallbackCalls[Key] = Value
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
            expect(CallbackCalls[5]).to.equal(6)
        end)
    end)
end