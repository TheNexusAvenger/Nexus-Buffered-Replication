--Tests BufferedRemoteEventSender.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BufferedRemoteEventSender = require(ReplicatedStorage.NexusBufferedReplication.Sender.BufferedRemoteEventSender)

return function()
    local function expectBuffer(Buffer: buffer, Data: {number}): ()
        expect(buffer.len(Buffer)).to.equal(8 * #Data)
        for i, Number in Data do
            expect(buffer.readf64(Buffer, 8 * (i - 1))).to.equal(Number)
        end
    end

    describe("A BufferedRemoteEventSender", function()
        local MockRemoteEvent = nil
        local TestBufferedRemoteEventSender = nil
        beforeEach(function()
            MockRemoteEvent = {
                SentBuffers = {},
                FireAllClients = function(self, Buffer)
                    table.insert(self.SentBuffers, Buffer)
                end,
            } :: any

            TestBufferedRemoteEventSender = BufferedRemoteEventSender.new(MockRemoteEvent, function(Key: number, Data: number)
                local Buffer = buffer.create(8 + (8 * Data))
                buffer.writef64(Buffer, 0, Key)
                for i = 1, Data do
                    buffer.writef64(Buffer, 8 * i, i)
                end
                return Buffer
            end)
        end)

        it("should queue data.", function()
            TestBufferedRemoteEventSender:QueueData(1, 5)
            expect(TestBufferedRemoteEventSender.QueuedData[1]).to.equal(5)
        end)

        it("should send queued data.", function()
            TestBufferedRemoteEventSender:QueueData(1, 5)
            TestBufferedRemoteEventSender:SendQueuedData()
            expect(TestBufferedRemoteEventSender.QueuedData[1]).to.equal(nil)

            expect(#MockRemoteEvent.SentBuffers).to.equal(1)
            expectBuffer(MockRemoteEvent.SentBuffers[1], {1, 1, 2, 3, 4, 5})
        end)

        it("should send multiple buffers together.", function()
            TestBufferedRemoteEventSender:QueueData(1, 5)
            TestBufferedRemoteEventSender:QueueData(2, 4)
            TestBufferedRemoteEventSender:QueueData(3, 3)
            TestBufferedRemoteEventSender:SendQueuedData()
            expect(TestBufferedRemoteEventSender.QueuedData[1]).to.equal(nil)

            expect(#MockRemoteEvent.SentBuffers).to.equal(1)
            expectBuffer(MockRemoteEvent.SentBuffers[1], {1, 1, 2, 3, 4, 5, 2, 1, 2, 3, 4, 3, 1, 2, 3})
        end)

        it("should split buffers when too long.", function()
            TestBufferedRemoteEventSender.MaxRequestSize = 8 * 12
            TestBufferedRemoteEventSender:QueueData(1, 5)
            TestBufferedRemoteEventSender:QueueData(2, 4)
            TestBufferedRemoteEventSender:QueueData(3, 3)
            TestBufferedRemoteEventSender:SendQueuedData()
            expect(TestBufferedRemoteEventSender.QueuedData[1]).to.equal(nil)

            expect(#MockRemoteEvent.SentBuffers).to.equal(2)
            expectBuffer(MockRemoteEvent.SentBuffers[1], {1, 1, 2, 3, 4, 5, 2, 1, 2, 3, 4})
            expectBuffer(MockRemoteEvent.SentBuffers[2], {3, 1, 2, 3})
        end)

        it("should not send queued data when it is too long.", function()
            TestBufferedRemoteEventSender:QueueData(1, 5)
            TestBufferedRemoteEventSender:QueueData(2, 500)
            TestBufferedRemoteEventSender:SendQueuedData()
            expect(TestBufferedRemoteEventSender.QueuedData[1]).to.equal(nil)

            expect(#MockRemoteEvent.SentBuffers).to.equal(1)
            expectBuffer(MockRemoteEvent.SentBuffers[1], {1, 1, 2, 3, 4, 5})
        end)
    end)

    describe("A BufferedRemoteEventSender for players", function()
        local MockRemoteEvent = nil
        local TestBufferedRemoteEventSender = nil
        beforeEach(function()
            MockRemoteEvent = {
                SentBuffers = {},
                FireAllClients = function(self, Buffer)
                    table.insert(self.SentBuffers, Buffer)
                end,
            } :: any

            TestBufferedRemoteEventSender = BufferedRemoteEventSender.WithPlayerKeys(MockRemoteEvent, function(Data: number)
                local Buffer = buffer.create((8 * Data))
                for i = 1, Data do
                    buffer.writef64(Buffer, 8 * (i - 1), i)
                end
                return Buffer
            end)
        end)

        it("should send queued data.", function()
            TestBufferedRemoteEventSender:QueueData({
                UserId = 12345,   
            } :: any, 5)
            TestBufferedRemoteEventSender:SendQueuedData()

            expect(#MockRemoteEvent.SentBuffers).to.equal(1)
            expectBuffer(MockRemoteEvent.SentBuffers[1], {12345, 1, 2, 3, 4, 5})
        end)
    end)
end